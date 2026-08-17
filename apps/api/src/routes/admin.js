import { Router } from "express";
import { z } from "zod";
import { REALTOR_STATUS, USER_ROLE } from "../lib/enums.js";
import { loadCurrentUser, requireAuth } from "../middleware/auth.js";
import { requireCurrentRole, requireRole } from "../middleware/roles.js";
import * as adminService from "../services/adminService.js";

const router = Router();

// Gated once, for the whole router, rather than per endpoint: a missing
// requireRole on one of eight handlers is a silent hole that no other
// endpoint's test would catch, and this file will keep growing. Ordering
// matters — requireAuth populates req.auth, which requireRole reads.
//
// Four links, and the last two are the ones that matter. requireRole compares
// against req.auth.role — the UPPERCASE Prisma value the JWT carries, not the
// lowercase wire key — which makes it a cheap first filter that turns away a
// buyer's or an agent's token without touching Postgres. It is NOT sufficient
// on its own, because that role is a claim frozen into the token at sign-in
// and this API has no revocation list: an admin demoted a minute ago still
// holds a token that says ADMIN for the rest of JWT_EXPIRES_IN (7 days by
// default), and the very first thing that token can do is PATCH its own row
// back to ADMIN. So loadCurrentUser re-reads the row and requireCurrentRole
// decides on *that* — the account as it exists now. It also 401s an account
// that has since been deleted, which the JWT likewise cannot know about.
//
// The cost is one extra findUnique per admin request, on the lowest-traffic
// surface in the product; the alternative is that revoking someone's admin
// rights quietly does nothing for a week.
//
// req.currentUser is otherwise unused by these handlers by design — an ADMIN
// has no agent scope to resolve (effectiveAgentId returns null for it), and
// the self-demotion rule needs only the actor's id, which the JWT already
// carries as `sub`.
router.use(requireAuth, requireRole("ADMIN"), loadCurrentUser, requireCurrentRole("ADMIN"));

// Mirrors routes/agents.js's helper of the same name: adminService throws
// httpError(status, code, message) and this maps it straight to the matching
// response; anything else falls through to next(e) / the app's generic 500
// handler.
function handleServiceError(e, res, next) {
  if (e.status) {
    return res.status(e.status).json({ error: { code: e.code, message: e.message } });
  }
  next(e);
}

function respondValidationError(res, parsed) {
  return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
}

// z.enum over the *keys* of a wire-format map, so the accepted values are
// derived from the one map that owns them instead of a hand-copied literal
// tuple that could drift. This is @lacasa/domain's own zodEnumFromKeys
// helper, re-derived in three lines rather than imported: that helper lives
// in packages/domain/src/schemas/zodEnum.ts, which is not one of the
// package's tsup entry points, so it is not reachable from the built `dist`
// this app imports.
const zodEnumFromKeys = (map) => z.enum(Object.keys(map));

// Shared by every list endpoint. `cursor` is the previous page's last row id
// — opaque to the client by contract, a uuid in fact, and validated as one so
// a malformed value answers 400 rather than reaching Postgres and blowing up
// on a uuid cast. `limit`'s ceiling is enforced here as a 400 (an explicit
// "too big" beats silently serving 100 when 500 was asked for); adminService
// clamps it a second time for any non-HTTP caller.
const pageQuerySchema = {
  limit: z.coerce.number().int().min(1).max(100).optional(),
  cursor: z.string().uuid().optional(),
};

// Route params are validated as uuids for the same reason `cursor` is: every
// id column in schema.prisma is @db.Uuid, so a non-uuid path segment would
// otherwise surface as a Prisma P2023 / Postgres 22P02 and a 500. The
// trade-off is that `/api/admin/users/not-a-uuid` answers 400 validation
// rather than 404 not_found — the honest answer, since the server cannot say
// whether a row it can't even look up exists.
const idParamSchema = z.object({ id: z.string().uuid() });
const userIdParamSchema = z.object({ userId: z.string().uuid() });

// ---------------------------------------------------------------------------
// Overview

router.get("/overview", async (req, res, next) => {
  try {
    res.json(await adminService.getOverview(req.ctx));
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

// ---------------------------------------------------------------------------
// Realtor applications

// `pending` is the default, applied in the service rather than here so a
// direct service call defaults the same way an HTTP one does. NONE is not an
// accepted value: "never applied" is not an application anyone reviews.
const listApplicationsQuerySchema = z.object({
  status: z.enum(["pending", "approved", "rejected"]).optional(),
  ...pageQuerySchema,
});

router.get("/applications", async (req, res, next) => {
  try {
    const parsed = listApplicationsQuerySchema.safeParse(req.query);
    if (!parsed.success) return respondValidationError(res, parsed);
    res.json(await adminService.listApplications(req.ctx, parsed.data));
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

// POST, not PATCH: approving is an action taken on an application, not an
// edit of a field the client gets to choose the value of. Both answer 200
// with the decided user rather than 204, so the console can update its row
// from the response instead of refetching.
router.post("/applications/:userId/approve", async (req, res, next) => {
  try {
    const parsed = userIdParamSchema.safeParse(req.params);
    if (!parsed.success) return respondValidationError(res, parsed);
    res.json(await adminService.approveApplication(req.ctx, parsed.data.userId));
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

router.post("/applications/:userId/reject", async (req, res, next) => {
  try {
    const parsed = userIdParamSchema.safeParse(req.params);
    if (!parsed.success) return respondValidationError(res, parsed);
    res.json(await adminService.rejectApplication(req.ctx, parsed.data.userId));
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

// ---------------------------------------------------------------------------
// Users

// `q` is capped at 200 characters — the same ceiling users.js puts on
// fullName, since that is the longest thing anyone could sensibly be
// searching for — so a megabyte-long ILIKE pattern never reaches Postgres.
const listUsersQuerySchema = z.object({
  q: z.string().max(200).optional(),
  role: zodEnumFromKeys(USER_ROLE).optional(),
  realtorStatus: zodEnumFromKeys(REALTOR_STATUS).optional(),
  ...pageQuerySchema,
});

router.get("/users", async (req, res, next) => {
  try {
    const parsed = listUsersQuerySchema.safeParse(req.query);
    if (!parsed.success) return respondValidationError(res, parsed);
    res.json(await adminService.listUsers(req.ctx, parsed.data));
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

router.get("/users/:id", async (req, res, next) => {
  try {
    const parsed = idParamSchema.safeParse(req.params);
    if (!parsed.success) return respondValidationError(res, parsed);
    res.json(await adminService.getUser(req.ctx, parsed.data.id));
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

const setRoleBodySchema = z.object({ role: zodEnumFromKeys(USER_ROLE) });

router.patch("/users/:id/role", async (req, res, next) => {
  try {
    const params = idParamSchema.safeParse(req.params);
    if (!params.success) return respondValidationError(res, params);
    const body = setRoleBodySchema.safeParse(req.body);
    if (!body.success) return respondValidationError(res, body);

    // req.auth.sub, not a loaded row: the self-demotion rule only needs to
    // know whether the target is the caller, and the JWT already answers
    // that without a round trip.
    res.json(
      await adminService.setUserRole(req.ctx, {
        userId: params.data.id,
        role: body.data.role,
        actorId: req.auth.sub,
      }),
    );
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

// ---------------------------------------------------------------------------
// Audit trail

const listAuditQuerySchema = z.object({
  // The accepted values are the lowercase wire keys of schema.prisma's
  // EventType, derived from the map adminService exports so this list can
  // never fall behind a new event type.
  type: zodEnumFromKeys(adminService.EVENT_TYPE).optional(),
  agentId: z.string().uuid().optional(),
  ...pageQuerySchema,
});

router.get("/audit", async (req, res, next) => {
  try {
    const parsed = listAuditQuerySchema.safeParse(req.query);
    if (!parsed.success) return respondValidationError(res, parsed);
    res.json(await adminService.listAudit(req.ctx, parsed.data));
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

export default router;
