// Prisma calls only — no business logic, no HTTP concerns. Every function
// takes `prisma` (i.e. `ctx.prisma`) as its first argument so it stays
// testable against the fake ctx in test/helpers/testApp.js without a real
// database.

export const AD_INCLUDE = { photos: true };

// `take` is optional and omitted from the call entirely when absent (rather
// than passed as `take: undefined`) so the existing non-paged callers/tests
// that assert the exact findMany() call shape (no `take` key at all) keep
// matching -- adding `take: undefined` to every call would still behave the
// same at the Postgres level but would change the object shape those
// assertions check.
export function findManyAds(prisma, { where, orderBy, take }) {
  return prisma.ad.findMany({ where, include: AD_INCLUDE, orderBy, ...(take ? { take } : {}) });
}

// Row count for the same `where` findManyAds would have run, without
// selecting (or joining `photos` onto) a single row. Its one caller is
// listAds()'s `?countOnly=true` branch, which exists so the mobile filter
// sheet's live "Apply Filters (N)" preview can stop downloading the entire
// serialized result set just to read `.length` off it.
export function countAds(prisma, { where }) {
  return prisma.ad.count({ where });
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
