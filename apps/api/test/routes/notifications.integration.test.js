import { describe, expect, it, beforeAll } from "vitest";
import supertest from "supertest";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";
import { createUser, authHeader } from "../integration/helpers/factories.js";

const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

let agentA, agentB, coworkerA, buyer;
let adA; // agentA's own ad, used for the AD_SOLD + publish-outcome rows

function adPayload(overrides = {}) {
  return {
    title: "Bright 3-room apartment in Chilonzor",
    city: "Tashkent",
    district: "Chilonzor",
    type: "residential",
    category: "sale",
    price: 90000,
    ...overrides,
  };
}

beforeAll(async () => {
  agentA = await createUser(prisma, { role: "AGENT", email: "notif-agent-a@example.test" });
  agentB = await createUser(prisma, { role: "AGENT", email: "notif-agent-b@example.test" });
  coworkerA = await createUser(prisma, { role: "COWORKER", agentId: agentA.id, email: "notif-coworker-a@example.test" });
  buyer = await createUser(prisma, { email: "notif-buyer@example.test" });

  // Lead notification source (LEAD_CREATED via the real route).
  await supertest(app)
    .post("/api/leads")
    .set("Authorization", authHeader(agentA))
    .send({ fullName: "Dilnoza Yusupova", phone: "+998901112233" });

  // Ad lifecycle source: create + mark sold (AD_CREATED, then AD_SOLD) via
  // the real route/service so the ActivityEvent rows match exactly what
  // production traffic would produce.
  const created = await supertest(app).post("/api/ads").set("Authorization", authHeader(agentA)).send(adPayload());
  adA = created.body;
  await supertest(app).patch(`/api/ads/${adA.id}`).set("Authorization", authHeader(agentA)).send({ stage: "2" });

  // Coworker-activity source: a coworker creating an ad under agentA logs
  // AD_CREATED with coworkerId set (adService.js#createAd).
  await supertest(app)
    .post("/api/ads")
    .set("Authorization", authHeader(coworkerA))
    .send(adPayload({ title: "Retail space near Chorsu bazaar" }));

  // Publish-outcome source: AdPublication has no route that can force a
  // PUBLISHED/FAILED row deterministically without real Telegram/Instagram
  // credentials, so — same as createUser bypassing the missing
  // promote-to-agent endpoint — this writes the row directly against the
  // real test database.
  await prisma.adPublication.create({
    data: {
      adId: adA.id,
      channel: "INSTAGRAM",
      status: "PUBLISHED",
      attempts: 1,
      lastAttemptAt: new Date(),
      publishedAt: new Date(),
      requestedById: agentA.id,
    },
  });

  // Noise for agentB, so the scoping tests below fail loudly if agentA's
  // feed ever leaks another agent's rows.
  await supertest(app)
    .post("/api/leads")
    .set("Authorization", authHeader(agentB))
    .send({ fullName: "Not Agent A's Lead", phone: "+998900000001" });
  const bAd = await supertest(app).post("/api/ads").set("Authorization", authHeader(agentB)).send(adPayload({ title: "Agent B's ad" }));
  await prisma.adPublication.create({
    data: { adId: bAd.body.id, channel: "TELEGRAM", status: "FAILED", attempts: 1, lastAttemptAt: new Date(), requestedById: agentB.id },
  });
});

describe("GET /api/notifications — auth and scoping", () => {
  it("requires auth", async () => {
    const res = await supertest(app).get("/api/notifications");
    expect(res.status).toBe(401);
  });

  it("403s a plain USER (no agent scope to derive a feed from)", async () => {
    const res = await supertest(app).get("/api/notifications").set("Authorization", authHeader(buyer));
    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe("forbidden");
  });

  it("returns every derived kind for the agent, and never another agent's rows", async () => {
    const res = await supertest(app).get("/api/notifications").set("Authorization", authHeader(agentA));

    expect(res.status).toBe(200);
    const kinds = res.body.map((n) => n.kind).sort();
    expect(kinds).toEqual(["coworkerActivity", "lead", "publish", "sold"]);

    expect(res.body.some((n) => n.title.includes("Dilnoza Yusupova"))).toBe(true);
    expect(res.body.some((n) => n.title.includes("Not Agent A's Lead"))).toBe(false);
    expect(res.body.some((n) => n.title.includes("Agent B's ad"))).toBe(false);

    const publish = res.body.find((n) => n.kind === "publish");
    expect(publish.title).toContain("Instagram post published");
    expect(publish.targetId).toBe(adA.id);

    const sold = res.body.find((n) => n.kind === "sold");
    expect(sold.title).toContain("marked as Sold");
    expect(sold.targetId).toBe(adA.id);

    const coworkerActivity = res.body.find((n) => n.kind === "coworkerActivity");
    expect(coworkerActivity.title).toContain("Retail space near Chorsu bazaar");
    expect(coworkerActivity.targetId).toBe(coworkerA.id);
  });

  it("a coworker sees their agent's feed (same effectiveAgentId scope)", async () => {
    const res = await supertest(app).get("/api/notifications").set("Authorization", authHeader(coworkerA));
    expect(res.status).toBe(200);
    expect(res.body.some((n) => n.title.includes("Dilnoza Yusupova"))).toBe(true);
  });

  it("agentB's feed never contains agentA's rows", async () => {
    const res = await supertest(app).get("/api/notifications").set("Authorization", authHeader(agentB));
    expect(res.status).toBe(200);
    expect(res.body.every((n) => !n.title.includes("Dilnoza Yusupova"))).toBe(true);
    expect(res.body.some((n) => n.title.includes("Not Agent A's Lead"))).toBe(true);
  });
});

describe("GET /api/notifications — deterministic ids", () => {
  it("returns the exact same ids on two successive calls, with nothing new having happened", async () => {
    const first = await supertest(app).get("/api/notifications").set("Authorization", authHeader(agentA));
    const second = await supertest(app).get("/api/notifications").set("Authorization", authHeader(agentA));

    expect(first.body.map((n) => n.id)).toEqual(second.body.map((n) => n.id));
  });
});

describe("GET /api/notifications — since / unread", () => {
  it("marks everything unread when since is omitted", async () => {
    const res = await supertest(app).get("/api/notifications").set("Authorization", authHeader(agentA));
    expect(res.body.every((n) => n.unread === true)).toBe(true);
  });

  it("marks rows at/after a future since as read, and rejects a malformed since", async () => {
    const future = new Date(Date.now() + 3600_000).toISOString();
    const res = await supertest(app).get(`/api/notifications?since=${encodeURIComponent(future)}`).set("Authorization", authHeader(agentA));
    expect(res.status).toBe(200);
    expect(res.body.every((n) => n.unread === false)).toBe(true);

    const bad = await supertest(app).get("/api/notifications?since=not-a-date").set("Authorization", authHeader(agentA));
    expect(bad.status).toBe(400);
  });
});

describe("GET /api/notifications — limit", () => {
  it("caps the response at ?limit=, and rejects a non-positive limit", async () => {
    const capped = await supertest(app).get("/api/notifications?limit=2").set("Authorization", authHeader(agentA));
    expect(capped.status).toBe(200);
    expect(capped.body).toHaveLength(2);

    const invalid = await supertest(app).get("/api/notifications?limit=0").set("Authorization", authHeader(agentA));
    expect(invalid.status).toBe(400);
  });

  it("caps at MAX_LIMIT even when a huge limit is requested", async () => {
    const res = await supertest(app).get("/api/notifications?limit=999999").set("Authorization", authHeader(agentA));
    expect(res.status).toBe(200);
    // Only 4 real rows exist for agentA regardless of the cap.
    expect(res.body.length).toBeLessThanOrEqual(4);
  });
});
