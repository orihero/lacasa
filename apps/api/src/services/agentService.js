import * as agentRepository from "../repositories/agentRepository.js";
import * as adRepository from "../repositories/adRepository.js";

// The public agent card. Deliberately a hand-picked field list rather than the
// whole User row — this is served unauthenticated, and passwordHash, the
// realtor application and the TG chat ids have no business on it.
//
// `rating` is `{ ratingAverage, ratingCount }` from ratingFor() below, kept
// as a separate parameter (rather than merged into the returned object by
// the caller) so every call site is forced to decide it explicitly instead
// of one day forgetting it and silently shipping `undefined`.
function serializeAgent(agent, adsCount, rating) {
  return {
    id: agent.id,
    fullName: agent.fullName,
    email: agent.email,
    phoneNumber: agent.phoneNumber,
    avatar: agent.avatarUrl,
    address: agent.address ?? null,
    adsCount,
    ratingAverage: rating.ratingAverage,
    ratingCount: rating.ratingCount,
  };
}

function adsCountFor(counts, agentId) {
  return Object.fromEntries(counts.map((c) => [c.agentId, c._count._all]))[agentId] ?? 0;
}

// An agent absent from `aggregates` has zero reviews -- groupBy's COUNT(*)
// can't produce a zero-row group, so "no row" is the only signal we get.
// That absence must come out as `ratingAverage: null`, never `0` or `0.0`:
// a null is what lets the client render "No reviews yet" instead of
// drawing a one-star agent card for someone nobody has rated (see
// mockups/SCREENS.md §3.9). Rounded to one decimal to match the
// "Review: {rating}/5" star row's display precision.
function ratingsByAgentId(aggregates) {
  return Object.fromEntries(
    aggregates.map((a) => [
      a.agentId,
      { ratingAverage: Math.round(a._avg.rating * 10) / 10, ratingCount: a._count._all },
    ]),
  );
}

function ratingFor(ratings, agentId) {
  return ratings[agentId] ?? { ratingAverage: null, ratingCount: 0 };
}

export async function listAgents(ctx) {
  const agents = await agentRepository.findAgents(ctx.prisma);
  const agentIds = agents.map((a) => a.id);
  // One groupBy for every agent's rating aggregate, run alongside the
  // existing ads-count groupBy -- an N+1 (one aggregate query per agent
  // card) is the obvious wrong way to build this list.
  const [counts, ratingAggregates] = await Promise.all([
    agentRepository.countAdsByAgentIds(ctx.prisma, agentIds),
    agentRepository.aggregateRatingsForAgentIds(ctx.prisma, agentIds),
  ]);
  const ratings = ratingsByAgentId(ratingAggregates);
  return agents.map((a) => serializeAgent(a, adsCountFor(counts, a.id), ratingFor(ratings, a.id)));
}

// Listing detail shows "N listings · M closed" under the agent (SCREENS.md
// §4.3), so the single-agent card carries both counts. `dealsClosedCount`
// reuses adRepository.countAdsByStage — the same query behind
// GET /my/ads/stage-counts — rather than adding a second way to count SOLD.
export async function getAgent(ctx, id) {
  const agent = await agentRepository.findAgentById(ctx.prisma, id);
  if (!agent) return null;

  const [counts, byStage, ratingAggregates] = await Promise.all([
    agentRepository.countAdsByAgentIds(ctx.prisma, [agent.id]),
    adRepository.countAdsByStage(ctx.prisma, agent.id),
    agentRepository.aggregateRatingsForAgentIds(ctx.prisma, [agent.id]),
  ]);

  const dealsClosedCount = Object.fromEntries(byStage.map((c) => [c.stage, c._count._all])).SOLD ?? 0;
  const rating = ratingFor(ratingsByAgentId(ratingAggregates), agent.id);

  return { ...serializeAgent(agent, adsCountFor(counts, agent.id), rating), dealsClosedCount };
}
