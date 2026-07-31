import { describe, expect, it, vi } from "vitest";
import { ALL_CHANNELS, CONFIRM_EVENTS, confirmSchema } from "@lacasa/domain";
import { createFakeLlm, createFakePrisma } from "../helpers/testApp.js";
import * as publishService from "../../src/services/publishService.js";

function makeActor(overrides = {}) {
  return {
    user: { id: "user-1", igAssistConsentAt: new Date("2026-01-01T00:00:00Z"), ...overrides.user },
    agentId: "agent-1",
    coworkerId: null,
    ...overrides,
  };
}

// -----------------------------------------------------------------------
// Drift contract: publishService's CHANNELS map and the domain package's
// exported channel/event vocabulary must never disagree — a typo in either
// would either create publications the status grid never renders, or
// silently start accepting/rejecting different confirm events than the
// extension (which imports the same @lacasa/domain package) sends.

describe("drift contract with @lacasa/domain", () => {
  it("every CHANNELS[...].enum is a real @lacasa/domain PublishChannel value", () => {
    for (const channel of Object.values(publishService.CHANNELS)) {
      expect(ALL_CHANNELS).toContain(channel.enum);
    }
  });

  it("confirmSchema's accepted `event` values equal @lacasa/domain's CONFIRM_EVENTS", () => {
    for (const event of CONFIRM_EVENTS) {
      expect(confirmSchema.safeParse({ adId: "a", event }).success).toBe(true);
    }
    expect(confirmSchema.safeParse({ adId: "a", event: "not-a-real-event" }).success).toBe(false);
  });
});

describe("statusGrid", () => {
  it("returns every @lacasa/domain channel in ALL_CHANNELS order, PENDING when no row exists", () => {
    const grid = publishService.statusGrid("ad-1", []);
    expect(grid.map((c) => c.channel)).toEqual(ALL_CHANNELS);
    expect(grid.every((c) => c.status === "PENDING")).toBe(true);
  });

  it("fills in the real row for a channel that has one", () => {
    const rows = [{ adId: "ad-1", channel: "OLX", status: "PUBLISHED", externalUrl: "https://olx.uz/x", externalId: "123", lastAttemptAt: null, errorMessage: null }];
    const grid = publishService.statusGrid("ad-1", rows);
    const olx = grid.find((c) => c.channel === "OLX");
    expect(olx).toMatchObject({ status: "PUBLISHED", externalUrl: "https://olx.uz/x", externalId: "123" });
  });
});

describe("mapFieldsForChannel", () => {
  it("throws a 404 httpError for an unknown channel", async () => {
    const ctx = { prisma: createFakePrisma(), llm: createFakeLlm() };
    await expect(
      publishService.mapFieldsForChannel(ctx, "not-a-channel", { adId: "a", ad: {}, step: "x", snapshot: [{}], actor: makeActor() }),
    ).rejects.toMatchObject({ status: 404, code: "unknown_channel" });
  });

  it("throws 403 consent_required for instagram when the actor hasn't opted in", async () => {
    const ctx = { prisma: createFakePrisma(), llm: createFakeLlm() };
    const actor = makeActor({ user: { id: "user-1", igAssistConsentAt: null } });
    await expect(
      publishService.mapFieldsForChannel(ctx, "instagram", { adId: "a", ad: {}, step: "caption", snapshot: [{}], actor }),
    ).rejects.toMatchObject({ status: 403, code: "consent_required" });
  });

  it("throws 503 llm_unconfigured before touching the daily-cap accounting", async () => {
    const count = vi.fn();
    const ctx = { prisma: createFakePrisma({ activityEvent: { count } }), llm: createFakeLlm({ configured: false }) };
    await expect(
      publishService.mapFieldsForChannel(ctx, "olx", { adId: "a", ad: {}, step: "category", snapshot: [{}], actor: makeActor() }),
    ).rejects.toMatchObject({ status: 503, code: "llm_unconfigured" });
    expect(count).not.toHaveBeenCalled();
  });

  it("throws 429 daily_cap once the agent has hit today's session-start count", async () => {
    const ctx = {
      prisma: createFakePrisma({ activityEvent: { count: vi.fn().mockResolvedValue(publishService.CHANNELS.olx.dailyCap) } }),
      llm: createFakeLlm(),
    };
    await expect(
      publishService.mapFieldsForChannel(ctx, "olx", { adId: "a", ad: {}, step: "category", snapshot: [{}], actor: makeActor() }),
    ).rejects.toMatchObject({ status: 429, code: "daily_cap" });
  });

  it("logs the session-start event only on the channel's sessionStartStep, not on other steps", async () => {
    const activityCreate = vi.fn().mockResolvedValue({});
    const upsert = vi.fn().mockResolvedValue({ id: "p1" });
    const ctx = {
      prisma: createFakePrisma({
        activityEvent: { count: vi.fn().mockResolvedValue(0), create: activityCreate },
        adPublication: { upsert },
      }),
      llm: createFakeLlm(),
    };

    await publishService.mapFieldsForChannel(ctx, "olx", { adId: "a", ad: {}, step: "some-other-step", snapshot: [{}], actor: makeActor() });
    expect(activityCreate).not.toHaveBeenCalled();

    await publishService.mapFieldsForChannel(ctx, "olx", { adId: "a", ad: {}, step: "category", snapshot: [{}], actor: makeActor() });
    expect(activityCreate).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ type: "OLX_CROSSPOST_STARTED" }) }),
    );
  });

  it("maps an llm_refusal error from ctx.llm.mapFields to a 502 httpError", async () => {
    const err = new Error("declined");
    err.code = "llm_refusal";
    const ctx = {
      prisma: createFakePrisma({ activityEvent: { count: vi.fn().mockResolvedValue(0), create: vi.fn().mockResolvedValue({}) } }),
      llm: createFakeLlm({ mapFields: vi.fn().mockRejectedValue(err) }),
    };
    await expect(
      publishService.mapFieldsForChannel(ctx, "olx", { adId: "a", ad: {}, step: "category", snapshot: [{}], actor: makeActor() }),
    ).rejects.toMatchObject({ status: 502, code: "llm_refusal" });
  });
});

describe("confirmChannelEvent", () => {
  it("throws a 404 httpError for an unknown channel", async () => {
    const ctx = { prisma: createFakePrisma() };
    await expect(
      publishService.confirmChannelEvent(ctx, "not-a-channel", { adId: "a", event: "drafted", actor: makeActor() }),
    ).rejects.toMatchObject({ status: 404, code: "unknown_channel" });
  });

  it("logs the completeEvent activity only when event is 'published'", async () => {
    const activityCreate = vi.fn().mockResolvedValue({});
    const ctx = {
      prisma: createFakePrisma({
        adPublication: { upsert: vi.fn().mockResolvedValue({ id: "p1" }) },
        activityEvent: { create: activityCreate },
      }),
    };

    await publishService.confirmChannelEvent(ctx, "olx", { adId: "a", event: "published", externalId: "e1", actor: makeActor() });
    expect(activityCreate).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ type: "OLX_CROSSPOST_COMPLETED" }) }),
    );

    activityCreate.mockClear();
    await publishService.confirmChannelEvent(ctx, "olx", { adId: "a", event: "drafted", actor: makeActor() });
    expect(activityCreate).not.toHaveBeenCalled();
  });

  it("logs the abortEvent activity when event is 'aborted'", async () => {
    const activityCreate = vi.fn().mockResolvedValue({});
    const ctx = {
      prisma: createFakePrisma({
        adPublication: { upsert: vi.fn().mockResolvedValue({ id: "p1" }) },
        activityEvent: { create: activityCreate },
      }),
    };

    await publishService.confirmChannelEvent(ctx, "instagram", { adId: "a", event: "aborted", errorMessage: "dom drift", actor: makeActor() });
    expect(activityCreate).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ type: "IG_ASSIST_ABORTED" }) }),
    );
  });
});

describe("reassignDraft", () => {
  it("throws a 400 httpError when fromAdId doesn't look like a draft id", async () => {
    const ctx = { prisma: createFakePrisma() };
    await expect(
      publishService.reassignDraft(ctx, { fromAdId: "ad-1", toAdId: "ad-2", actor: makeActor() }),
    ).rejects.toMatchObject({ status: 400, code: "not_a_draft" });
  });

  it("moves every matching row from the draft id to the real ad id via a transaction, then deletes the draft rows", async () => {
    const rows = [
      { id: "pub-1", channel: "OLX", status: "PUBLISHED", externalId: null, externalUrl: null, payload: {}, attempts: 1, lastAttemptAt: null, publishedAt: null, errorMessage: null, requestedById: "user-1" },
    ];
    const upsert = vi.fn().mockResolvedValue({});
    const del = vi.fn().mockResolvedValue({});
    const ctx = {
      prisma: createFakePrisma({
        adPublication: { findMany: vi.fn().mockResolvedValue(rows), upsert, delete: del },
      }),
    };

    const moved = await publishService.reassignDraft(ctx, { fromAdId: "draft-abc", toAdId: "ad-real", actor: makeActor() });

    expect(moved).toBe(1);
    expect(upsert).toHaveBeenCalledWith(
      expect.objectContaining({ where: { adId_channel: { adId: "ad-real", channel: "OLX" } } }),
    );
    expect(del).toHaveBeenCalledWith({ where: { id: "pub-1" } });
  });
});

describe("getAdStatus / getStatusBulk", () => {
  it("getAdStatus builds a full channel grid for a single ad", async () => {
    const ctx = { prisma: createFakePrisma({ adPublication: { findMany: vi.fn().mockResolvedValue([]) } }) };
    const result = await publishService.getAdStatus(ctx, "ad-1");
    expect(result.adId).toBe("ad-1");
    expect(result.channels).toHaveLength(ALL_CHANNELS.length);
  });

  it("getStatusBulk returns {} for an empty adIds list without querying", async () => {
    const findMany = vi.fn();
    const ctx = { prisma: createFakePrisma({ adPublication: { findMany } }) };
    expect(await publishService.getStatusBulk(ctx, [])).toEqual({});
    expect(findMany).not.toHaveBeenCalled();
  });

  it("getStatusBulk groups rows per adId", async () => {
    const rows = [{ adId: "ad-1", channel: "OLX", status: "PUBLISHED" }];
    const ctx = { prisma: createFakePrisma({ adPublication: { findMany: vi.fn().mockResolvedValue(rows) } }) };
    const result = await publishService.getStatusBulk(ctx, ["ad-1", "ad-2"]);
    expect(result["ad-1"]).toEqual([{ channel: "OLX", status: "PUBLISHED" }]);
    expect(result["ad-2"]).toEqual([]);
  });
});
