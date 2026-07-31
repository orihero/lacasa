import { Router } from "express";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import { effectiveAgentId } from "../middleware/roles.js";
import * as leadService from "../services/leadService.js";

const router = Router();

router.use(requireAuth, loadCurrentUser);

router.get("/", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    res.json(await leadService.listLeads(req.ctx, agentId));
  } catch (e) {
    next(e);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    const lead = await leadService.getLead(req.ctx, req.params.id, agentId);
    if (!lead) {
      return res.status(404).json({ error: { code: "not_found", message: "Lead not found" } });
    }
    res.json(lead);
  } catch (e) {
    next(e);
  }
});

router.post("/", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    const actor = { agentId, coworkerId: req.currentUser.role === "COWORKER" ? req.currentUser.id : null };
    const lead = await leadService.createLead(req.ctx, req.body, actor);
    res.status(201).json(lead);
  } catch (e) {
    next(e);
  }
});

router.patch("/:id", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    const actor = { agentId, coworkerId: req.currentUser.role === "COWORKER" ? req.currentUser.id : null };
    const lead = await leadService.updateLead(req.ctx, req.params.id, agentId, req.body, actor);
    if (!lead) {
      return res.status(404).json({ error: { code: "not_found", message: "Lead not found" } });
    }
    res.json(lead);
  } catch (e) {
    next(e);
  }
});

router.delete("/:id", async (req, res, next) => {
  try {
    if (req.currentUser.role !== "AGENT") {
      return res.status(403).json({ error: { code: "forbidden", message: "Only the owning agent can delete a lead" } });
    }
    const deleted = await leadService.deleteLead(req.ctx, req.params.id, req.currentUser.id);
    if (!deleted) {
      return res.status(404).json({ error: { code: "not_found", message: "Lead not found" } });
    }
    res.status(204).end();
  } catch (e) {
    next(e);
  }
});

export default router;
