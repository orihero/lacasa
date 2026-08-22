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
  agent = await createUser(prisma, { role: "AGENT", email: "agent-leads@example.test" });
});

describe("leads auth", () => {
  it("requires auth to list or create", async () => {
    const list = await supertest(app).get("/api/leads");
    expect(list.status).toBe(401);

    const create = await supertest(app).post("/api/leads").send({ fullName: "X", phone: "1" });
    expect(create.status).toBe(401);
  });
});

describe("POST /api/leads + GET /api/leads", () => {
  it("creates a lead scoped to the agent, defaulting status to new", async () => {
    const res = await supertest(app)
      .post("/api/leads")
      .set("Authorization", authHeader(agent))
      .send({ fullName: "Jane Buyer", phone: "+998901112233" });

    expect(res.status).toBe(201);
    expect(res.body.agentId).toBe(agent.id);
    expect(res.body.status).toBe("new");

    const list = await supertest(app).get("/api/leads").set("Authorization", authHeader(agent));
    expect(list.status).toBe(200);
    expect(list.body.some((l) => l.id === res.body.id)).toBe(true);
  });
});

describe("PATCH /api/leads/:id — status transition", () => {
  it("moves a lead through its status lifecycle", async () => {
    const created = await supertest(app)
      .post("/api/leads")
      .set("Authorization", authHeader(agent))
      .send({ fullName: "Transition Lead", phone: "+998907778899" });
    expect(created.body.status).toBe("new");

    const calledBack = await supertest(app)
      .patch(`/api/leads/${created.body.id}`)
      .set("Authorization", authHeader(agent))
      .send({ status: "need_to_call_back" });
    expect(calledBack.status).toBe(200);
    expect(calledBack.body.status).toBe("need_to_call_back");

    const accepted = await supertest(app)
      .patch(`/api/leads/${created.body.id}`)
      .set("Authorization", authHeader(agent))
      .send({ status: "accepted" });
    expect(accepted.status).toBe(200);
    expect(accepted.body.status).toBe("accepted");
  });

  it("404s when the lead doesn't exist under the caller's agent scope", async () => {
    const otherAgent = await createUser(prisma, { role: "AGENT", email: "agent-leads-other@example.test" });
    const theirs = await supertest(app)
      .post("/api/leads")
      .set("Authorization", authHeader(otherAgent))
      .send({ fullName: "Not Yours", phone: "+998900000000" });

    const res = await supertest(app)
      .patch(`/api/leads/${theirs.body.id}`)
      .set("Authorization", authHeader(agent))
      .send({ status: "accepted" });
    expect(res.status).toBe(404);
  });
});
