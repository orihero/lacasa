// Prisma calls only — no business logic, no HTTP concerns. Every function
// takes `prisma` (i.e. `ctx.prisma`) as its first argument so it stays
// testable against the fake ctx in test/helpers/testApp.js without a real
// database. Mirrors savedAdRepository.js's shape (that model's dedup and
// idempotent-unsave behaviour is the direct template for this one -- see
// prisma/schema.prisma's DeviceToken doc comment).

// Upsert, not create: registering an already-registered device (app
// relaunch resending its current token) is the same fact, so it must not
// blow up on the @@unique([userId, token]) constraint. `userId_token` is
// Prisma's generated name for that compound key. `platform` is re-written on
// every call rather than left untouched, in case a token were ever somehow
// reissued to a different OS than it was first seen on -- cheap to keep
// current, never wrong to overwrite with what the caller just asserted.
export function upsertDeviceToken(prisma, userId, token, platform) {
  return prisma.deviceToken.upsert({
    where: { userId_token: { userId, token } },
    create: { userId, token, platform },
    update: { platform },
  });
}

// deleteMany, not delete: unregistering a device that was never registered
// (or already unregistered) is a no-op, not a P2025. Returns { count } so
// callers can tell the two apart if they care, same as
// savedAdRepository.js#deleteSavedAd.
export function deleteDeviceToken(prisma, userId, token) {
  return prisma.deviceToken.deleteMany({ where: { userId, token } });
}

// Every device a push send needs to fan out to for one user. Called on
// every fire-and-forget push attempt (pushService.js#sendPushToUser) --
// there is no notion of a "primary" device, a user with three installs gets
// the same notification on all three.
export function findDeviceTokensForUser(prisma, userId) {
  return prisma.deviceToken.findMany({ where: { userId } });
}
