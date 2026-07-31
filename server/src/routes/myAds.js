import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import { effectiveAgentId } from "../middleware/roles.js";
import { serializeAd } from "../lib/adsSerializer.js";
import { buildAdFilters, AD_INCLUDE } from "./ads.js";

const router = Router();

router.use(requireAuth, loadCurrentUser);

router.get("/", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    const filters = buildAdFilters(req.query);
    const sort = req.query.sort;
    const orderBy =
      sort === "highestPrice"
        ? { price: "desc" }
        : sort === "lowestPrice"
          ? { price: "asc" }
          : { createdAt: "desc" };

    const ads = await prisma.ad.findMany({
      where: { ...filters, agentId },
      include: AD_INCLUDE,
      orderBy,
    });
    res.json(ads.map(serializeAd));
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
    const counts = await prisma.ad.groupBy({ by: ["stage"], where: { agentId }, _count: { _all: true } });
    const byStage = Object.fromEntries(counts.map((c) => [c.stage, c._count._all]));
    res.json({
      stage1: byStage.ACTIVE ?? 0,
      stage2: byStage.SOLD ?? 0,
      stage3: byStage.DRAFT ?? 0,
    });
  } catch (e) {
    next(e);
  }
});

export default router;
