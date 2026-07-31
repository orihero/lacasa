// Prisma calls only — no business logic, no HTTP concerns. Every function
// takes `prisma` (i.e. `ctx.prisma`) as its first argument so it stays
// testable against the fake ctx in test/helpers/testApp.js without a real
// database.

export function findManyLeads(prisma, { where, orderBy }) {
  return prisma.lead.findMany({ where, orderBy });
}

export function findLeadByIdForAgent(prisma, id, agentId) {
  return prisma.lead.findFirst({ where: { id, agentId } });
}

export function updateLead(prisma, id, data) {
  return prisma.lead.update({ where: { id }, data });
}

export function deleteLead(prisma, id) {
  return prisma.lead.delete({ where: { id } });
}
