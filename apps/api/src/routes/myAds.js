import { Router } from "express";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import { effectiveAgentId } from "../middleware/roles.js";
import * as adService from "../services/adService.js";

const router = Router();

router.use(requireAuth, loadCurrentUser);

router.get("/", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    // `sort`/`q`/`stage`/`limit`/`cursor`/`paged` all flow straight through
    // to adService.listAds via `req.query` -- it resolves `sort` through its
    // own wire-value whitelist (which still recognises `highestPrice`/
    // `lowestPrice`, the two values this route used to map by hand right
    // here), so there's nothing left for this route to compute itself.
    res.json(await adService.listAds(req.ctx, req.query, { agentId }));
  } catch (e) {
    next(e);
  }
});

router.get("/stage-counts", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    res.json(await adService.stageCounts(req.ctx, agentId));
  } catch (e) {
    next(e);
  }
});

export default router;
