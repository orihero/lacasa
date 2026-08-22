import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { createFakePrisma } from "../helpers/testApp.js";
import { config } from "../../src/lib/config.js";
import * as pushService from "../../src/services/pushService.js";

// Same config-mutation + vi.stubGlobal("fetch") technique as
// test/lib/push.test.js / test/lib/telegram.test.js -- see either file's
// header comment. registerDevice/unregisterDevice never touch config or
// fetch at all, so most of those tests don't need this, but sendPushToUser
// and the two notifyX functions route straight through lib/push.js's real
// fetch() call once PUSH_CONFIGURED is true.
const ORIGINAL_KEY = config.FCM_SERVER_KEY;
const ORIGINAL_CONFIGURED = config.PUSH_CONFIGURED;

afterEach(() => {
  config.FCM_SERVER_KEY = ORIGINAL_KEY;
  config.PUSH_CONFIGURED = ORIGINAL_CONFIGURED;
  vi.unstubAllGlobals();
  vi.restoreAllMocks();
});

function fcmOk(overrides = {}) {
  return { ok: true, status: 200, json: async () => ({ success: 1, failure: 0, results: [{}], ...overrides }) };
}

describe("registerDevice / unregisterDevice", () => {
  it("upserts on (userId, token), mapping the wire platform to the Prisma enum", async () => {
    const upsert = vi.fn().mockResolvedValue({});
    const prisma = createFakePrisma({ deviceToken: { upsert } });

    await pushService.registerDevice({ prisma }, "user-1", { token: "tok-1", platform: "android" });

    expect(upsert).toHaveBeenCalledWith({
      where: { userId_token: { userId: "user-1", token: "tok-1" } },
      create: { userId: "user-1", token: "tok-1", platform: "ANDROID" },
      update: { platform: "ANDROID" },
    });
  });

  it("registering the same device twice is one call to the same idempotent upsert -- no separate create/update branching in this layer", async () => {
    const upsert = vi.fn().mockResolvedValue({});
    const prisma = createFakePrisma({ deviceToken: { upsert } });

    await pushService.registerDevice({ prisma }, "user-1", { token: "tok-1", platform: "ios" });
    await pushService.registerDevice({ prisma }, "user-1", { token: "tok-1", platform: "ios" });

    expect(upsert).toHaveBeenCalledTimes(2);
    expect(upsert.mock.calls[0]).toEqual(upsert.mock.calls[1]);
  });

  it("unregisterDevice always succeeds, even for a token that was never registered", async () => {
    const deleteMany = vi.fn().mockResolvedValue({ count: 0 });
    const prisma = createFakePrisma({ deviceToken: { deleteMany } });

    await expect(pushService.unregisterDevice({ prisma }, "user-1", "never-registered")).resolves.toBeUndefined();
    expect(deleteMany).toHaveBeenCalledWith({ where: { userId: "user-1", token: "never-registered" } });
  });
});

describe("sendPushToUser", () => {
  it("skips and never touches the database when no provider is configured (the default, unset state)", async () => {
    config.FCM_SERVER_KEY = undefined;
    config.PUSH_CONFIGURED = false;
    const findMany = vi.fn();
    const prisma = createFakePrisma({ deviceToken: { findMany } });

    const result = await pushService.sendPushToUser({ prisma }, "user-1", { title: "t", body: "b" });

    expect(result).toEqual({ sent: 0, skipped: "unconfigured" });
    expect(findMany).not.toHaveBeenCalled();
  });

  it("skips with no_devices when the user has no registered devices", async () => {
    config.FCM_SERVER_KEY = "key";
    config.PUSH_CONFIGURED = true;
    const prisma = createFakePrisma({ deviceToken: { findMany: vi.fn().mockResolvedValue([]) } });

    const result = await pushService.sendPushToUser({ prisma }, "user-1", { title: "t", body: "b" });
    expect(result).toEqual({ sent: 0, skipped: "no_devices" });
  });

  it("delivers to every registered device, tolerating one device's failure without affecting the others", async () => {
    config.FCM_SERVER_KEY = "key";
    config.PUSH_CONFIGURED = true;
    const tokens = [
      { id: "dev-1", token: "tok-1" },
      { id: "dev-2", token: "tok-2" },
    ];
    const prisma = createFakePrisma({ deviceToken: { findMany: vi.fn().mockResolvedValue(tokens) } });
    const fetchMock = vi
      .fn()
      .mockResolvedValueOnce(fcmOk())
      .mockResolvedValueOnce({ ok: false, status: 404, json: async () => ({ results: [{ error: "NotRegistered" }] }) });
    vi.stubGlobal("fetch", fetchMock);
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});

    const result = await pushService.sendPushToUser({ prisma }, "user-1", {
      title: "New lead",
      body: "New lead: Jane Buyer",
      targetId: "lead-1",
    });

    expect(result).toEqual({ sent: 1, skipped: null });
    expect(fetchMock).toHaveBeenCalledTimes(2);
    const [, init] = fetchMock.mock.calls[0];
    expect(JSON.parse(init.body)).toEqual({
      to: "tok-1",
      notification: { title: "New lead", body: "New lead: Jane Buyer" },
      data: { targetId: "lead-1" },
    });
    // The second device's failure was logged, not silently dropped.
    expect(errorSpy).toHaveBeenCalledWith(expect.stringContaining("dev-2"), expect.anything());
  });

  // The central guarantee this file exists to prove: see pushService.js's
  // header comment and lib/activity.js / publishService.js's call sites,
  // none of which can afford this to reject.
  it("never throws, even when the device lookup itself fails", async () => {
    config.FCM_SERVER_KEY = "key";
    config.PUSH_CONFIGURED = true;
    const prisma = createFakePrisma({ deviceToken: { findMany: vi.fn().mockRejectedValue(new Error("db down")) } });
    vi.spyOn(console, "error").mockImplementation(() => {});

    await expect(pushService.sendPushToUser({ prisma }, "user-1", { title: "t", body: "b" })).resolves.toEqual({
      sent: 0,
      skipped: "error",
    });
  });
});

describe("notifyForActivityEvent", () => {
  beforeEach(() => {
    config.FCM_SERVER_KEY = "key";
    config.PUSH_CONFIGURED = true;
  });

  it("pushes a LEAD_CREATED event using the exact same copy the pull feed (notificationService.js) renders", async () => {
    const prisma = createFakePrisma({
      deviceToken: { findMany: vi.fn().mockResolvedValue([{ id: "dev-1", token: "tok-1" }]) },
      lead: { findUnique: vi.fn().mockResolvedValue({ id: "lead-1", fullName: "Jane Buyer" }) },
    });
    const fetchMock = vi.fn().mockResolvedValue(fcmOk());
    vi.stubGlobal("fetch", fetchMock);

    await pushService.notifyForActivityEvent({ prisma }, {
      id: "event-1",
      type: "LEAD_CREATED",
      agentId: "agent-1",
      coworkerId: null,
      leadId: "lead-1",
      createdAt: new Date(),
    });

    expect(fetchMock).toHaveBeenCalledOnce();
    const body = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(body.notification).toEqual({ title: "New lead", body: "New lead: Jane Buyer" });
    expect(body.data).toEqual({ targetId: "lead-1" });
  });

  it("skips event types with no corresponding notification kind (e.g. cross-post session bookkeeping), without touching the database", async () => {
    const findUnique = vi.fn();
    const prisma = createFakePrisma({ lead: { findUnique } });

    await pushService.notifyForActivityEvent({ prisma }, {
      id: "event-1",
      type: "OLX_CROSSPOST_STARTED",
      agentId: "agent-1",
      coworkerId: null,
      leadId: null,
    });

    expect(findUnique).not.toHaveBeenCalled();
  });

  it("skips agent-authored AD_CREATED (no coworkerId) -- same rule the pull feed applies", async () => {
    const findUnique = vi.fn();
    const prisma = createFakePrisma({ ad: { findUnique } });

    await pushService.notifyForActivityEvent({ prisma }, {
      id: "event-1",
      type: "AD_CREATED",
      agentId: "agent-1",
      coworkerId: null,
      adId: "ad-1",
    });

    expect(findUnique).not.toHaveBeenCalled();
  });

  it("pushes a coworker-authored AD_CREATED event", async () => {
    const prisma = createFakePrisma({
      deviceToken: { findMany: vi.fn().mockResolvedValue([{ id: "dev-1", token: "tok-1" }]) },
      ad: { findUnique: vi.fn().mockResolvedValue({ id: "ad-2", title: "Retail space near Chorsu bazaar" }) },
      user: { findUnique: vi.fn().mockResolvedValue({ id: "coworker-1", fullName: "Sardor Abdullayev" }) },
    });
    const fetchMock = vi.fn().mockResolvedValue(fcmOk());
    vi.stubGlobal("fetch", fetchMock);

    await pushService.notifyForActivityEvent({ prisma }, {
      id: "event-1",
      type: "AD_CREATED",
      agentId: "agent-1",
      coworkerId: "coworker-1",
      adId: "ad-2",
    });

    const body = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(body.notification.title).toBe("Coworker activity");
    expect(body.notification.body).toBe("Coworker added a new listing — Sardor Abdullayev created Retail space near Chorsu bazaar");
  });

  // Never fails the write it's attached to (lib/activity.js's
  // logActivityEvent) even when the best-effort relation lookup itself blows up.
  it("never throws when the relation lookup fails", async () => {
    const prisma = createFakePrisma({ lead: { findUnique: vi.fn().mockRejectedValue(new Error("boom")) } });
    vi.spyOn(console, "error").mockImplementation(() => {});

    await expect(
      pushService.notifyForActivityEvent({ prisma }, {
        id: "event-1",
        type: "LEAD_CREATED",
        agentId: "agent-1",
        coworkerId: null,
        leadId: "lead-1",
      }),
    ).resolves.toBeUndefined();
  });
});

describe("notifyPublishOutcome", () => {
  beforeEach(() => {
    config.FCM_SERVER_KEY = "key";
    config.PUSH_CONFIGURED = true;
  });

  it("pushes a PUBLISHED outcome to the ad's owning agent, reusing buildPublishNotification's copy", async () => {
    const prisma = createFakePrisma({
      ad: { findUnique: vi.fn().mockResolvedValue({ id: "ad-1", title: "Sunny flat", agentId: "agent-1" }) },
      deviceToken: { findMany: vi.fn().mockResolvedValue([{ id: "dev-1", token: "tok-1" }]) },
    });
    const fetchMock = vi.fn().mockResolvedValue(fcmOk());
    vi.stubGlobal("fetch", fetchMock);

    await pushService.notifyPublishOutcome({ prisma }, {
      adId: "ad-1",
      channel: "TELEGRAM",
      status: "PUBLISHED",
      lastAttemptAt: new Date(),
      updatedAt: new Date(),
    });

    const body = JSON.parse(fetchMock.mock.calls[0][1].body);
    expect(body.notification.title).toBe("Publish update");
    expect(body.notification.body).toBe("Telegram post published — Sunny flat is now live on Telegram");
    expect(body.data).toEqual({ targetId: "ad-1" });
  });

  it("no-ops for a non-terminal status (PENDING/DRAFTED_AWAITING_REVIEW) -- nothing to announce yet", async () => {
    const findUnique = vi.fn();
    const prisma = createFakePrisma({ ad: { findUnique } });

    await pushService.notifyPublishOutcome({ prisma }, { adId: "ad-1", channel: "OLX", status: "PENDING" });

    expect(findUnique).not.toHaveBeenCalled();
  });

  it("no-ops for a still-open draft publication -- no Ad row yet means no agent to notify", async () => {
    const findMany = vi.fn();
    const prisma = createFakePrisma({
      ad: { findUnique: vi.fn().mockResolvedValue(null) },
      deviceToken: { findMany },
    });

    await pushService.notifyPublishOutcome({ prisma }, { adId: "draft-abc", channel: "TELEGRAM", status: "FAILED" });

    expect(findMany).not.toHaveBeenCalled();
  });

  it("never throws when the ad lookup fails", async () => {
    const prisma = createFakePrisma({ ad: { findUnique: vi.fn().mockRejectedValue(new Error("boom")) } });
    vi.spyOn(console, "error").mockImplementation(() => {});

    await expect(
      pushService.notifyPublishOutcome({ prisma }, { adId: "ad-1", channel: "TELEGRAM", status: "PUBLISHED" }),
    ).resolves.toBeUndefined();
  });
});
