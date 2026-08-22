import { describe, expect, it, beforeAll } from "vitest";
import supertest from "supertest";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";
import { createUser, authHeader } from "../integration/helpers/factories.js";

const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

let agent;
let freshAgent;
let buyer;

function adPayload(overrides = {}) {
  return {
    title: "Agent counted flat",
    city: "Tashkent",
    district: "Yunusabad",
    type: "residential",
    category: "sale",
    price: 90000,
    ...overrides,
  };
}

beforeAll(async () => {
  agent = await createUser(prisma, { role: "AGENT", email: "agent-counts@example.test" });
  freshAgent = await createUser(prisma, { role: "AGENT", email: "agent-fresh@example.test" });
  buyer = await createUser(prisma, { email: "buyer-counts@example.test" });

  const first = await supertest(app)
    .post("/api/ads")
    .set("Authorization", authHeader(agent))
    .send(adPayload({ title: "Still listed" }));

  await supertest(app)
    .post("/api/ads")
    .set("Authorization", authHeader(agent))
    .send(adPayload({ title: "Will be sold" }));

  // "2" is the wire value for SOLD — see packages/domain/src/enums/ads.ts.
  await supertest(app)
    .patch(`/api/ads/${first.body.id}`)
    .set("Authorization", authHeader(agent))
    .send({ stage: "2" });
});

describe("GET /api/agents/:id", () => {
  it("reports how many ads the agent created and how many they closed", async () => {
    const res = await supertest(app).get(`/api/agents/${agent.id}`);

    expect(res.status).toBe(200);
    expect(res.body.id).toBe(agent.id);
    expect(res.body.adsCount).toBe(2);
    expect(res.body.dealsClosedCount).toBe(1);
  });

  it("reports zeroes for an agent who has done neither", async () => {
    const res = await supertest(app).get(`/api/agents/${freshAgent.id}`);

    expect(res.status).toBe(200);
    expect(res.body.adsCount).toBe(0);
    expect(res.body.dealsClosedCount).toBe(0);
  });

  it("never exposes the password hash on the public card", async () => {
    const res = await supertest(app).get(`/api/agents/${agent.id}`);

    expect(res.body).not.toHaveProperty("passwordHash");
  });

  it("404s an unknown id, and a real user who is not an agent", async () => {
    expect((await supertest(app).get("/api/agents/00000000-0000-0000-0000-000000000000")).status).toBe(404);
    expect((await supertest(app).get(`/api/agents/${buyer.id}`)).status).toBe(404);
  });
});

describe("GET /api/agents", () => {
  it("keeps its existing shape — adsCount only, no dealsClosedCount", async () => {
    const res = await supertest(app).get("/api/agents");

    expect(res.status).toBe(200);
    const found = res.body.find((a) => a.id === agent.id);
    expect(found.adsCount).toBe(2);
    expect(found).not.toHaveProperty("dealsClosedCount");
  });
});

describe("agent reviews", () => {
  let reviewAgent;
  let buyerA;
  let buyerB;
  let buyerC;

  beforeAll(async () => {
    reviewAgent = await createUser(prisma, { role: "AGENT", email: "agent-reviews@example.test" });
    buyerA = await createUser(prisma, { email: "review-buyer-a@example.test" });
    buyerB = await createUser(prisma, { email: "review-buyer-b@example.test" });
    buyerC = await createUser(prisma, { email: "review-buyer-c@example.test" });
  });

  it("reports ratingAverage: null and ratingCount: 0 before any review exists — never 0.0", async () => {
    const res = await supertest(app).get(`/api/agents/${reviewAgent.id}`);

    expect(res.body.ratingAverage).toBeNull();
    expect(res.body.ratingCount).toBe(0);
  });

  it("rejects an out-of-range rating at both boundaries", async () => {
    const low = await supertest(app)
      .post(`/api/agents/${reviewAgent.id}/reviews`)
      .set("Authorization", authHeader(buyerA))
      .send({ rating: 0 });
    const high = await supertest(app)
      .post(`/api/agents/${reviewAgent.id}/reviews`)
      .set("Authorization", authHeader(buyerA))
      .send({ rating: 6 });

    expect(low.status).toBe(400);
    expect(high.status).toBe(400);
  });

  it("rejects a self-review with 403", async () => {
    const res = await supertest(app)
      .post(`/api/agents/${reviewAgent.id}/reviews`)
      .set("Authorization", authHeader(reviewAgent))
      .send({ rating: 5 });

    expect(res.status).toBe(403);
  });

  it("404s when the review target is a real user who is not an AGENT", async () => {
    const res = await supertest(app)
      .post(`/api/agents/${buyer.id}/reviews`)
      .set("Authorization", authHeader(buyerA))
      .send({ rating: 5 });

    expect(res.status).toBe(404);
  });

  it("upserts on a repeat review from the same author instead of stacking a new row", async () => {
    const first = await supertest(app)
      .post(`/api/agents/${reviewAgent.id}/reviews`)
      .set("Authorization", authHeader(buyerA))
      .send({ rating: 3, comment: "Fine" });
    expect(first.status).toBe(200);

    const second = await supertest(app)
      .post(`/api/agents/${reviewAgent.id}/reviews`)
      .set("Authorization", authHeader(buyerA))
      .send({ rating: 5, comment: "Actually great" });
    expect(second.status).toBe(200);
    expect(second.body.id).toBe(first.body.id);

    const list = await supertest(app).get(`/api/agents/${reviewAgent.id}/reviews`);
    const fromBuyerA = list.body.reviews.filter((r) => r.author.id === buyerA.id);
    expect(fromBuyerA).toHaveLength(1);
    expect(fromBuyerA[0].rating).toBe(5);
  });

  it("leaks no email or phone on the review author, and rolls into the agent's rounded ratingAverage", async () => {
    await supertest(app)
      .post(`/api/agents/${reviewAgent.id}/reviews`)
      .set("Authorization", authHeader(buyerB))
      .send({ rating: 4 });

    const list = await supertest(app).get(`/api/agents/${reviewAgent.id}/reviews`);
    for (const review of list.body.reviews) {
      expect(review.author).not.toHaveProperty("email");
      expect(review.author).not.toHaveProperty("phoneNumber");
      expect(Object.keys(review.author).sort()).toEqual(["avatar", "fullName", "id"]);
    }

    // buyerA settled on 5 (see the upsert test above), buyerB just posted 4
    // -> average 4.5, count 2.
    const card = await supertest(app).get(`/api/agents/${reviewAgent.id}`);
    expect(card.body.ratingAverage).toBe(4.5);
    expect(card.body.ratingCount).toBe(2);
  });

  it("paginates with ?limit, returning a cursor only while more rows remain", async () => {
    await supertest(app)
      .post(`/api/agents/${reviewAgent.id}/reviews`)
      .set("Authorization", authHeader(buyerC))
      .send({ rating: 2 });

    const firstPage = await supertest(app).get(`/api/agents/${reviewAgent.id}/reviews?limit=2`);
    expect(firstPage.body.reviews).toHaveLength(2);
    expect(firstPage.body.nextCursor).not.toBeNull();

    const secondPage = await supertest(app).get(
      `/api/agents/${reviewAgent.id}/reviews?limit=2&cursor=${firstPage.body.nextCursor}`,
    );
    expect(secondPage.body.reviews).toHaveLength(1);
    expect(secondPage.body.nextCursor).toBeNull();

    const seenIds = new Set([...firstPage.body.reviews, ...secondPage.body.reviews].map((r) => r.id));
    expect(seenIds.size).toBe(3); // buyerA, buyerB, buyerC — no row skipped or repeated across pages
  });

  it("removes a review on DELETE .../reviews/me, and stays idempotent on a repeat delete", async () => {
    const before = await supertest(app).get(`/api/agents/${reviewAgent.id}`);
    expect(before.body.ratingCount).toBe(3);

    const del = await supertest(app)
      .delete(`/api/agents/${reviewAgent.id}/reviews/me`)
      .set("Authorization", authHeader(buyerC));
    expect(del.status).toBe(204);

    const after = await supertest(app).get(`/api/agents/${reviewAgent.id}`);
    expect(after.body.ratingCount).toBe(2);

    const delAgain = await supertest(app)
      .delete(`/api/agents/${reviewAgent.id}/reviews/me`)
      .set("Authorization", authHeader(buyerC));
    expect(delAgain.status).toBe(204);
  });
});

describe("PATCH /api/users/me — address", () => {
  it("writes the address field and it appears on the public agent card", async () => {
    const patch = await supertest(app)
      .patch("/api/users/me")
      .set("Authorization", authHeader(agent))
      .send({ address: "12 Amir Temur, Tashkent" });

    expect(patch.status).toBe(200);
    expect(patch.body.user.address).toBe("12 Amir Temur, Tashkent");

    const card = await supertest(app).get(`/api/agents/${agent.id}`);
    expect(card.body.address).toBe("12 Amir Temur, Tashkent");
  });
});
