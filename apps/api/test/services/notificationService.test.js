import { describe, expect, it, vi } from "vitest";
import { createFakePrisma } from "../helpers/testApp.js";
import { listNotifications, DEFAULT_LIMIT } from "../../src/services/notificationService.js";

// Builds a fake ctx.prisma whose activityEvent/ad/adPublication.findMany
// calls branch on the `where` clause the same way the real repository's
// four distinct queries do -- this is what lets one fake stand in for all
// four notificationRepository.js calls listNotifications makes.
function buildPrisma({ leadEvents = [], soldEvents = [], coworkerEvents = [], agentAds = [], publications = [] } = {}) {
  const activityFindMany = vi.fn(async ({ where }) => {
    if (where.type?.in?.includes("LEAD_CREATED")) return leadEvents;
    if (where.type === "AD_SOLD") return soldEvents;
    if (where.type === "AD_CREATED") return coworkerEvents;
    throw new Error(`unexpected activityEvent.findMany where: ${JSON.stringify(where)}`);
  });
  const adFindMany = vi.fn(async () => agentAds);
  const publicationFindMany = vi.fn(async () => publications);

  return createFakePrisma({
    activityEvent: { findMany: activityFindMany },
    ad: { findMany: adFindMany },
    adPublication: { findMany: publicationFindMany },
  });
}

function leadEvent(overrides = {}) {
  return {
    id: "event-lead-1",
    type: "LEAD_CREATED",
    agentId: "agent-1",
    coworkerId: null,
    leadId: "lead-1",
    lead: { id: "lead-1", fullName: "Jane Buyer", status: "NEW" },
    createdAt: new Date("2026-08-10T10:00:00Z"),
    ...overrides,
  };
}

function soldEvent(overrides = {}) {
  return {
    id: "event-sold-1",
    type: "AD_SOLD",
    agentId: "agent-1",
    coworkerId: null,
    adId: "ad-1",
    ad: { id: "ad-1", title: "Two-room flat in Mirobod" },
    createdAt: new Date("2026-08-09T10:00:00Z"),
    ...overrides,
  };
}

function coworkerAdEvent(overrides = {}) {
  return {
    id: "event-coworker-1",
    type: "AD_CREATED",
    agentId: "agent-1",
    coworkerId: "coworker-1",
    adId: "ad-2",
    ad: { id: "ad-2", title: "Retail space near Chorsu bazaar" },
    coworker: { id: "coworker-1", fullName: "Sardor Abdullayev" },
    createdAt: new Date("2026-08-08T10:00:00Z"),
    ...overrides,
  };
}

function publicationRow(overrides = {}) {
  return {
    adId: "ad-3",
    channel: "INSTAGRAM",
    status: "PUBLISHED",
    lastAttemptAt: new Date("2026-08-07T10:00:00Z"),
    updatedAt: new Date("2026-08-07T10:00:00Z"),
    ...overrides,
  };
}

describe("listNotifications", () => {
  it("derives one notification per source row, newest first", async () => {
    const prisma = buildPrisma({
      leadEvents: [leadEvent()],
      soldEvents: [soldEvent()],
      coworkerEvents: [coworkerAdEvent()],
      agentAds: [{ id: "ad-3", title: "Bright 3-room apartment in Chilonzor" }],
      publications: [publicationRow()],
    });

    const result = await listNotifications({ prisma }, { agentId: "agent-1" });

    expect(result).toHaveLength(4);
    expect(result.map((n) => n.kind)).toEqual(["lead", "sold", "coworkerActivity", "publish"]);
    // Newest-first: the lead event (Aug 10) sorts ahead of sold (Aug 9),
    // which sorts ahead of coworker (Aug 8), which sorts ahead of publish
    // (Aug 7).
    expect(result[0].title).toContain("Jane Buyer");
    expect(result[3].title).toContain("Instagram post published");
  });

  it("produces a deterministic id for the same underlying row across two calls", async () => {
    const prisma = buildPrisma({ leadEvents: [leadEvent()], soldEvents: [soldEvent()] });

    const first = await listNotifications({ prisma }, { agentId: "agent-1" });
    const second = await listNotifications({ prisma }, { agentId: "agent-1" });

    expect(first.map((n) => n.id)).toEqual(second.map((n) => n.id));
    expect(first[0].id).toBe("lead:lead-1:event-lead-1");
    expect(first[1].id).toBe("sold:ad-1:event-sold-1");
  });

  it("changes the publish notification's id when a retry changes lastAttemptAt, but not otherwise", async () => {
    // findPublicationsForAdIds short-circuits to [] when there is no ad to
    // scope the query to (see notificationRepository.js) -- agentAds must be
    // non-empty for the publish source to run at all.
    const agentAds = [{ id: "ad-3", title: "Bright 3-room apartment in Chilonzor" }];
    const unchanged = buildPrisma({ agentAds, publications: [publicationRow()] });
    const a = await listNotifications({ prisma: unchanged }, { agentId: "agent-1" });
    const b = await listNotifications({ prisma: unchanged }, { agentId: "agent-1" });
    expect(a[0].id).toBe(b[0].id);

    const retried = buildPrisma({
      agentAds,
      publications: [publicationRow({ status: "FAILED", lastAttemptAt: new Date("2026-08-07T11:00:00Z") })],
    });
    const c = await listNotifications({ prisma: retried }, { agentId: "agent-1" });
    expect(c[0].id).not.toBe(a[0].id);
  });

  it("scopes every query to the requested agentId", async () => {
    const prisma = buildPrisma({ leadEvents: [leadEvent()] });
    await listNotifications({ prisma }, { agentId: "agent-1" });

    expect(prisma.activityEvent.findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: expect.objectContaining({ agentId: "agent-1" }) }),
    );
    expect(prisma.ad.findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { agentId: "agent-1" } }));
  });

  it("gates AD_CREATED coworker events on coworkerId at the repository query, not in service code", async () => {
    const prisma = buildPrisma({ coworkerEvents: [coworkerAdEvent()] });
    await listNotifications({ prisma }, { agentId: "agent-1" });

    const coworkerCall = prisma.activityEvent.findMany.mock.calls.find((c) => c[0].where.type === "AD_CREATED");
    expect(coworkerCall[0].where.coworkerId).toEqual({ not: null });
  });

  it("drops a lead/sold/coworker event whose joined row was deleted (SetNull), rather than fabricating a title", async () => {
    const prisma = buildPrisma({
      leadEvents: [leadEvent({ lead: null })],
      soldEvents: [soldEvent({ ad: null })],
      coworkerEvents: [coworkerAdEvent({ ad: null })],
    });

    const result = await listNotifications({ prisma }, { agentId: "agent-1" });
    expect(result).toEqual([]);
  });

  it("computes unread against a since boundary, and defaults to unread with no boundary", async () => {
    const prisma = buildPrisma({ leadEvents: [leadEvent({ createdAt: new Date("2026-08-10T10:00:00Z") })] });

    const noSince = await listNotifications({ prisma }, { agentId: "agent-1" });
    expect(noSince[0].unread).toBe(true);

    const before = await listNotifications({ prisma }, { agentId: "agent-1", since: new Date("2026-08-10T09:00:00Z") });
    expect(before[0].unread).toBe(true);

    const after = await listNotifications({ prisma }, { agentId: "agent-1", since: new Date("2026-08-10T11:00:00Z") });
    expect(after[0].unread).toBe(false);
  });

  it("caps the result at the requested limit, keeping the newest rows", async () => {
    const many = Array.from({ length: 5 }, (_, i) =>
      leadEvent({
        id: `event-lead-${i}`,
        leadId: `lead-${i}`,
        lead: { id: `lead-${i}`, fullName: `Buyer ${i}`, status: "NEW" },
        createdAt: new Date(Date.UTC(2026, 7, 10, i)),
      }),
    );
    const prisma = buildPrisma({ leadEvents: many });

    const result = await listNotifications({ prisma }, { agentId: "agent-1", limit: 2 });
    expect(result).toHaveLength(2);
    // Newest first -> the two highest hour offsets (4, 3) survive the cap.
    expect(result[0].title).toContain("Buyer 4");
    expect(result[1].title).toContain("Buyer 3");
  });

  it("defaults the limit to DEFAULT_LIMIT when none is given", async () => {
    const many = Array.from({ length: DEFAULT_LIMIT + 5 }, (_, i) =>
      leadEvent({ id: `event-lead-${i}`, leadId: `lead-${i}`, lead: { id: `lead-${i}`, fullName: `Buyer ${i}`, status: "NEW" } }),
    );
    const prisma = buildPrisma({ leadEvents: many });

    const result = await listNotifications({ prisma }, { agentId: "agent-1" });
    expect(result).toHaveLength(DEFAULT_LIMIT);
  });
});
