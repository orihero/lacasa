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
    const sort = req.query.sort;
    const orderBy =
      sort === "highestPrice"
        ? { price: "desc" }
        : sort === "lowestPrice"
          ? { price: "asc" }
          : { createdAt: "desc" };

    res.json(await adService.listAds(req.ctx, req.query, { agentId, orderBy }));
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
