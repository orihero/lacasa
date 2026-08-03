// Prisma calls only — no business logic, no HTTP concerns. Every function
// takes `prisma` (i.e. `ctx.prisma`) as its first argument so it stays
// testable against the fake ctx in test/helpers/testApp.js without a real
// database.

import { AD_INCLUDE } from "./adRepository.js";

// The saved list renders full listing cards, so it pulls the ad (and its
// photos, via the same include the ad repository uses) rather than bare ids.
export function findManySavedAdsForUser(prisma, userId) {
  return prisma.savedAd.findMany({
    where: { userId },
    include: { ad: { include: AD_INCLUDE } },
    orderBy: { createdAt: "desc" },
  });
}

// Upsert, not create: saving an already-saved ad is the same fact, so it must
// not blow up on the @@unique([userId, adId]) constraint. `userId_adId` is
// Prisma's generated name for that compound key.
export function upsertSavedAd(prisma, userId, adId) {
  return prisma.savedAd.upsert({
    where: { userId_adId: { userId, adId } },
    create: { userId, adId },
    update: {},
  });
}

// deleteMany, not delete: unsaving something that was never saved is a no-op,
// not a P2025. Returns { count } so callers can tell the two apart if they care.
export function deleteSavedAd(prisma, userId, adId) {
  return prisma.savedAd.deleteMany({ where: { userId, adId } });
}
