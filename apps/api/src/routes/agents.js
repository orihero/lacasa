import { Router } from "express";
import * as agentService from "../services/agentService.js";

const router = Router();

// Public: the agent directory and the agent card under a listing are both
// read by anonymous visitors.
router.get("/", async (req, res, next) => {
  try {
    res.json(await agentService.listAgents(req.ctx));
  } catch (e) {
    next(e);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    const agent = await agentService.getAgent(req.ctx, req.params.id);
    if (!agent) {
      return res.status(404).json({ error: { code: "not_found", message: "Agent not found" } });
    }
    res.json(agent);
  } catch (e) {
    next(e);
  }
});

export default router;
