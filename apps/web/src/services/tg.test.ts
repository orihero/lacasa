// Regression guard: TGService must never talk to api.telegram.org directly
// — the whole point of this migration is that the bot token stays
// server-side (see this file's header for the full story). This test
// intercepts requests to the real Telegram API host and fails loudly if
// TGService.publish ever calls it instead of the server's own
// POST /api/publish/telegram route.
import { HttpResponse, http } from "msw";
import { describe, expect, it } from "vitest";
import { API_BASE, server } from "../test-utils/msw";
import { TGService } from "./tg";

describe("TGService.init", () => {
  it("wraps raw chat ids into stub accounts without fetching anything from Telegram (no server enrichment endpoint exists)", async () => {
    const accounts = await TGService.init([111, 222]);

    expect(accounts).toEqual([{ id: 111 }, { id: 222 }]);
    // Nothing beyond `id` is fabricated.
    expect(accounts[0].title).toBeUndefined();
    expect(accounts[0].username).toBeUndefined();
    expect(accounts[0].file_path).toBeUndefined();
    expect(accounts[0].members_count).toBeUndefined();
  });

  it("returns an empty list for an empty input without making any request", async () => {
    let telegramHit = false;
    server.use(
      http.all("https://api.telegram.org/*", () => {
        telegramHit = true;
        return HttpResponse.json({ ok: false });
      }),
    );

    expect(await TGService.init([])).toEqual([]);
    expect(telegramHit).toBe(false);
  });
});

describe("TGService.publish", () => {
  it("posts to the server's POST /api/publish/telegram route and never directly to api.telegram.org", async () => {
    let hitTelegramDirectly = false;
    let capturedBody: unknown = null;
    server.use(
      http.all("https://api.telegram.org/*", () => {
        hitTelegramDirectly = true;
        return HttpResponse.json({ ok: false });
      }),
      http.post(`${API_BASE}/publish/telegram`, async ({ request }) => {
        capturedBody = await request.json();
        return HttpResponse.json({
          publication: { id: "pub-1", adId: "ad-1", channel: "TELEGRAM", status: "PUBLISHED" },
          results: [{ chatId: "111", ok: true, messageId: 5 }],
        });
      }),
    );

    const { results } = await TGService.publish({
      adId: "ad-1",
      caption: "hello",
      imageUrls: ["https://cdn.example.com/a.jpg"],
      chatIds: [111],
    });

    expect(hitTelegramDirectly).toBe(false);
    expect(capturedBody).toEqual({
      adId: "ad-1",
      caption: "hello",
      imageUrls: ["https://cdn.example.com/a.jpg"],
      chatIds: ["111"],
    });
    expect(results).toEqual([{ chatId: "111", ok: true, messageId: 5 }]);
  });

  it("propagates a server error (e.g. 503 tg_unconfigured) instead of swallowing it", async () => {
    server.use(
      http.post(`${API_BASE}/publish/telegram`, () =>
        HttpResponse.json({ error: { code: "tg_unconfigured", message: "Telegram is not configured" } }, { status: 503 }),
      ),
    );

    await expect(
      TGService.publish({
        adId: "ad-1",
        caption: "hello",
        imageUrls: ["https://cdn.example.com/a.jpg"],
        chatIds: [111],
      }),
    ).rejects.toBeTruthy();
  });
});
