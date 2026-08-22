// Prisma calls only — no business logic, no HTTP concerns. Every function
// takes `prisma` (i.e. `ctx.prisma`) as its first argument so it stays
// testable against the fake ctx in test/helpers/testApp.js without a real
// database.

export function findAgents(prisma) {
  return prisma.user.findMany({ where: { role: "AGENT" } });
}

// Scoped to role AGENT, so a coworker's or buyer's id 404s here rather than
// exposing them through the public agent card.
export function findAgentById(prisma, id) {
  return prisma.user.findFirst({ where: { id, role: "AGENT" } });
}

// One grouped query for however many agents, rather than a count per agent.
// Prisma handles an empty `in` list fine, so callers need no special case.
export function countAdsByAgentIds(prisma, agentIds) {
  return prisma.activityEvent.groupBy({
    by: ["agentId"],
    where: { type: "AD_CREATED", agentId: { in: agentIds } },
    _count: { _all: true },
  });
}

// Same shape/reasoning as countAdsByAgentIds above: one groupBy for however
// many agents are on the current page (GET /api/agents) or exactly one
// (GET /api/agents/:id), rather than a query per agent card. An agent with
// zero reviews simply has no row in the result -- COUNT(*)/AVG() can't
// produce a zero-row group -- and agentService turns that absence into
// `ratingAverage: null` rather than defaulting to 0.
export function aggregateRatingsForAgentIds(prisma, agentIds) {
  return prisma.agentReview.groupBy({
    by: ["agentId"],
    where: { agentId: { in: agentIds } },
    _avg: { rating: true },
    _count: { _all: true },
  });
}

// Newest first, keyed by (createdAt, id) so the ordering is stable even
// when two reviews land in the same millisecond -- id is the tie-breaker
// and also the cursor value itself, since it's the unique field Prisma's
// cursor pagination needs. `take` is the caller's page size *plus one*
// (see reviewService.listReviews): fetching one extra row is how the
// service tells "there is a next page" apart from "this was the last row"
// without a second COUNT query.
export function findReviewsForAgent(prisma, agentId, { take, cursor } = {}) {
  return prisma.agentReview.findMany({
    where: { agentId },
    orderBy: [{ createdAt: "desc" }, { id: "desc" }],
    take,
    ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
    include: { author: true },
  });
}

// Upsert on the (agentId, authorId) unique pair so a second review from the
// same author edits the first rather than stacking a new row next to it
// (SCREENS.md's aggregate would otherwise be swingable by one account
// posting repeatedly). `include: { author: true }` costs one join but saves
// the service layer a second round trip to build the response's author
// block.
export function upsertReview(prisma, { agentId, authorId, rating, comment }) {
  return prisma.agentReview.upsert({
    where: { agentId_authorId: { agentId, authorId } },
    create: { agentId, authorId, rating, comment },
    update: { rating, comment },
    include: { author: true },
  });
}

// Mirrors savedAdService.js#unsaveAd: deleting a review that doesn't exist
// leaves the caller in exactly the state they asked for, so this is a
// deleteMany (never throws P2025) rather than a delete keyed on the unique
// pair.
export function deleteReview(prisma, agentId, authorId) {
  return prisma.agentReview.deleteMany({ where: { agentId, authorId } });
}
