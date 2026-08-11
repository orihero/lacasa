import { describe, expect, it, beforeAll } from "vitest";
import supertest from "supertest";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";
import { createUser, authHeader } from "../integration/helpers/factories.js";

// POST /api/push/devices, DELETE /api/push/devices/:token, end to end
// against real Postgres. Covers: idempotent re-registration (the whole
// point of DeviceToken's @@unique([userId, token])), unregister (including
// its no-op-on-unknown-token case), auth rejection, and that any
// authenticated role can register (unlike e.g. savedAds.js's buyer-only
// gate — see push.js's own header comment on why this route has no role
// restriction).

const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

let agent, coworker, buyer;

beforeAll(async () => {
  agent = await createUser(prisma, { role: "AGENT", email: "push-agent@example.test" });
  coworker = await createUser(prisma, { role: "COWORKER", agentId: agent.id, email: "push-coworker@example.test" });
  buyer = await createUser(prisma, { email: "push-buyer@example.test" });
});

describe("POST /api/push/devices auth", () => {
  it("requires auth", async () => {
    const res = await supertest(app).post("/api/push/devices").send({ token: "tok-1", platform: "android" });
    expect(res.status).toBe(401);
  });
});

describe("DELETE /api/push/devices/:token auth", () => {
  it("requires auth", async () => {
    const res = await supertest(app).delete("/api/push/devices/tok-1");
    expect(res.status).toBe(401);
  });
});

describe("registering a device", () => {
  it("registers a new device and returns { ok: true }", async () => {
    const res = await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(buyer))
      .send({ token: "buyer-device-1", platform: "ios" });

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true });

    const row = await prisma.deviceToken.findUnique({
      where: { userId_token: { userId: buyer.id, token: "buyer-device-1" } },
    });
    expect(row).not.toBeNull();
    expect(row.platform).toBe("IOS");
  });

  it("treats a repeat registration of the same device as the same fact -- same response, still one row", async () => {
    const first = await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(buyer))
      .send({ token: "buyer-device-2", platform: "android" });
    expect(first.status).toBe(200);

    const again = await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(buyer))
      .send({ token: "buyer-device-2", platform: "android" });
    expect(again.status).toBe(200);
    expect(again.body).toEqual({ ok: true });

    expect(await prisma.deviceToken.count({ where: { userId: buyer.id, token: "buyer-device-2" } })).toBe(1);
  });

  it("updates the platform on a re-registration that reports a different one", async () => {
    await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(buyer))
      .send({ token: "buyer-device-3", platform: "android" });

    await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(buyer))
      .send({ token: "buyer-device-3", platform: "ios" });

    const row = await prisma.deviceToken.findUnique({
      where: { userId_token: { userId: buyer.id, token: "buyer-device-3" } },
    });
    expect(row.platform).toBe("IOS");
  });

  it("keeps one user's device rows out of another's -- same token, different owners, two rows", async () => {
    await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(agent))
      .send({ token: "shared-token", platform: "android" });
    await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(buyer))
      .send({ token: "shared-token", platform: "android" });

    expect(await prisma.deviceToken.count({ where: { token: "shared-token" } })).toBe(2);
  });

  it("allows an agent and a coworker to register too -- this route has no role restriction", async () => {
    const agentRes = await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(agent))
      .send({ token: "agent-device-1", platform: "android" });
    expect(agentRes.status).toBe(200);

    const coworkerRes = await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(coworker))
      .send({ token: "coworker-device-1", platform: "android" });
    expect(coworkerRes.status).toBe(200);
  });

  it("400s a missing token", async () => {
    const res = await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(buyer))
      .send({ platform: "android" });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });

  it("400s an unrecognised platform", async () => {
    const res = await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(buyer))
      .send({ token: "tok-x", platform: "windows-phone" });
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });
});

describe("unregistering a device", () => {
  it("unregisters a device and it no longer exists", async () => {
    await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(buyer))
      .send({ token: "buyer-device-to-remove", platform: "ios" });

    const res = await supertest(app)
      .delete("/api/push/devices/buyer-device-to-remove")
      .set("Authorization", authHeader(buyer));
    expect(res.status).toBe(204);

    const row = await prisma.deviceToken.findUnique({
      where: { userId_token: { userId: buyer.id, token: "buyer-device-to-remove" } },
    });
    expect(row).toBeNull();
  });

  it("still 204s a repeat unregister of the same token", async () => {
    await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(buyer))
      .send({ token: "buyer-device-repeat-unreg", platform: "ios" });
    await supertest(app)
      .delete("/api/push/devices/buyer-device-repeat-unreg")
      .set("Authorization", authHeader(buyer));

    const again = await supertest(app)
      .delete("/api/push/devices/buyer-device-repeat-unreg")
      .set("Authorization", authHeader(buyer));
    expect(again.status).toBe(204);
  });

  it("204s unregistering a token that was never registered", async () => {
    const res = await supertest(app)
      .delete("/api/push/devices/never-registered-token")
      .set("Authorization", authHeader(buyer));
    expect(res.status).toBe(204);
  });

  it("only removes the caller's own row for a shared token, not another user's", async () => {
    await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(agent))
      .send({ token: "cross-user-token", platform: "android" });
    await supertest(app)
      .post("/api/push/devices")
      .set("Authorization", authHeader(buyer))
      .send({ token: "cross-user-token", platform: "android" });

    await supertest(app).delete("/api/push/devices/cross-user-token").set("Authorization", authHeader(buyer));

    expect(await prisma.deviceToken.count({ where: { token: "cross-user-token" } })).toBe(1);
    expect(
      await prisma.deviceToken.findUnique({ where: { userId_token: { userId: agent.id, token: "cross-user-token" } } }),
    ).not.toBeNull();
  });
});
