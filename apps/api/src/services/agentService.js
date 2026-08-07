import * as agentRepository from "../repositories/agentRepository.js";
import * as adRepository from "../repositories/adRepository.js";

// The public agent card. Deliberately a hand-picked field list rather than the
// whole User row — this is served unauthenticated, and passwordHash, the
// realtor application and the TG chat ids have no business on it.
function serializeAgent(agent, adsCount) {
  return {
    id: agent.id,
    fullName: agent.fullName,
    email: agent.email,
    phoneNumber: agent.phoneNumber,
    avatar: agent.avatarUrl,
    adsCount,
  };
}

function adsCountFor(counts, agentId) {
  return Object.fromEntries(counts.map((c) => [c.agentId, c._count._all]))[agentId] ?? 0;
}

export async function listAgents(ctx) {
  const agents = await agentRepository.findAgents(ctx.prisma);
  const counts = await agentRepository.countAdsByAgentIds(
    ctx.prisma,
    agents.map((a) => a.id),
  );
  return agents.map((a) => serializeAgent(a, adsCountFor(counts, a.id)));
}

// Listing detail shows "N listings · M closed" under the agent (SCREENS.md
// §4.3), so the single-agent card carries both counts. `dealsClosedCount`
// reuses adRepository.countAdsByStage — the same query behind
// GET /my/ads/stage-counts — rather than adding a second way to count SOLD.
export async function getAgent(ctx, id) {
  const agent = await agentRepository.findAgentById(ctx.prisma, id);
  if (!agent) return null;

  const [counts, byStage] = await Promise.all([
    agentRepository.countAdsByAgentIds(ctx.prisma, [agent.id]),
    adRepository.countAdsByStage(ctx.prisma, agent.id),
  ]);

  const dealsClosedCount = Object.fromEntries(byStage.map((c) => [c.stage, c._count._all])).SOLD ?? 0;

  return { ...serializeAgent(agent, adsCountFor(counts, agent.id)), dealsClosedCount };
}
