import { afterEach, beforeEach, describe, expect, it, vi } from "vitest";
import { config } from "../../src/lib/config.js";
import { sendMediaGroup, sendMessage } from "../../src/lib/telegram.js";

// config is the same singleton object every module in this app imports (see
// src/lib/config.js) -- mutating its properties for the duration of a test
// and restoring them in afterEach is the same technique test/lib/config.test.js
// uses via loadConfig(), but telegram.js reads the live singleton (like
// lib/instagram.js's appConfig() does with config.IG_APP_ID), not a
// re-parsed copy, so that's what has to move here.
const ORIGINAL_TOKEN = config.TG_BOT_TOKEN;
const ORIGINAL_CONFIGURED = config.TG_CONFIGURED;

afterEach(() => {
  config.TG_BOT_TOKEN = ORIGINAL_TOKEN;
  config.TG_CONFIGURED = ORIGINAL_CONFIGURED;
  vi.unstubAllGlobals();
});

describe("when TG_BOT_TOKEN is unset", () => {
  beforeEach(() => {
    config.TG_BOT_TOKEN = undefined;
    config.TG_CONFIGURED = false;
  });

  it("sendMediaGroup rejects with a typed tg_not_configured error, without calling fetch", async () => {
    const fetchSpy = vi.fn();
    vi.stubGlobal("fetch", fetchSpy);

    await expect(sendMediaGroup({ chatId: "1", imageUrls: ["https://x/1.jpg"], caption: "c" })).rejects.toMatchObject({
      code: "tg_not_configured",
      status: 503,
    });
    expect(fetchSpy).not.toHaveBeenCalled();
  });

  it("sendMessage rejects the same way", async () => {
    await expect(sendMessage({ chatId: "1", text: "hi" })).rejects.toMatchObject({ code: "tg_not_configured", status: 503 });
  });
});

describe("when TG_BOT_TOKEN is set", () => {
  beforeEach(() => {
    config.TG_BOT_TOKEN = "test-token";
    config.TG_CONFIGURED = true;
  });

  it("sendMediaGroup posts to the bot's sendMediaGroup endpoint and returns the message id", async () => {
    const fetchMock = vi.fn().mockResolvedValue({
      ok: true,
      status: 200,
      json: async () => ({ ok: true, result: [{ message_id: 555 }] }),
    });
    vi.stubGlobal("fetch", fetchMock);

    const result = await sendMediaGroup({ chatId: "-100123", imageUrls: ["https://x/1.jpg", "https://x/2.jpg"], caption: "Nice flat" });

    expect(result).toEqual({ messageId: 555 });
    expect(fetchMock).toHaveBeenCalledOnce();
    const [url] = fetchMock.mock.calls[0];
    expect(url).toContain("/bottest-token/sendMediaGroup?");
    expect(url).toContain("chat_id=-100123");
    // caption only on the last item
    const params = new URL(url).searchParams;
    const media = JSON.parse(params.get("media"));
    expect(media).toHaveLength(2);
    expect(media[0].caption).toBeUndefined();
    expect(media[1].caption).toBe("Nice flat");
  });

  it("maps a Telegram API error response (ok:false) to a tg_api_error", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: false,
        status: 403,
        json: async () => ({ ok: false, description: "Forbidden: bot was blocked by the user" }),
      }),
    );

    await expect(sendMediaGroup({ chatId: "-100123", imageUrls: ["https://x/1.jpg"], caption: "c" })).rejects.toMatchObject({
      code: "tg_api_error",
      status: 403,
      message: "Forbidden: bot was blocked by the user",
    });
  });

  it("sendMessage posts to sendMessage and returns the message id", async () => {
    vi.stubGlobal(
      "fetch",
      vi.fn().mockResolvedValue({
        ok: true,
        status: 200,
        json: async () => ({ ok: true, result: { message_id: 42 } }),
      }),
    );

    const result = await sendMessage({ chatId: "-100999", text: "hello" });
    expect(result).toEqual({ messageId: 42 });
  });
});
