// Telegram Bot API helpers, server-side only. Mirrors lib/instagram.js's
// shape: plain fetch()-based functions, not part of ctx (see publishService.js's
// file header on why direct-publish libs stay a plain import), one
// error-shaping helper. config.TG_BOT_TOKEN is read inside botToken() at
// call time rather than destructured at module load, so importing this
// module never crashes when the var is unset -- callers see a typed
// tg_not_configured error the first time they actually try to call out.

import { config } from "./config.js";

const API = "https://api.telegram.org";

function botToken() {
  const token = config.TG_BOT_TOKEN;
  if (!token) {
    const err = new Error("Telegram bot token is not configured (TG_BOT_TOKEN)");
    err.code = "tg_not_configured";
    err.status = 503;
    throw err;
  }
  return token;
}

async function tgFetch(methodAndQuery, init) {
  const token = botToken();
  const res = await fetch(`${API}/bot${token}/${methodAndQuery}`, init);
  const body = await res.json().catch(() => ({}));
  if (!res.ok || body?.ok === false) {
    const message = body?.description ?? `Telegram API error (${res.status})`;
    const err = new Error(message);
    err.code = "tg_api_error";
    err.status = res.status >= 400 ? res.status : 502;
    throw err;
  }
  return body.result;
}

// Publishes an ad's photos to one chat as an album; caption is attached to
// the last photo only, the same placement the browser-side implementation
// used (apps/web/src/components/adsAdd/AdsAdd.tsx's onSubmitTG, now retired
// in favour of this server-side call).
export async function sendMediaGroup({ chatId, imageUrls, caption }) {
  const media = imageUrls.map((url, i) => ({
    type: "photo",
    media: url,
    ...(i === imageUrls.length - 1 ? { caption } : {}),
  }));
  const params = new URLSearchParams({ chat_id: String(chatId), media: JSON.stringify(media) });
  const result = await tgFetch(`sendMediaGroup?${params}`, { method: "POST" });
  return { messageId: result?.[0]?.message_id ?? null };
}

// Relays the public contact form (POST /api/contact) to the office chat.
export async function sendMessage({ chatId, text }) {
  const params = new URLSearchParams({ chat_id: String(chatId), text });
  const result = await tgFetch(`sendMessage?${params}`, { method: "POST" });
  return { messageId: result?.message_id ?? null };
}
