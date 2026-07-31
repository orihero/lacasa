import { Router } from "express";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import { effectiveAgentId } from "../middleware/roles.js";
import { EVENT_STAGE } from "../lib/enums.js";

const router = Router();

router.use(requireAuth, loadCurrentUser);

function dateRangeFor(filterType) {
  const now = new Date();
  switch (filterType) {
    case "today": {
      const start = new Date(now);
      start.setHours(0, 0, 0, 0);
      const end = new Date(now);
      end.setHours(23, 59, 59, 999);
      return [start, end];
    }
    case "thisWeek": {
      const start = new Date(now);
      start.setDate(now.getDate() - now.getDay());
      start.setHours(0, 0, 0, 0);
      const end = new Date(start);
      end.setDate(start.getDate() + 6);
      end.setHours(23, 59, 59, 999);
      return [start, end];
    }
    case "thisMonth": {
      const start = new Date(now.getFullYear(), now.getMonth(), 1);
      const end = new Date(now.getFullYear(), now.getMonth() + 1, 0);
      end.setHours(23, 59, 59, 999);
      return [start, end];
    }
    default:
      return [null, null];
  }
}

router.get("/ads", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    const [start, end] = dateRangeFor(req.query.filterType);
    const range = start && end ? { gte: start, lte: end } : undefined;

    const [adsNewCount, adsSoldCount] = await Promise.all([
      req.ctx.prisma.activityEvent.count({ where: { agentId, type: "AD_CREATED", ...(range ? { createdAt: range } : {}) } }),
      req.ctx.prisma.activityEvent.count({ where: { agentId, type: "AD_SOLD", ...(range ? { createdAt: range } : {}) } }),
    ]);

    res.json({ adsNewCount, adsSoldCount });
  } catch (e) {
    next(e);
  }
});

router.get("/coworkers", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    const events = await req.ctx.prisma.activityEvent.findMany({ where: { agentId } });
    res.json(
      events.map((e) => ({
        id: e.id,
        agentId: e.agentId,
        coworkerId: e.coworkerId ?? "",
        adId: e.adId ?? "",
        leadId: e.leadId ?? "",
        stage: EVENT_STAGE[e.type],
        createdAt: { seconds: Math.floor(new Date(e.createdAt).getTime() / 1000) },
      })),
    );
  } catch (e) {
    next(e);
  }
});

export default router;
