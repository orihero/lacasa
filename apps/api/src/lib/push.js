// Firebase Cloud Messaging (legacy HTTP API) helper, server-side only.
// Mirrors lib/telegram.js's shape exactly (see that file's header comment):
// a plain fetch()-based function, not part of ctx, one error-shaping
// helper, and config.FCM_SERVER_KEY read at call time (inside
// serverKey()) rather than destructured at module load -- so importing
// this module never crashes when the var is unset, and a caller only sees
// a typed push_not_configured error the first time it actually tries to
// send.
//
// This is deliberately never called directly from a route or a request
// path -- the only caller is pushService.js#sendPushToUser, which already
// checks config.PUSH_CONFIGURED before reaching here and wraps this call so
// a delivery failure can never fail the write that triggered it. See that
// file's header comment for the full guarantee.

import { config } from "./config.js";

const API = "https://fcm.googleapis.com/fcm/send";

function serverKey() {
  const key = config.FCM_SERVER_KEY;
  if (!key) {
    const err = new Error("Firebase Cloud Messaging server key is not configured (FCM_SERVER_KEY)");
    err.code = "push_not_configured";
    err.status = 503;
    throw err;
  }
  return key;
}

// Sends one notification to one device token. `data`, when given, rides
// alongside the visible notification payload as FCM's `data` field so a
// tapped notification can deep-link (e.g. `{ targetId }` -> the lead/ad/
// coworker id the notification is about) without the client having to parse
// the display copy back apart.
export async function sendFcmPush({ token, title, body, data }) {
  const key = serverKey();
  const res = await fetch(API, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      Authorization: `key=${key}`,
    },
    body: JSON.stringify({
      to: token,
      notification: { title, body },
      ...(data ? { data } : {}),
    }),
  });
  const payload = await res.json().catch(() => ({}));
  // FCM's legacy API answers 200 even for a token-level failure (an
  // uninstalled app, an expired token) -- `success`/`failure` counts and
  // `results[0].error` are how that's actually reported, not the HTTP
  // status. Both cases -- transport-level (non-2xx) and payload-level
  // (`failure: 1`) -- are folded into the same typed error so the caller
  // (pushService.js) doesn't need to know FCM's particular reporting shape.
  if (!res.ok || payload?.failure > 0) {
    const message = payload?.results?.[0]?.error ?? `FCM push failed (${res.status})`;
    const err = new Error(message);
    err.code = "push_send_failed";
    err.status = res.status >= 400 ? res.status : 502;
    throw err;
  }
  return { messageId: payload?.results?.[0]?.message_id ?? null };
}
