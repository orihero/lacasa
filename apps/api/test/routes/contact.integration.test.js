import { afterEach, describe, expect, it, vi } from "vitest";
import supertest from "supertest";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { config } from "../../src/lib/config.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";

// POST /api/contact is public (no requireAuth) -- every test below omits the
// Authorization header on purpose, that IS the "doesn't require auth"
// coverage. The outbound Telegram call is faked via vi.stubGlobal("fetch",
// ...), same technique as publish.integration.test.js. The rate-limit test
// runs last and sends its own generous batch of requests rather than
// relying on how many the earlier functional tests already consumed --
// the limiter's bucket is a module-level singleton for the lifetime of this
// file (see lib/rateLimiter.js), shared by every test below.

const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

const ORIGINAL_TOKEN = config.TG_BOT_TOKEN;
const ORIGINAL_CONFIGURED = config.TG_CONFIGURED;
const ORIGINAL_CHAT_ID = config.TG_CONTACT_CHAT_ID;

afterEach(() => {
  config.TG_BOT_TOKEN = ORIGINAL_TOKEN;
  config.TG_CONFIGURED = ORIGINAL_CONFIGURED;
  config.TG_CONTACT_CHAT_ID = ORIGINAL_CHAT_ID;
  vi.unstubAllGlobals();
});

describe("POST /api/contact", () => {
  it("rejects a malformed phone number with 400 validation, no auth required", async () => {
    const res = await supertest(app).post("/api/contact").send({ name: "Aziz", phone: "not-a-phone", message: "hi" });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });

  it("503s with contact_unconfigured when TG_BOT_TOKEN or TG_CONTACT_CHAT_ID is unset", async () => {
    config.TG_BOT_TOKEN = undefined;
    config.TG_CONFIGURED = false;
    config.TG_CONTACT_CHAT_ID = undefined;

    const res = await supertest(app).post("/api/contact").send({ name: "Aziz", phone: "+998901234567", message: "hi" });
    expect(res.status).toBe(503);
    expect(res.body.error.code).toBe("contact_unconfigured");
  });

  it("relays to TG_CONTACT_CHAT_ID and answers 202 without echoing the caller's input back", async () => {
    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
    config.TG_CONTACT_CHAT_ID = "-1009999";
    const fetchMock = vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ ok: true, result: { message_id: 1 } }) });
    vi.stubGlobal("fetch", fetchMock);

    const res = await supertest(app).post("/api/contact").send({ name: "Aziz", phone: "+998901234567", message: "Call me" });

    expect(res.status).toBe(202);
    expect(res.body).toEqual({ ok: true });
    const [url] = fetchMock.mock.calls[0];
    expect(url).toContain("chat_id=-1009999");
    expect(decodeURIComponent(url)).toContain("Aziz");
  });

  it("502s with contact_relay_failed when the Telegram relay itself errors, and still doesn't echo input", async () => {
    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
    config.TG_CONTACT_CHAT_ID = "-1009999";
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: false, status: 400, json: async () => ({ ok: false, description: "chat not found" }) }),
    );

    const res = await supertest(app).post("/api/contact").send({ name: "Aziz", phone: "+998901234567", message: "hi" });

    expect(res.status).toBe(502);
    expect(res.body.error.code).toBe("contact_relay_failed");
    expect(JSON.stringify(res.body)).not.toContain("Aziz");
  });

  it("eventually answers 429 once the per-IP rate limit is exceeded", async () => {
    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
    config.TG_CONTACT_CHAT_ID = "-1009999";
    vi.stubGlobal("fetch", vi.fn().mockResolvedValue({ ok: true, status: 200, json: async () => ({ ok: true, result: { message_id: 1 } }) }));

    const responses = [];
    for (let i = 0; i < 10; i++) {
      // eslint-disable-next-line no-await-in-loop -- must serialize: the limiter is a shared, order-dependent bucket
      responses.push(await supertest(app).post("/api/contact").send({ name: "Aziz", phone: "+998901234567", message: `hi ${i}` }));
    }

    const last = responses[responses.length - 1];
    expect(last.status).toBe(429);
    expect(last.body.error.code).toBe("rate_limited");
    expect(last.headers["retry-after"]).toBeDefined();
    expect(responses.some((r) => r.status === 429)).toBe(true);
  });
});
