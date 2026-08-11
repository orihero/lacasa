// GET /api/notifications — see notificationService.js's header comment for
// the full design rationale (derived feed, deterministic ids, why read
// state is a query param and not a stored value). This route is just the
// usual thin HTTP layer: parse query params, enforce the agent-scope guard,
// call the service, map errors to the envelope.
import { Router } from "express";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import { effectiveAgentId } from "../middleware/roles.js";
import { listNotifications, DEFAULT_LIMIT, MAX_LIMIT } from "../services/notificationService.js";

const router = Router();

router.use(requireAuth, loadCurrentUser);

router.get("/", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }

    let since = null;
    if (req.query.since !== undefined) {
      const parsed = new Date(req.query.since);
      if (Number.isNaN(parsed.getTime())) {
        // "validation", not a bespoke "invalid_since" -- every other route in
        // this codebase (ads/auth/users/coworkers/publish/agents' reviews)
        // answers a malformed-input 400 with code "validation", and a client
        // switching on error codes shouldn't need a second code for the same
        // condition just because this route validates a query string instead
        // of a body.
        return res.status(400).json({ error: { code: "validation", message: "since must be a valid ISO 8601 timestamp" } });
      }
      since = parsed;
    }

    let limit = DEFAULT_LIMIT;
    if (req.query.limit !== undefined) {
      const parsed = Number(req.query.limit);
      if (!Number.isFinite(parsed) || parsed < 1) {
        return res.status(400).json({ error: { code: "validation", message: "limit must be a positive integer" } });
      }
      limit = Math.min(Math.trunc(parsed), MAX_LIMIT);
    }

    const notifications = await listNotifications(req.ctx, { agentId, since, limit });
    res.json(notifications);
  } catch (e) {
    next(e);
  }
});

export default router;
