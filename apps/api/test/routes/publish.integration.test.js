import { afterEach, beforeAll, describe, expect, it, vi } from "vitest";
import supertest from "supertest";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { config } from "../../src/lib/config.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";
import { createUser, authHeader } from "../integration/helpers/factories.js";
import * as publishService from "../../src/services/publishService.js";
import { actorFields } from "../../src/middleware/roles.js";

// Covers the two new direct-publish/report-back routes added to publish.js
// (POST /telegram, POST /youtube) end to end: real Postgres via
// useIntegrationDb(), fake MinIO/LLM (unused by these routes but required by
// createApp's ctx seam, same as every other *.integration.test.js). The
// outbound Telegram HTTP call is faked via vi.stubGlobal("fetch", ...) --
// never hits the real Bot API -- and config.TG_BOT_TOKEN/TG_CONFIGURED are
// toggled directly on the shared config singleton for the duration of each
// test that needs a specific configured/unconfigured state (see
// test/lib/telegram.test.js for the same technique at the unit level).

const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

const ORIGINAL_TOKEN = config.TG_BOT_TOKEN;
const ORIGINAL_CONFIGURED = config.TG_CONFIGURED;

afterEach(() => {
  config.TG_BOT_TOKEN = ORIGINAL_TOKEN;
  config.TG_CONFIGURED = ORIGINAL_CONFIGURED;
  vi.unstubAllGlobals();
});

let agent, otherAgent;

beforeAll(async () => {
  agent = await createUser(prisma, { role: "AGENT", email: "publish-agent@example.test" });
  await prisma.user.update({ where: { id: agent.id }, data: { tgChatIds: [111n, 222n] } });
  agent = await prisma.user.findUnique({ where: { id: agent.id } });

  otherAgent = await createUser(prisma, { role: "AGENT", email: "publish-other-agent@example.test" });
});

async function createAd(owner, overrides = {}) {
  const res = await supertest(app)
    .post("/api/ads")
    .set("Authorization", authHeader(owner))
    .send({
      title: "Sunny flat",
      city: "Tashkent",
      district: "Yunusabad",
      type: "residential",
      category: "sale",
      price: 120000,
      ...overrides,
    });
  return res.body;
}

describe("POST /api/publish/telegram", () => {
  it("requires auth", async () => {
    const res = await supertest(app)
      .post("/api/publish/telegram")
      .send({ adId: "draft-1", caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["111"] });
    expect(res.status).toBe(401);
  });

  it("rejects a malformed body with 400 validation", async () => {
    const res = await supertest(app)
      .post("/api/publish/telegram")
      .set("Authorization", authHeader(agent))
      .send({ adId: "draft-1", caption: "c", imageUrls: [], chatIds: ["111"] });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });

  it("403s when the ad belongs to another agent", async () => {
    const ad = await createAd(otherAgent);
    const res = await supertest(app)
      .post("/api/publish/telegram")
      .set("Authorization", authHeader(agent))
      .send({ adId: ad.id, caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["111"] });
    expect(res.status).toBe(403);
  });

  it("400s when the requested chat id isn't on the caller's connected chats", async () => {
    const res = await supertest(app)
      .post("/api/publish/telegram")
      .set("Authorization", authHeader(agent))
      .send({ adId: "draft-tg-1", caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["999"] });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("no_connected_accounts");
  });

  it("503s with tg_unconfigured and still records a FAILED AdPublication when TG_BOT_TOKEN is unset", async () => {
    config.TG_BOT_TOKEN = undefined;
    config.TG_CONFIGURED = false;

    const res = await supertest(app)
      .post("/api/publish/telegram")
      .set("Authorization", authHeader(agent))
      .send({ adId: "draft-tg-2", caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["111"] });

    expect(res.status).toBe(503);
    expect(res.body.error.code).toBe("tg_unconfigured");

    const status = await supertest(app).get("/api/publish/ads/draft-tg-2/status").set("Authorization", authHeader(agent));
    const tg = status.body.channels.find((c) => c.channel === "TELEGRAM");
    expect(tg.status).toBe("FAILED");
  });

  it("resolves allowed chat ids from the agent's tgChatIds when a coworker publishes", async () => {
    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ ok: true, result: [{ message_id: 654 }] }) }),
    );
    const coworker = await createUser(prisma, {
      role: "COWORKER",
      agentId: agent.id,
      email: "publish-coworker@example.test",
    });

    const res = await supertest(app)
      .post("/api/publish/telegram")
      .set("Authorization", authHeader(coworker))
      .send({ adId: "draft-tg-coworker-1", caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["111"] });

    expect(res.status).toBe(200);
    expect(res.body.publication.status).toBe("PUBLISHED");
  });

  it("publishes on the happy path and shows up in the status grid", async () => {
    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ ok: true, result: [{ message_id: 321 }] }) }),
    );

    const res = await supertest(app)
      .post("/api/publish/telegram")
      .set("Authorization", authHeader(agent))
      .send({ adId: "draft-tg-3", caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["111", "222"] });

    expect(res.status).toBe(200);
    expect(res.body.publication.status).toBe("PUBLISHED");
    expect(res.body.publication.externalId).toBe("321");

    const status = await supertest(app).get("/api/publish/ads/draft-tg-3/status").set("Authorization", authHeader(agent));
    const tg = status.body.channels.find((c) => c.channel === "TELEGRAM");
    expect(tg.status).toBe("PUBLISHED");
  });

  it("records a FAILED publication (200 response) when the Telegram API itself errors", async () => {
    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: false, status: 403, json: async () => ({ ok: false, description: "bot was blocked" }) }),
    );

    const res = await supertest(app)
      .post("/api/publish/telegram")
      .set("Authorization", authHeader(agent))
      .send({ adId: "draft-tg-4", caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["111"] });

    expect(res.status).toBe(200);
    expect(res.body.publication.status).toBe("FAILED");
    expect(res.body.publication.errorMessage).toBe("bot was blocked");
  });
});

describe("POST /api/publish/youtube", () => {
  it("requires auth", async () => {
    const res = await supertest(app).post("/api/publish/youtube").send({ adId: "draft-1", status: "PUBLISHED", externalId: "dQw4w9WgXcQ" });
    expect(res.status).toBe(401);
  });

  it("rejects a PUBLISHED report with no externalId", async () => {
    const res = await supertest(app)
      .post("/api/publish/youtube")
      .set("Authorization", authHeader(agent))
      .send({ adId: "draft-yt-1", status: "PUBLISHED" });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });

  it("403s when reporting on another agent's ad (can't write an arbitrary status for someone else's ad)", async () => {
    const ad = await createAd(otherAgent);
    const res = await supertest(app)
      .post("/api/publish/youtube")
      .set("Authorization", authHeader(agent))
      .send({ adId: ad.id, status: "PUBLISHED", externalId: "dQw4w9WgXcQ" });
    expect(res.status).toBe(403);
  });

  it("records a PUBLISHED report and shows up in the status grid", async () => {
    const res = await supertest(app)
      .post("/api/publish/youtube")
      .set("Authorization", authHeader(agent))
      .send({ adId: "draft-yt-2", status: "PUBLISHED", externalId: "dQw4w9WgXcQ" });

    expect(res.status).toBe(200);
    expect(res.body.publication.status).toBe("PUBLISHED");
    expect(res.body.publication.externalUrl).toBe("https://www.youtube.com/watch?v=dQw4w9WgXcQ");

    const status = await supertest(app).get("/api/publish/ads/draft-yt-2/status").set("Authorization", authHeader(agent));
    const yt = status.body.channels.find((c) => c.channel === "YOUTUBE");
    expect(yt.status).toBe("PUBLISHED");
  });

  it("records a FAILED report with the reported errorMessage", async () => {
    const res = await supertest(app)
      .post("/api/publish/youtube")
      .set("Authorization", authHeader(agent))
      .send({ adId: "draft-yt-3", status: "FAILED", errorMessage: "quota exceeded" });

    expect(res.status).toBe(200);
    expect(res.body.publication.status).toBe("FAILED");
    expect(res.body.publication.errorMessage).toBe("quota exceeded");
  });
});

// Retry endpoint: the whole difficulty is not double-posting, so most of
// these tests are about the status/ownership/concurrency gates rather than
// the happy path itself (already covered end-to-end by the telegram happy
// path above, which retry reuses verbatim).
describe("POST /api/publish/ads/:adId/:channel/retry", () => {
  it("requires auth", async () => {
    const res = await supertest(app).post("/api/publish/ads/draft-1/telegram/retry");
    expect(res.status).toBe(401);
  });

  it("404s unknown_channel for a channel that isn't a real PublishChannel", async () => {
    const res = await supertest(app)
      .post("/api/publish/ads/draft-1/not-a-channel/retry")
      .set("Authorization", authHeader(agent));
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe("unknown_channel");
  });

  it("400s not_retryable for youtube, olx, and realting, each naming why", async () => {
    for (const channel of ["youtube", "olx", "realting"]) {
      const res = await supertest(app)
        .post(`/api/publish/ads/draft-1/${channel}/retry`)
        .set("Authorization", authHeader(agent));
      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("not_retryable");
      expect(res.body.error.message.length).toBeGreaterThan(0);
    }
  });

  it("403s when the ad belongs to another agent", async () => {
    const ad = await createAd(otherAgent);
    const res = await supertest(app)
      .post(`/api/publish/ads/${ad.id}/telegram/retry`)
      .set("Authorization", authHeader(agent));
    expect(res.status).toBe(403);
  });

  it("400s not_failed when the channel has never been attempted", async () => {
    const res = await supertest(app)
      .post("/api/publish/ads/draft-retry-never/telegram/retry")
      .set("Authorization", authHeader(agent));
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("not_failed");
  });

  it("409s already_published -- retrying a live post is refused, not silently re-sent", async () => {
    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ ok: true, result: [{ message_id: 1 }] }) }),
    );
    const adId = "draft-retry-published";
    await supertest(app)
      .post("/api/publish/telegram")
      .set("Authorization", authHeader(agent))
      .send({ adId, caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["111"] });

    const res = await supertest(app).post(`/api/publish/ads/${adId}/telegram/retry`).set("Authorization", authHeader(agent));
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe("already_published");
  });

  it("409s awaiting_review for DRAFTED_AWAITING_REVIEW -- a human may already be mid-flight", async () => {
    const adId = "draft-retry-drafted";
    await supertest(app)
      .post("/api/publish/instagram/confirm")
      .set("Authorization", authHeader(agent))
      .send({ adId, event: "drafted" });

    const res = await supertest(app).post(`/api/publish/ads/${adId}/instagram/retry`).set("Authorization", authHeader(agent));
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe("awaiting_review");
  });

  it("409s retry_unavailable for a FAILED row that predates retry support (no stored request to replay)", async () => {
    config.TG_BOT_TOKEN = undefined;
    config.TG_CONFIGURED = false;
    const adId = "draft-retry-legacy";
    await supertest(app)
      .post("/api/publish/telegram")
      .set("Authorization", authHeader(agent))
      .send({ adId, caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["111"] });

    // Simulate a row written before payload.request existed by stripping it
    // directly -- there is no API surface that produces this shape anymore.
    await prisma.adPublication.update({
      where: { adId_channel: { adId, channel: "TELEGRAM" } },
      data: { payload: { mechanism: "bot-api" } },
    });

    const res = await supertest(app).post(`/api/publish/ads/${adId}/telegram/retry`).set("Authorization", authHeader(agent));
    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe("retry_unavailable");
  });

  it("retries successfully: attempts increments, status lands PUBLISHED, externalId is the new message id", async () => {
    // First attempt fails (bot unconfigured) but still records the request.
    config.TG_BOT_TOKEN = undefined;
    config.TG_CONFIGURED = false;
    const adId = "draft-retry-success";
    await supertest(app)
      .post("/api/publish/telegram")
      .set("Authorization", authHeader(agent))
      .send({ adId, caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["111"] });

    // Now the token is configured -- the retry should succeed by replaying
    // the exact stored caption/imageUrls/chatIds, with no body of its own.
    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ ok: true, result: [{ message_id: 4242 }] }) }),
    );

    const res = await supertest(app).post(`/api/publish/ads/${adId}/telegram/retry`).set("Authorization", authHeader(agent));

    expect(res.status).toBe(200);
    expect(res.body.publication.status).toBe("PUBLISHED");
    expect(res.body.publication.externalId).toBe("4242");
    // attempts: 1 (first, failed) + 1 (this retry) = 2 -- proves the claim
    // step itself did not also increment (that would read 3).
    expect(res.body.publication.attempts).toBe(2);

    const status = await supertest(app).get(`/api/publish/ads/${adId}/status`).set("Authorization", authHeader(agent));
    const tg = status.body.channels.find((c) => c.channel === "TELEGRAM");
    expect(tg.status).toBe("PUBLISHED");
  });

  it("under two concurrent retries against the same FAILED row, exactly one succeeds and the other 409s retry_in_progress", async () => {
    config.TG_BOT_TOKEN = undefined;
    config.TG_CONFIGURED = false;
    const adId = "draft-retry-race";
    await supertest(app)
      .post("/api/publish/telegram")
      .set("Authorization", authHeader(agent))
      .send({ adId, caption: "c", imageUrls: ["https://x/1.jpg"], chatIds: ["111"] });

    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ ok: true, result: [{ message_id: 5050 }] }) }),
    );

    // Driven at the service layer, not over HTTP: two real supertest
    // requests each spin up their own ephemeral listener, and the TCP
    // handshake overhead was enough in practice for the first request to
    // finish end-to-end before the second's claim step ever ran -- the two
    // calls never actually landed their UPDATEs at the same time, so the
    // race this test exists to exercise never happened. Calling
    // retryPublish directly against the same real Postgres connection pool
    // starts both promises in the same event-loop turn, so their `await`s
    // genuinely interleave and the conditional UPDATE's row lock is what's
    // actually under test, not incidental request scheduling.
    const actor = actorFields(agent);
    const [first, second] = await Promise.allSettled([
      publishService.retryPublish({ prisma }, { adId, channelKey: "telegram", actor }),
      publishService.retryPublish({ prisma }, { adId, channelKey: "telegram", actor }),
    ]);

    const outcomes = [first, second];
    expect(outcomes.filter((o) => o.status === "fulfilled")).toHaveLength(1);
    const loser = outcomes.find((o) => o.status === "rejected");
    expect(loser.reason).toMatchObject({ status: 409, code: "retry_in_progress" });

    // Exactly one retry actually landed -- attempts is 2 (initial fail +
    // the one winning retry), not 3.
    const final = await prisma.adPublication.findUnique({ where: { adId_channel: { adId, channel: "TELEGRAM" } } });
    expect(final.attempts).toBe(2);
    expect(final.status).toBe("PUBLISHED");
  });
});
