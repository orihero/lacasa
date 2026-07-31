import { Router } from "express";
import { prisma } from "../lib/prisma.js";

const router = Router();

router.get("/", async (_req, res, next) => {
  try {
    const agents = await prisma.user.findMany({ where: { role: "AGENT" } });
    const counts = await prisma.activityEvent.groupBy({
      by: ["agentId"],
      where: { type: "AD_CREATED", agentId: { in: agents.map((a) => a.id) } },
      _count: { _all: true },
    });
    const countByAgent = Object.fromEntries(counts.map((c) => [c.agentId, c._count._all]));

    res.json(
      agents.map((a) => ({
        id: a.id,
        fullName: a.fullName,
        email: a.email,
        phoneNumber: a.phoneNumber,
        avatar: a.avatarUrl,
        adsCount: countByAgent[a.id] ?? 0,
      })),
    );
  } catch (e) {
    next(e);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    const agent = await prisma.user.findFirst({ where: { id: req.params.id, role: "AGENT" } });
    if (!agent) {
      return res.status(404).json({ error: { code: "not_found", message: "Agent not found" } });
    }
    res.json({
      id: agent.id,
      fullName: agent.fullName,
      email: agent.email,
      phoneNumber: agent.phoneNumber,
      avatar: agent.avatarUrl,
    });
  } catch (e) {
    next(e);
  }
});

export default router;
