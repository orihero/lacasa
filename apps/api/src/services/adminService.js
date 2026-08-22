import { LEAD_STATUS, LEAD_STATUS_REV, REALTOR_STATUS, USER_ROLE } from "../lib/enums.js";
import { serializeUser } from "../lib/serializeUser.js";
import { httpError } from "../lib/httpError.js";
import * as adminRepository from "../repositories/adminRepository.js";

// The control room (/api/admin). Everything here is already gated at the
// router level — requireAuth, then requireRole("ADMIN") on the JWT claim,
// then loadCurrentUser + requireCurrentRole("ADMIN") on the row as Postgres
// has it right now — so no function in this file re-checks the caller's role.
// One exception: setUserRole needs the *acting* admin's id, not their role,
// to enforce the self-demotion rule, and the route passes it in.

const DEFAULT_LIMIT = 25;
const MAX_LIMIT = 100;

// ISO-8601 strings, not the `{ seconds }` Firestore-shaped timestamps the
// mobile-facing endpoints emit (leadService.js, adsSerializer.js,
// notificationService.js). Two reasons this is the right call *here*
// specifically and not a gratuitous second convention: the admin console is
// a brand-new web client with no Firestore-era wire_timestamp.dart to stay
// compatible with, and — decisively — every application/user row below
// embeds serializeUser's `realtor` block, whose `appliedAt`/`decidedAt` are
// already raw Dates that JSON.stringify to ISO strings. Emitting
// `{ seconds }` for the sibling `createdAt` in the same object would put two
// different timestamp shapes one key apart.
const toIso = (date) => (date ? new Date(date).toISOString() : null);

// Postgres EventType (schema.prisma) <-> its lowercase wire key, in the same
// forward/_REV shape as @lacasa/domain's maps. Defined locally rather than
// imported because the domain package has no EventType map: its EVENT_STAGE
// covers only the five legacy Firestore-numbered types (AD_CREATED..
// LEAD_STATUS_CHANGED) and maps them to *numbers*, not wire keys, so the six
// OLX/IG cross-post types have no key there at all. Derived from one list by
// lowercasing rather than hand-written twice, so the two halves cannot drift;
// the list itself must track schema.prisma's `enum EventType`.
const EVENT_TYPES = [
  "AD_CREATED",
  "AD_SOLD",
  "AD_DRAFT_UPDATED",
  "LEAD_CREATED",
  "LEAD_STATUS_CHANGED",
  "OLX_CROSSPOST_STARTED",
  "OLX_CROSSPOST_COMPLETED",
  "OLX_CROSSPOST_ABORTED",
  "IG_ASSIST_STARTED",
  "IG_ASSIST_COMPLETED",
  "IG_ASSIST_ABORTED",
];

export const EVENT_TYPE = Object.fromEntries(EVENT_TYPES.map((v) => [v.toLowerCase(), v]));
const EVENT_TYPE_REV = Object.fromEntries(EVENT_TYPES.map((v) => [v, v.toLowerCase()]));

// Same story for PublishStatus: no domain map exists (@lacasa/domain/enums's
// publish.ts owns channels and extension confirm-events, not this enum), and
// the overview only ever needs the value -> key direction. Lowercasing the
// Postgres value yields exactly the four keys the contract names, including
// `drafted_awaiting_review`.
const PUBLISH_STATUS_KEYS = ["PUBLISHED", "FAILED", "PENDING", "DRAFTED_AWAITING_REVIEW"];

// Clamped rather than rejected: the route's zod schema already answers 400
// for a limit outside 1..100, so reaching this with an out-of-range value
// means some other caller (a test, a future internal consumer) bypassed the
// route. Defense in depth, same as reviewService.js#listReviews.
function resolveTake(limit) {
  return Math.min(Math.max(1, Number(limit) || DEFAULT_LIMIT), MAX_LIMIT);
}

// Splits the "page size + 1" row set the repositories fetch back into the
// page itself and the cursor for the next one. nextCursor is null on the last
// page, which is how a client knows to stop.
function toPage(rows, take) {
  const hasMore = rows.length > take;
  const page = hasMore ? rows.slice(0, take) : rows;
  return { page, nextCursor: hasMore ? page[page.length - 1].id : null };
}

// Turns a Prisma groupBy result into a plain { bucket: count } lookup.
// `values` is the full set of Postgres enum values the response must carry
// and `keyOf` maps each to its output key, so the result is zero-filled:
// groupBy cannot emit a group with count 0 (there are no rows to group), so
// without this a status nobody has ever used would be *missing* from the
// payload rather than reported as 0, and the dashboard would render an empty
// cell instead of a zero.
function tally(rows, field, values, keyOf) {
  const counts = Object.fromEntries(values.map((v) => [keyOf(v), 0]));
  for (const row of rows) {
    const key = keyOf(row[field]);
    if (key in counts) counts[key] = row._count._all;
  }
  return counts;
}

const sum = (rows) => rows.reduce((total, row) => total + row._count._all, 0);

// ---------------------------------------------------------------------------
// GET /api/admin/overview

export async function getOverview(ctx) {
  const [roleRows, applicationRows, adRows, leadRows, publicationRows, recentSignups] =
    await adminRepository.overviewAggregates(ctx.prisma);

  const byRole = tally(roleRows, "role", Object.values(USER_ROLE), (v) => v);
  const byApplication = tally(applicationRows, "realtorStatus", Object.values(REALTOR_STATUS), (v) => v);
  const byStage = tally(adRows, "stage", ["ACTIVE", "SOLD", "DRAFT"], (v) => v);
  const byPublishStatus = tally(publicationRows, "status", PUBLISH_STATUS_KEYS, (v) => v.toLowerCase());

  return {
    // Totals are summed from the grouped rows rather than asked for as a
    // separate count() — the groupBy has no `where`, so its groups already
    // partition the whole table, and a seventh statement would only add a
    // way for the parts to disagree with the whole.
    users: {
      total: sum(roleRows),
      buyers: byRole.USER,
      agents: byRole.AGENT,
      coworkers: byRole.COWORKER,
      admins: byRole.ADMIN,
    },
    // NONE is deliberately dropped: it means "never applied", which is every
    // buyer on the platform, not an application awaiting anyone's attention.
    applications: {
      pending: byApplication.PENDING,
      approved: byApplication.APPROVED,
      rejected: byApplication.REJECTED,
    },
    ads: {
      total: sum(adRows),
      active: byStage.ACTIVE,
      sold: byStage.SOLD,
      draft: byStage.DRAFT,
    },
    leads: {
      total: sum(leadRows),
      // The five keys come from @lacasa/domain's LEAD_STATUS rather than
      // from whatever statuses happen to exist in the table, so a status no
      // lead currently holds still reports 0 instead of vanishing.
      byStatus: tally(leadRows, "status", Object.values(LEAD_STATUS), (v) => LEAD_STATUS_REV[v]),
    },
    publications: {
      published: byPublishStatus.published,
      failed: byPublishStatus.failed,
      pending: byPublishStatus.pending,
      drafted_awaiting_review: byPublishStatus.drafted_awaiting_review,
    },
    recentSignups: recentSignups.map((user) => ({
      id: user.id,
      fullName: user.fullName,
      email: user.email,
      role: user.role.toLowerCase(),
      createdAt: toIso(user.createdAt),
    })),
  };
}

// ---------------------------------------------------------------------------
// Applications

// Built by destructuring serializeUser's output rather than reading the
// Prisma row directly: the `realtor` block's enum lowercasing lives in
// serializeUser.js and must keep living in exactly one place. The fields
// serializeUser carries that an applications table has no use for
// (tgChatIds, igAccounts, avatar, address) are dropped on purpose — an admin
// deciding on an application does not need a buyer's Telegram chat ids.
//
// `realtor` is null for a row whose realtorKind was never set. That should
// not happen for a PENDING/APPROVED/REJECTED row (both are written together
// at signup — see registerSchema/realtorApplicationSchema), but this reports
// what the row actually says rather than fabricating a kind.
function serializeApplicationRow(user) {
  const { id, fullName, email, phoneNumber, realtor } = serializeUser(user);
  return { id, fullName, email, phoneNumber, realtor, createdAt: toIso(user.createdAt) };
}

export async function listApplications(ctx, { status, limit, cursor } = {}) {
  const take = resolveTake(limit);
  // Defaults to the only status that represents work to do. The route's zod
  // enum has already rejected anything outside pending/approved/rejected, so
  // the mapped value can never be NONE and buyers who never applied can never
  // appear in this list.
  const realtorStatus = REALTOR_STATUS[status ?? "pending"];

  const rows = await adminRepository.findApplications(ctx.prisma, { realtorStatus, take: take + 1, cursor });
  const { page, nextCursor } = toPage(rows, take);
  return { items: page.map(serializeApplicationRow), nextCursor };
}

// Approve and reject differ only in the status they write and in whether
// they promote the account, so they share one implementation — two copies of
// the lock/re-read/409 logic is exactly the kind of thing that drifts.
//
// The whole decision runs inside one interactive transaction, and the
// re-read inside it takes a row lock (adminRepository.lockUserForUpdate; see
// that function's comment on why READ COMMITTED makes an unlocked re-read
// meaningless). Without it, two admins clicking Approve on the same
// application at the same moment would both observe PENDING and both write a
// decision — with the second one silently overwriting the first's
// realtorDecidedAt.
async function decideApplication(ctx, userId, { realtorStatus, promote }) {
  const user = await ctx.prisma.$transaction(async (tx) => {
    await adminRepository.lockUserForUpdate(tx, userId);

    const existing = await adminRepository.findUserById(tx, userId);
    if (!existing) {
      throw httpError(404, "not_found", "User not found");
    }
    if (existing.realtorStatus !== "PENDING") {
      throw httpError(409, "not_pending", "This application has already been decided");
    }

    const data = { realtorStatus, realtorDecidedAt: new Date() };
    // Promotion is strictly USER -> AGENT. An account that is already an
    // AGENT (re-applied after an earlier approval), a COWORKER, or an ADMIN
    // keeps the role it has: re-promoting an AGENT is a no-op worth avoiding
    // for clarity, and writing AGENT over COWORKER or ADMIN would be an
    // actual privilege change — a coworker would lose their agency scope and
    // an admin would be quietly demoted out of the control room. Approving an
    // application is a decision about the *application*, not a role reset.
    if (promote && existing.role === "USER") {
      data.role = "AGENT";
    }

    return adminRepository.updateUser(tx, userId, data);
  });

  return { user: serializeUser(user) };
}

export function approveApplication(ctx, userId) {
  return decideApplication(ctx, userId, { realtorStatus: "APPROVED", promote: true });
}

// Rejection leaves `role` untouched on purpose: a rejected applicant is still
// a buyer (or whatever they already were), and demoting them here would be a
// second, unasked-for decision.
export function rejectApplication(ctx, userId) {
  return decideApplication(ctx, userId, { realtorStatus: "REJECTED", promote: false });
}

// ---------------------------------------------------------------------------
// Users

// serializeUser's full shape plus the two things the directory adds: when the
// account joined, and what demoting it would strand. Spreading serializeUser
// (rather than picking fields out of it, as the applications table does)
// keeps this row honest to the contract's "serializeUser shape + ...".
function serializeUserRow(user, counts) {
  return {
    ...serializeUser(user),
    createdAt: toIso(user.createdAt),
    counts: counts ?? { ads: 0, leads: 0 },
  };
}

// Two grouped queries for the whole page, never a pair per row. The two run
// concurrently because neither depends on the other, and both are skipped
// entirely for an empty page — an `in: []` query is a round trip whose answer
// is already known.
async function countsForUsers(ctx, users) {
  if (!users.length) return new Map();

  const userIds = users.map((u) => u.id);
  const [adRows, leadRows] = await Promise.all([
    adminRepository.countAdsByOwnerIds(ctx.prisma, userIds),
    adminRepository.countLeadsByOwnerIds(ctx.prisma, userIds),
  ]);

  const adsByOwner = new Map(adRows.map((r) => [r.agentId, r._count._all]));
  const leadsByOwner = new Map(leadRows.map((r) => [r.agentId, r._count._all]));
  return new Map(
    userIds.map((id) => [id, { ads: adsByOwner.get(id) ?? 0, leads: leadsByOwner.get(id) ?? 0 }]),
  );
}

export async function listUsers(ctx, { q, role, realtorStatus, limit, cursor } = {}) {
  const take = resolveTake(limit);
  const rows = await adminRepository.findUsers(ctx.prisma, {
    q: q || undefined,
    // Both filters arrive as lowercase wire keys and are mapped through the
    // @lacasa/domain maps that own that translation. `undefined` (filter
    // absent) survives the lookup as undefined, which Prisma drops.
    role: role ? USER_ROLE[role] : undefined,
    realtorStatus: realtorStatus ? REALTOR_STATUS[realtorStatus] : undefined,
    take: take + 1,
    cursor,
  });

  const { page, nextCursor } = toPage(rows, take);
  const counts = await countsForUsers(ctx, page);
  return { items: page.map((user) => serializeUserRow(user, counts.get(user.id))), nextCursor };
}

export async function getUser(ctx, id) {
  const user = await adminRepository.findUserById(ctx.prisma, id);
  if (!user) {
    throw httpError(404, "not_found", "User not found");
  }
  const counts = await countsForUsers(ctx, [user]);
  return { user: serializeUserRow(user, counts.get(user.id)) };
}

// PATCH /api/admin/users/:id/role.
//
// Like decideApplication above, the read the guard rails are decided on
// happens inside the transaction and under a lock — but a wider one, because
// "last_admin" is a fact about the whole ADMIN population rather than about
// this row (see adminRepository.lockUsersForRoleChange).
//
// Nothing is cascaded. Demoting an AGENT that still owns ads, leads or
// coworkers is allowed and deletes none of them; the response's `counts`
// block is what makes that honest, so the console can show "this account
// still owns 42 ads" instead of the change looking free.
export async function setUserRole(ctx, { userId, role, actorId }) {
  const nextRole = USER_ROLE[role];

  const user = await ctx.prisma.$transaction(async (tx) => {
    await adminRepository.lockUsersForRoleChange(tx, userId);

    const existing = await adminRepository.findUserById(tx, userId);
    if (!existing) {
      throw httpError(404, "not_found", "User not found");
    }

    // Checked before every other rule and before any write: an admin
    // removing their own admin rights is almost always a misclick, and it is
    // the one mistake they cannot undo themselves afterwards. Note this
    // fires even when another admin exists — "last_admin" protects the
    // platform, this protects the person clicking.
    if (userId === actorId && existing.role === "ADMIN" && nextRole !== "ADMIN") {
      throw httpError(400, "self_demotion", "You cannot remove your own admin role");
    }

    if (existing.role === "ADMIN" && nextRole !== "ADMIN") {
      const remaining = await adminRepository.countAdmins(tx, { excludeUserId: userId });
      if (remaining === 0) {
        throw httpError(409, "last_admin", "This is the last admin account; promote another admin first");
      }
    }

    // A COWORKER's every scoped read and write resolves through
    // effectiveAgentId(), which returns `user.agentId` for that role — a
    // coworker with no agentId would be an account that can reach the Work
    // tab and see nothing, with no way to fix itself. There is no admin
    // endpoint for setting agentId (assigning a coworker to an agency is the
    // agent's own job, POST /api/coworkers), so this refuses rather than
    // guessing an agency.
    if (nextRole === "COWORKER" && !existing.agentId) {
      throw httpError(
        400,
        "coworker_needs_agent",
        "This account has no owning agent; it must be invited by an agent before it can be a coworker",
      );
    }

    // No early return for a no-op change (role already === nextRole): the
    // write is idempotent, and short-circuiting would make the response's
    // updatedAt lie about when the row was last touched only in that one
    // case.
    return adminRepository.updateUser(tx, userId, { role: nextRole });
  });

  // Counted after the transaction commits: nothing in it touches ads or
  // leads, so these numbers are the same either side of it, and keeping two
  // aggregate queries out of a lock-holding transaction keeps the lock
  // window as short as the write itself.
  const counts = await countsForUsers(ctx, [user]);
  return { user: serializeUserRow(user, counts.get(user.id)) };
}

// ---------------------------------------------------------------------------
// GET /api/admin/audit

// `agent` is typed nullable on the wire for symmetry with the other three,
// but ActivityEvent.agentId is non-nullable in schema.prisma, so in practice
// it is always present. The other three are genuinely optional: an event may
// be the agent's own (no coworker), and only ad/lead events carry a subject —
// and both of those relations are `onDelete: SetNull`, so an event whose ad
// was deleted survives in the trail with a null subject rather than
// disappearing from it.
function serializeAuditRow(event) {
  return {
    id: event.id,
    type: EVENT_TYPE_REV[event.type] ?? event.type.toLowerCase(),
    createdAt: toIso(event.createdAt),
    agent: event.agent ? { id: event.agent.id, fullName: event.agent.fullName } : null,
    coworker: event.coworker ? { id: event.coworker.id, fullName: event.coworker.fullName } : null,
    ad: event.ad ? { id: event.ad.id, title: event.ad.title } : null,
    lead: event.lead ? { id: event.lead.id, fullName: event.lead.fullName } : null,
    meta: event.meta ?? null,
  };
}

export async function listAudit(ctx, { type, agentId, limit, cursor } = {}) {
  const take = resolveTake(limit);
  const rows = await adminRepository.findAuditEvents(ctx.prisma, {
    type: type ? EVENT_TYPE[type] : undefined,
    agentId: agentId || undefined,
    take: take + 1,
    cursor,
  });

  const { page, nextCursor } = toPage(rows, take);
  return { items: page.map(serializeAuditRow), nextCursor };
}
