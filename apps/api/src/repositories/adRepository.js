// Prisma calls only — no business logic, no HTTP concerns. Every function
// takes `prisma` (i.e. `ctx.prisma`) as its first argument so it stays
// testable against the fake ctx in test/helpers/testApp.js without a real
// database.

export const AD_INCLUDE = { photos: true };

export function findManyAds(prisma, { where, orderBy }) {
  return prisma.ad.findMany({ where, include: AD_INCLUDE, orderBy });
}

export function findAdById(prisma, id) {
  return prisma.ad.findUnique({ where: { id }, include: AD_INCLUDE });
}

export function findAdByIdForAgent(prisma, id, agentId) {
  return prisma.ad.findFirst({ where: { id, agentId }, include: AD_INCLUDE });
}

export function updateAd(prisma, id, data) {
  return prisma.ad.update({ where: { id }, data, include: AD_INCLUDE });
}

export function deleteAd(prisma, id) {
  return prisma.ad.delete({ where: { id } });
}

export function countAdsByStage(prisma, agentId) {
  return prisma.ad.groupBy({ by: ["stage"], where: { agentId }, _count: { _all: true } });
}
