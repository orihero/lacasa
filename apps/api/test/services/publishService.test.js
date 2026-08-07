import { afterEach, describe, expect, it, vi } from "vitest";
import { ALL_CHANNELS, CONFIRM_EVENTS, confirmSchema } from "@lacasa/domain";
import { createFakeLlm, createFakePrisma } from "../helpers/testApp.js";
import { config } from "../../src/lib/config.js";
import * as publishService from "../../src/services/publishService.js";

function makeActor(overrides = {}) {
  return {
    user: { id: "user-1", igAssistConsentAt: new Date("2026-01-01T00:00:00Z"), tgChatIds: [], ...overrides.user },
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

describe("publishTelegramDirect", () => {
  const ORIGINAL_TOKEN = config.TG_BOT_TOKEN;
  const ORIGINAL_CONFIGURED = config.TG_CONFIGURED;

  afterEach(() => {
    config.TG_BOT_TOKEN = ORIGINAL_TOKEN;
    config.TG_CONFIGURED = ORIGINAL_CONFIGURED;
    vi.unstubAllGlobals();
  });

  it("throws 404 ad_not_found for a real (non-draft) adId that doesn't exist", async () => {
    const ctx = { prisma: createFakePrisma({ ad: { findUnique: vi.fn().mockResolvedValue(null) } }) };
    await expect(
      publishService.publishTelegramDirect(ctx, { adId: "ad-missing", caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["1"], actor: makeActor() }),
    ).rejects.toMatchObject({ status: 404, code: "ad_not_found" });
  });

  it("throws 403 forbidden when the ad belongs to a different agent", async () => {
    const ctx = { prisma: createFakePrisma({ ad: { findUnique: vi.fn().mockResolvedValue({ agentId: "someone-else" }) } }) };
    await expect(
      publishService.publishTelegramDirect(ctx, { adId: "ad-1", caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["1"], actor: makeActor() }),
    ).rejects.toMatchObject({ status: 403, code: "forbidden" });
  });

  it("skips the ownership check entirely for a draft- adId", async () => {
    const findUnique = vi.fn();
    const ctx = {
      prisma: createFakePrisma({
        ad: { findUnique },
        adPublication: { upsert: vi.fn().mockResolvedValue({ id: "p1" }) },
      }),
    };
    // No connected chat ids -> rejects before any network call, but proves
    // ad.findUnique was never consulted for a draft id.
    await expect(
      publishService.publishTelegramDirect(ctx, { adId: "draft-abc", caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["1"], actor: makeActor() }),
    ).rejects.toMatchObject({ status: 400, code: "no_connected_accounts" });
    expect(findUnique).not.toHaveBeenCalled();
  });

  it("throws 400 no_connected_accounts when none of the requested chatIds are on the actor's User.tgChatIds", async () => {
    const ctx = { prisma: createFakePrisma() };
    const actor = makeActor({ user: { tgChatIds: [111n] } });
    await expect(
      publishService.publishTelegramDirect(ctx, { adId: "draft-1", caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["999"], actor }),
    ).rejects.toMatchObject({ status: 400, code: "no_connected_accounts" });
  });

  it("resolves allowed chat ids from the AGENT's tgChatIds, not the calling coworker's own row", async () => {
    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ ok: true, result: [{ message_id: 555 }] }) }),
    );
    const findUnique = vi.fn().mockResolvedValue({ tgChatIds: [111n] });
    const upsert = vi.fn().mockResolvedValue({ id: "p1" });
    const ctx = { prisma: createFakePrisma({ user: { findUnique }, adPublication: { upsert } }) };
    // A COWORKER's own User row never has tgChatIds set -- only the agent
    // who connected Telegram does (auth.js's resolveAgentContext). If this
    // read the caller's own row instead of the agent's, `allowed` would be
    // empty and this would 400 no_connected_accounts.
    const actor = makeActor({ user: { id: "coworker-1", tgChatIds: [] }, agentId: "agent-1", coworkerId: "coworker-1" });

    const result = await publishService.publishTelegramDirect(ctx, {
      adId: "draft-coworker-1",
      caption: "c",
      imageUrls: ["https://x/1.jpg"],
      chatIds: ["111"],
      actor,
    });

    expect(findUnique).toHaveBeenCalledWith({ where: { id: "agent-1" }, select: { tgChatIds: true } });
    expect(result.results).toEqual([{ chatId: "111", ok: true, messageId: 555 }]);
  });

  it("records a FAILED AdPublication and throws 503 tg_unconfigured when TG_BOT_TOKEN is unset", async () => {
    config.TG_BOT_TOKEN = undefined;
    config.TG_CONFIGURED = false;
    const upsert = vi.fn().mockResolvedValue({ id: "p1" });
    const ctx = { prisma: createFakePrisma({ adPublication: { upsert } }) };
    const actor = makeActor({ user: { tgChatIds: [111n] } });

    await expect(
      publishService.publishTelegramDirect(ctx, { adId: "draft-1", caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["111"], actor }),
    ).rejects.toMatchObject({ status: 503, code: "tg_unconfigured" });

    expect(upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { adId_channel: { adId: "draft-1", channel: "TELEGRAM" } },
        create: expect.objectContaining({ status: "FAILED" }),
      }),
    );
  });

  it("publishes to every connected chat id and upserts a PUBLISHED AdPublication on the happy path", async () => {
    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ ok: true, result: [{ message_id: 777 }] }) }),
    );
    const upsert = vi.fn().mockResolvedValue({ id: "p1" });
    const ctx = { prisma: createFakePrisma({ adPublication: { upsert } }) };
    const actor = makeActor({ user: { tgChatIds: [111n] } });

    const result = await publishService.publishTelegramDirect(ctx, {
      adId: "draft-1",
      caption: "c",
      imageUrls: ["https://x/1.jpg"],
      chatIds: ["111"],
      actor,
    });

    expect(result.results).toEqual([{ chatId: "111", ok: true, messageId: 777 }]);
    expect(upsert).toHaveBeenCalledWith(
      expect.objectContaining({ create: expect.objectContaining({ status: "PUBLISHED", externalId: "777" }) }),
    );
  });

  it("upserts a FAILED AdPublication when the Telegram API rejects the send", async () => {
    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: false, status: 403, json: async () => ({ ok: false, description: "bot was blocked" }) }),
    );
    const upsert = vi.fn().mockResolvedValue({ id: "p1" });
    const ctx = { prisma: createFakePrisma({ adPublication: { upsert } }) };
    const actor = makeActor({ user: { tgChatIds: [111n] } });

    const result = await publishService.publishTelegramDirect(ctx, {
      adId: "draft-1",
      caption: "c",
      imageUrls: ["https://x/1.jpg"],
      chatIds: ["111"],
      actor,
    });

    expect(result.results).toEqual([{ chatId: "111", ok: false, error: "bot was blocked" }]);
    expect(upsert).toHaveBeenCalledWith(
      expect.objectContaining({ create: expect.objectContaining({ status: "FAILED", errorMessage: "bot was blocked" }) }),
    );
  });
});

describe("reportYoutubeStatus", () => {
  it("throws 403 forbidden when the ad belongs to a different agent (can't report someone else's ad)", async () => {
    const ctx = { prisma: createFakePrisma({ ad: { findUnique: vi.fn().mockResolvedValue({ agentId: "someone-else" }) } }) };
    await expect(
      publishService.reportYoutubeStatus(ctx, { adId: "ad-1", status: "PUBLISHED", externalId: "dQw4w9WgXcQ", actor: makeActor() }),
    ).rejects.toMatchObject({ status: 403, code: "forbidden" });
  });

  it("upserts a PUBLISHED AdPublication and derives externalUrl from externalId when none was sent", async () => {
    const upsert = vi.fn().mockResolvedValue({ id: "p1" });
    const ctx = { prisma: createFakePrisma({ adPublication: { upsert } }) };

    await publishService.reportYoutubeStatus(ctx, { adId: "draft-1", status: "PUBLISHED", externalId: "dQw4w9WgXcQ", actor: makeActor() });

    expect(upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        where: { adId_channel: { adId: "draft-1", channel: "YOUTUBE" } },
        create: expect.objectContaining({
          status: "PUBLISHED",
          externalId: "dQw4w9WgXcQ",
          externalUrl: "https://www.youtube.com/watch?v=dQw4w9WgXcQ",
        }),
      }),
    );
  });

  it("upserts a FAILED AdPublication carrying the reported errorMessage", async () => {
    const upsert = vi.fn().mockResolvedValue({ id: "p1" });
    const ctx = { prisma: createFakePrisma({ adPublication: { upsert } }) };

    await publishService.reportYoutubeStatus(ctx, { adId: "draft-1", status: "FAILED", errorMessage: "quota exceeded", actor: makeActor() });

    expect(upsert).toHaveBeenCalledWith(
      expect.objectContaining({
        create: expect.objectContaining({ status: "FAILED", errorMessage: "quota exceeded", externalId: null }),
      }),
    );
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
