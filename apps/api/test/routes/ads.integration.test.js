import { describe, expect, it, beforeAll } from "vitest";
import supertest from "supertest";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";
import { createUser, authHeader } from "../integration/helpers/factories.js";

const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

let agent;

beforeAll(async () => {
  agent = await createUser(prisma, { role: "AGENT", email: "agent-ads@example.test" });
});

function adPayload(overrides = {}) {
  return {
    title: "Sunny flat",
    city: "Tashkent",
    district: "Yunusabad",
    type: "residential",
    category: "sale",
    price: 120000,
    ...overrides,
  };
}

describe("POST /api/ads", () => {
  it("requires auth", async () => {
    const res = await supertest(app).post("/api/ads").send(adPayload());
    expect(res.status).toBe(401);
  });

  it("creates an ad scoped to the authenticated agent, defaulting stage to active", async () => {
    const res = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Create Test" }));

    expect(res.status).toBe(201);
    expect(res.body.agentId).toBe(agent.id);
    expect(res.body.title).toBe("Create Test");
    expect(res.body.stage).toBe("1"); // AD_STAGE_REV.ACTIVE — see packages/domain/src/enums/ads.ts
    expect(res.body.priceType).toBe("uzs"); // defaults to UZS when omitted
  });
});

describe("GET /api/ads and GET /api/ads/:id", () => {
  let tashkentSale;

  beforeAll(async () => {
    const created = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Tashkent Sale", city: "Tashkent", category: "sale" }));
    tashkentSale = created.body;

    await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Samarkand Rent", city: "Samarkand", category: "rent" }));
  });

  it("lists ads without auth (public listing) and filters by city + category", async () => {
    const all = await supertest(app).get("/api/ads");
    expect(all.status).toBe(200);
    expect(all.body.some((a) => a.title === "Tashkent Sale")).toBe(true);
    expect(all.body.some((a) => a.title === "Samarkand Rent")).toBe(true);

    const filtered = await supertest(app).get("/api/ads").query({ city: "Samarkand", category: "rent" });
    expect(filtered.status).toBe(200);
    expect(filtered.body.length).toBeGreaterThan(0);
    expect(filtered.body.every((a) => a.city === "Samarkand" && a.category === "rent")).toBe(true);
  });

  it("gets a single ad by id and 404s for an unknown id", async () => {
    const found = await supertest(app).get(`/api/ads/${tashkentSale.id}`);
    expect(found.status).toBe(200);
    expect(found.body.id).toBe(tashkentSale.id);

    const missing = await supertest(app).get("/api/ads/00000000-0000-0000-0000-000000000000");
    expect(missing.status).toBe(404);
  });
});
