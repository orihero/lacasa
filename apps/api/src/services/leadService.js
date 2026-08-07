import { LEAD_STATUS, LEAD_STATUS_REV } from "../lib/enums.js";
import { createWithActivityEvent, logActivityEvent } from "../lib/activity.js";
import * as leadRepository from "../repositories/leadRepository.js";

export function serializeLead(lead) {
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

export function parseLeadInput(body) {
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

// Matches the pre-migration behavior: both agents and their coworkers see
// the full agent-scoped lead list (LeadList.jsx never actually scoped
// coworkers down to their own leads — see docs/05 Phase D notes).
export async function listLeads(ctx, agentId) {
  const leads = await leadRepository.findManyLeads(ctx.prisma, { where: { agentId }, orderBy: { createdAt: "desc" } });
  return leads.map(serializeLead);
}

export async function getLead(ctx, id, agentId) {
  const lead = await leadRepository.findLeadByIdForAgent(ctx.prisma, id, agentId);
  return lead ? serializeLead(lead) : null;
}

export async function createLead(ctx, body, actor) {
  const data = parseLeadInput(body);

  const lead = await createWithActivityEvent(
    ctx,
    "lead",
    "LEAD_CREATED",
    {
      data: {
        ...data,
        status: data.status ?? "NEW",
        active: data.active ?? true,
        agentId: actor.agentId,
        coworkerId: actor.coworkerId,
      },
    },
    actor,
  );

  return serializeLead(lead);
}

// Returns null when no lead matches `id` under `agentId` (caller maps that
// to 404).
export async function updateLead(ctx, id, agentId, body, actor) {
  const existing = await leadRepository.findLeadByIdForAgent(ctx.prisma, id, agentId);
  if (!existing) return null;

  const data = parseLeadInput(body);
  const lead = await leadRepository.updateLead(ctx.prisma, id, data);

  // Faithful to the original: every update logs a LEAD_STATUS_CHANGED
  // event, not just ones that actually change `status` — see LeadUpdate.jsx
  // and LeadKanbanList.tsx, both of which log unconditionally.
  await logActivityEvent(ctx, "LEAD_STATUS_CHANGED", actor, { leadId: lead.id });

  return serializeLead(lead);
}

// Returns null when no lead matches (404), true once deleted. Only an AGENT
// may delete (enforced by the route, which is why `agentId` here is always
// the caller's own id, never a coworker's agent scope).
export async function deleteLead(ctx, id, agentId) {
  const existing = await leadRepository.findLeadByIdForAgent(ctx.prisma, id, agentId);
  if (!existing) return null;
  await leadRepository.deleteLead(ctx.prisma, id);
  return true;
}
