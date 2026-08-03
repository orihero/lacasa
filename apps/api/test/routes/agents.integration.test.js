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
