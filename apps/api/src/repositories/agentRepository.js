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
