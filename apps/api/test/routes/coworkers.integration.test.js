import { describe, expect, it, beforeAll } from "vitest";
import supertest from "supertest";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";
import { createUser, authHeader } from "../integration/helpers/factories.js";

const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

let agentA, agentB, coworkerA, coworkerB;

beforeAll(async () => {
  agentA = await createUser(prisma, { role: "AGENT", email: "coworker-agent-a@example.test" });
  agentB = await createUser(prisma, { role: "AGENT", email: "coworker-agent-b@example.test" });
  coworkerA = await createUser(prisma, { role: "COWORKER", agentId: agentA.id, email: "coworker-a@example.test" });
  coworkerB = await createUser(prisma, { role: "COWORKER", agentId: agentB.id, email: "coworker-b@example.test" });
});

describe("POST /api/coworkers", () => {
  it("lets an agent create a coworker under their own agentId", async () => {
    const res = await supertest(app)
      .post("/api/coworkers")
      .set("Authorization", authHeader(agentA))
      .send({ fullName: "New Coworker", email: "new-coworker-a@example.test", password: "password123" });

    expect(res.status).toBe(201);
    expect(res.body.agentId).toBe(agentA.id);
  });

  it("forbids a coworker (non-agent) from creating another coworker", async () => {
    const res = await supertest(app)
      .post("/api/coworkers")
      .set("Authorization", authHeader(coworkerA))
      .send({ fullName: "Nope", email: "nope-coworker@example.test", password: "password123" });

    expect(res.status).toBe(403);
  });
});

describe("coworker CRUD scoping — a coworker must not read another agent's data", () => {
  it("GET / only ever returns coworkers within the caller's own agent scope", async () => {
    const asAgentA = await supertest(app).get("/api/coworkers").set("Authorization", authHeader(agentA));
    expect(asAgentA.status).toBe(200);
    expect(asAgentA.body.some((c) => c.id === coworkerA.id)).toBe(true);
    expect(asAgentA.body.some((c) => c.id === coworkerB.id)).toBe(false);

    // A coworker can see their own siblings (same agentId), never another agent's.
    const asCoworkerA = await supertest(app).get("/api/coworkers").set("Authorization", authHeader(coworkerA));
    expect(asCoworkerA.status).toBe(200);
    expect(asCoworkerA.body.every((c) => c.agentId === agentA.id)).toBe(true);
    expect(asCoworkerA.body.some((c) => c.id === coworkerB.id)).toBe(false);
  });

  it("GET /:id 404s when fetching another agent's coworker", async () => {
    const crossAgent = await supertest(app)
      .get(`/api/coworkers/${coworkerB.id}`)
      .set("Authorization", authHeader(agentA));
    expect(crossAgent.status).toBe(404);

    const crossCoworker = await supertest(app)
      .get(`/api/coworkers/${coworkerB.id}`)
      .set("Authorization", authHeader(coworkerA));
    expect(crossCoworker.status).toBe(404);
  });

  it("PATCH and DELETE 404 (not 200/204) on another agent's coworker", async () => {
    const patch = await supertest(app)
      .patch(`/api/coworkers/${coworkerB.id}`)
      .set("Authorization", authHeader(agentA))
      .send({ fullName: "Hijacked" });
    expect(patch.status).toBe(404);

    const del = await supertest(app).delete(`/api/coworkers/${coworkerB.id}`).set("Authorization", authHeader(agentA));
    expect(del.status).toBe(404);

    // coworkerB is untouched
    const stillThere = await prisma.user.findUnique({ where: { id: coworkerB.id } });
    expect(stillThere).not.toBeNull();
    expect(stillThere.fullName).not.toBe("Hijacked");
  });
});
