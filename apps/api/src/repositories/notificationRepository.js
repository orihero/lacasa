// Prisma calls only — no business logic, no HTTP concerns. Every function
// takes `prisma` (i.e. `ctx.prisma`) as its first argument so it stays
// testable against the fake ctx in test/helpers/testApp.js without a real
// database.
//
// There is no `notifications` table (see notificationService.js's header
// comment for why) — every function here reads one of the four source
// models the feed is derived from, always scoped to the caller's
// `effectiveAgentId`.

// LEAD_CREATED fires once per lead; LEAD_STATUS_CHANGED fires on every
// update regardless of whether `status` itself changed (see
// leadService.js#updateLead) — both are surfaced, the service layer doesn't
// try to guess which status-changed events were "real" transitions.
export function findLeadActivityEvents(prisma, agentId) {
  return prisma.activityEvent.findMany({
    where: { agentId, type: { in: ["LEAD_CREATED", "LEAD_STATUS_CHANGED"] } },
    include: { lead: true },
    orderBy: { createdAt: "desc" },
  });
}

// AD_SOLD is surfaced regardless of which actor (agent or coworker) marked
// the ad sold -- unlike AD_CREATED below, "an ad sold" is news worth telling
// the agent even when they did it themselves (mirrors SCREENS.md §4.4's own
// seed row, which carries no actor distinction).
export function findAdSoldEvents(prisma, agentId) {
  return prisma.activityEvent.findMany({
    where: { agentId, type: "AD_SOLD" },
    include: { ad: true },
    orderBy: { createdAt: "desc" },
  });
}

// AD_CREATED is only fetched for coworker-authored ads (coworkerId set) --
// see notificationService.js's header comment for why the agent's own
// AD_CREATED events are not surfaced as a separate "you created an ad"
// notification.
export function findCoworkerAdCreatedEvents(prisma, agentId) {
  return prisma.activityEvent.findMany({
    where: { agentId, type: "AD_CREATED", coworkerId: { not: null } },
    include: { ad: true, coworker: true },
    orderBy: { createdAt: "desc" },
  });
}

// AdPublication.adId is a plain string with no FK to Ad (see
// publishService.js's file-header comment), so there is no direct
// `where: { ad: { agentId } }` query available -- scoping to the caller's
// own publish outcomes means first collecting the id/title of every ad they
// own, then filtering AdPublication rows against that id set.
export function findAgentAds(prisma, agentId) {
  return prisma.ad.findMany({ where: { agentId }, select: { id: true, title: true } });
}

export function findPublicationsForAdIds(prisma, adIds) {
  if (!adIds.length) return Promise.resolve([]);
  return prisma.adPublication.findMany({
    where: { adId: { in: adIds }, status: { in: ["PUBLISHED", "FAILED"] } },
    orderBy: { updatedAt: "desc" },
  });
}
