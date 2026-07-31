import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import { effectiveAgentId } from "../middleware/roles.js";
import { LEAD_STATUS, LEAD_STATUS_REV } from "../lib/enums.js";

const router = Router();

function serializeLead(lead) {
  return {
    id: lead.id,
    fullName: lead.fullName,
    phone: lead.phone,
    email: lead.email,
    budget: lead.budget !== null ? Number(lead.budget) : null,
    comment: lead.comment,
    conversationComment: lead.conversationComment,
    status: LEAD_STATUS_REV[lead.status],
    source: lead.source,
    callbackDate: lead.callbackDate,
    active: lead.active,
    agentId: lead.agentId,
    coworkerId: lead.coworkerId ?? "",
    createdAt: { seconds: Math.floor(new Date(lead.createdAt).getTime() / 1000) },
    updatedAt: { seconds: Math.floor(new Date(lead.updatedAt).getTime() / 1000) },
  };
}

function parseLeadInput(body) {
  const data = {};
  if (body.fullName !== undefined) data.fullName = String(body.fullName);
  if (body.phone !== undefined) data.phone = String(body.phone);
  if (body.email !== undefined) data.email = body.email || null;
  if (body.budget !== undefined) data.budget = body.budget === "" || body.budget == null ? null : Number(body.budget);
  if (body.comment !== undefined) data.comment = body.comment || null;
  if (body.conversationComment !== undefined) data.conversationComment = body.conversationComment || null;
  if (body.status !== undefined) data.status = LEAD_STATUS[body.status] ?? "NEW";
  if (body.source !== undefined) data.source = body.source || null;
  if (body.callbackDate !== undefined) data.callbackDate = body.callbackDate ? new Date(body.callbackDate) : null;
  if (body.active !== undefined) data.active = Boolean(body.active);
  return data;
}

router.use(requireAuth, loadCurrentUser);

// Matches the pre-migration behavior: both agents and their coworkers see
// the full agent-scoped lead list (LeadList.jsx never actually scoped
// coworkers down to their own leads — see docs/05 Phase D notes).
router.get("/", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    const leads = await prisma.lead.findMany({ where: { agentId }, orderBy: { createdAt: "desc" } });
    res.json(leads.map(serializeLead));
  } catch (e) {
    next(e);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    const lead = await prisma.lead.findFirst({ where: { id: req.params.id, agentId } });
    if (!lead) {
      return res.status(404).json({ error: { code: "not_found", message: "Lead not found" } });
    }
    res.json(serializeLead(lead));
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

    const data = parseLeadInput(req.body);
    const lead = await prisma.lead.create({
      data: {
        ...data,
        status: data.status ?? "NEW",
        active: data.active ?? true,
        agentId,
        coworkerId: req.currentUser.role === "COWORKER" ? req.currentUser.id : null,
      },
    });

    await prisma.activityEvent.create({
      data: {
        type: "LEAD_CREATED",
        agentId,
        coworkerId: req.currentUser.role === "COWORKER" ? req.currentUser.id : null,
        leadId: lead.id,
      },
    });

    res.status(201).json(serializeLead(lead));
  } catch (e) {
    next(e);
  }
});

router.patch("/:id", async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    const existing = await prisma.lead.findFirst({ where: { id: req.params.id, agentId } });
    if (!existing) {
      return res.status(404).json({ error: { code: "not_found", message: "Lead not found" } });
    }

    const data = parseLeadInput(req.body);
    const lead = await prisma.lead.update({ where: { id: req.params.id }, data });

    // Faithful to the original: every update logs a LEAD_STATUS_CHANGED
    // event, not just ones that actually change `status` — see LeadUpdate.jsx
    // and LeadKanbanList.tsx, both of which log unconditionally.
    await prisma.activityEvent.create({
      data: {
        type: "LEAD_STATUS_CHANGED",
        agentId,
        coworkerId: req.currentUser.role === "COWORKER" ? req.currentUser.id : null,
        leadId: lead.id,
      },
    });

    res.json(serializeLead(lead));
  } catch (e) {
    next(e);
  }
});

router.delete("/:id", async (req, res, next) => {
  try {
    if (req.currentUser.role !== "AGENT") {
      return res.status(403).json({ error: { code: "forbidden", message: "Only the owning agent can delete a lead" } });
    }
    const existing = await prisma.lead.findFirst({ where: { id: req.params.id, agentId: req.currentUser.id } });
    if (!existing) {
      return res.status(404).json({ error: { code: "not_found", message: "Lead not found" } });
    }
    await prisma.lead.delete({ where: { id: req.params.id } });
    res.status(204).end();
  } catch (e) {
    next(e);
  }
});

export default router;
