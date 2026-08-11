import { afterEach, describe, expect, it, vi } from "vitest";
import { config } from "../../src/lib/config.js";
import { sendFcmPush } from "../../src/lib/push.js";

// Mirrors test/lib/telegram.test.js's technique exactly (see that file's own
// header comment): config is the same singleton every module in this app
// imports, mutated for the duration of a test and restored in afterEach,
// and the outbound HTTP call is faked via vi.stubGlobal("fetch", ...) --
// never a real call to FCM.
const ORIGINAL_KEY = config.FCM_SERVER_KEY;
const ORIGINAL_CONFIGURED = config.PUSH_CONFIGURED;

afterEach(() => {
  config.FCM_SERVER_KEY = ORIGINAL_KEY;
  config.PUSH_CONFIGURED = ORIGINAL_CONFIGURED;
  vi.unstubAllGlobals();
});

describe("when FCM_SERVER_KEY is unset", () => {
  it("sendFcmPush rejects with a typed push_not_configured error, without calling fetch", async () => {
    config.FCM_SERVER_KEY = undefined;
    config.PUSH_CONFIGURED = false;
    const fetchSpy = vi.fn();
    vi.stubGlobal("fetch", fetchSpy);

    await expect(sendFcmPush({ token: "tok-1", title: "t", body: "b" })).rejects.toMatchObject({
      code: "push_not_configured",
      status: 503,
    });
    expect(fetchSpy).not.toHaveBeenCalled();
  });
});

describe("when FCM_SERVER_KEY is set", () => {
  it("posts to FCM's legacy send endpoint and returns the message id", async () => {
    config.FCM_SERVER_KEY = "test-key";
    config.PUSH_CONFIGURED = true;
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ success: 1, failure: 0, results: [{ message_id: "0:abc" }] }),
    });
    vi.stubGlobal("fetch", fetchMock);

    const result = await sendFcmPush({
      token: "tok-1",
      title: "New lead",
      body: "New lead: Jane",
      data: { targetId: "lead-1" },
    });

    expect(result).toEqual({ messageId: "0:abc" });
    expect(fetchMock).toHaveBeenCalledOnce();
    const [url, init] = fetchMock.mock.calls[0];
    expect(url).toBe("https://fcm.googleapis.com/fcm/send");
    expect(init.headers.Authorization).toBe("key=test-key");
    expect(JSON.parse(init.body)).toEqual({
      to: "tok-1",
      notification: { title: "New lead", body: "New lead: Jane" },
      data: { targetId: "lead-1" },
    });
  });

  it("omits `data` entirely when no targetId is given", async () => {
    config.FCM_SERVER_KEY = "test-key";
    config.PUSH_CONFIGURED = true;
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ success: 1, failure: 0, results: [{}] }),
    });
    vi.stubGlobal("fetch", fetchMock);

    await sendFcmPush({ token: "tok-1", title: "t", body: "b" });

    const [, init] = fetchMock.mock.calls[0];
    expect(JSON.parse(init.body)).toEqual({ to: "tok-1", notification: { title: "t", body: "b" } });
  });

  it("maps a transport-level error response (ok:false) to push_send_failed", async () => {
    config.FCM_SERVER_KEY = "test-key";
    config.PUSH_CONFIGURED = true;
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({ ok: false, status: 401, json: async () => ({ results: [{ error: "InvalidApiKey" }] }) }),
    );

    await expect(sendFcmPush({ token: "tok-1", title: "t", body: "b" })).rejects.toMatchObject({
      code: "push_send_failed",
      status: 401,
      message: "InvalidApiKey",
    });
  });

  // FCM's legacy API answers 200 even for a token-level failure (an
  // uninstalled app, an expired token) -- `failure: 1` is how that's
  // actually reported, not the HTTP status. See lib/push.js's own comment.
  it("maps a payload-level failure (ok:true, failure:1) to push_send_failed too", async () => {
    config.FCM_SERVER_KEY = "test-key";
    config.PUSH_CONFIGURED = true;
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        status: 200,
        json: async () => ({ success: 0, failure: 1, results: [{ error: "NotRegistered" }] }),
      }),
    );

    await expect(sendFcmPush({ token: "tok-1", title: "t", body: "b" })).rejects.toMatchObject({
      code: "push_send_failed",
      message: "NotRegistered",
    });
  });
});
