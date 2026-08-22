import { Router } from "express";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import { effectiveAgentId } from "../middleware/roles.js";
import * as statisticsService from "../services/statisticsService.js";

const router = Router();

router.use(requireAuth, loadCurrentUser);

// Any httpError thrown by statisticsService (see its `status`/`code`) maps
// straight to the matching HTTP response; anything else falls through to
// the app's generic error middleware. Mirrors routes/publish.js's
// handleServiceError.
function handleServiceError(e, res, next) {
  if (e.status) {
    return res.status(e.status).json({ error: { code: e.code, message: e.message } });
  }
  next(e);
}

router.get("/ads", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    res.json(await statisticsService.getAdsCounts(req.ctx, agentId, req.query.filterType));
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

// Bucketed AD_CREATED/AD_SOLD time series — see statisticsService.js for the
// granularity rule and the zero-fill/timezone reasoning. `?filterType=` reuses
// the today/thisWeek/thisMonth vocabulary; an explicit `?from=&to=` overrides it.
router.get("/ads/series", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    res.json(await statisticsService.getAdsSeries(req.ctx, agentId, req.query));
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

router.get("/coworkers", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    res.json(await statisticsService.getCoworkerEvents(req.ctx, agentId));
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

// Aggregated per-coworker counts (ads created/sold, leads created) plus
// last-active timestamp, folded from the same ActivityEvent rows GET
// /coworkers already exposes raw — see statisticsService.js#getCoworkerSummary.
router.get("/coworkers/summary", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    res.json(await statisticsService.getCoworkerSummary(req.ctx, agentId));
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

export default router;
