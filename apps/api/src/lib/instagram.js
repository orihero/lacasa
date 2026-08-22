// Instagram Graph API helpers ("Business Login for Instagram").
// All calls run server-side with tokens stored in agent_ig_tokens — raw
// tokens are never shipped to the client (docs/09 §1, migration plan E.2).

import { config } from "./config.js";

const IG_OAUTH_AUTHORIZE = "https://www.instagram.com/oauth/authorize";
const IG_OAUTH_TOKEN = "https://api.instagram.com/oauth/access_token";
const GRAPH = "https://graph.instagram.com";

export const IG_SCOPES = "instagram_business_basic,instagram_business_content_publish";

function appConfig() {
  const appId = config.IG_APP_ID;
  const appSecret = config.IG_APP_SECRET;
  const redirectUri = config.IG_REDIRECT_URI;
  if (!appId || !appSecret || !redirectUri) {
    const err = new Error("Instagram OAuth is not configured (IG_APP_ID / IG_APP_SECRET / IG_REDIRECT_URI)");
    err.code = "ig_not_configured";
    throw err;
  }
  return { appId, appSecret, redirectUri };
}

async function graphFetch(url, init) {
  const res = await fetch(url, init);
  const body = await res.json().catch(() => ({}));
  if (!res.ok) {
    const message = body?.error?.message ?? body?.error_message ?? `Instagram API error (${res.status})`;
    const err = new Error(message);
    err.code = "ig_api_error";
    err.status = res.status;
    throw err;
  }
  return body;
}

export function buildAuthorizeUrl(state) {
  const { appId, redirectUri } = appConfig();
  const params = new URLSearchParams({
    client_id: appId,
    redirect_uri: redirectUri,
    response_type: "code",
    scope: IG_SCOPES,
    state,
  });
  return `${IG_OAUTH_AUTHORIZE}?${params}`;
}

// code -> short-lived token
export async function exchangeCode(code) {
  const { appId, appSecret, redirectUri } = appConfig();
  const form = new URLSearchParams({
    client_id: appId,
    client_secret: appSecret,
    grant_type: "authorization_code",
    redirect_uri: redirectUri,
    code,
  });
  return graphFetch(IG_OAUTH_TOKEN, { method: "POST", body: form });
}

// short-lived -> long-lived (60 days)
export async function exchangeLongLived(shortToken) {
  const { appSecret } = appConfig();
  const params = new URLSearchParams({
    grant_type: "ig_exchange_token",
    client_secret: appSecret,
    access_token: shortToken,
  });
  return graphFetch(`${GRAPH}/access_token?${params}`);
}

// refresh a long-lived token (>=24h old, not expired)
export async function refreshLongLived(token) {
  const params = new URLSearchParams({
    grant_type: "ig_refresh_token",
    access_token: token,
  });
  return graphFetch(`${GRAPH}/refresh_access_token?${params}`);
}

export async function fetchMe(token) {
  const params = new URLSearchParams({
    fields: "user_id,username",
    access_token: token,
  });
  return graphFetch(`${GRAPH}/me?${params}`);
}

export async function fetchAccountInfo(igUserId, token) {
  const params = new URLSearchParams({
    fields: "id,username,followers_count,follows_count,media_count,profile_picture_url,biography",
    access_token: token,
  });
  return graphFetch(`${GRAPH}/${igUserId}?${params}`);
}

// Carousel publish: N item containers -> carousel container -> media_publish.
// Mirrors the flow the client used to run in src/services/ig.ts.
export async function publishCarousel({ igUserId, token, imageUrls, caption }) {
  const itemIds = [];
  for (const url of imageUrls) {
    const params = new URLSearchParams({
      access_token: token,
      image_url: url,
      is_carousel_item: "true",
    });
    const res = await graphFetch(`${GRAPH}/${igUserId}/media?${params}`, { method: "POST" });
    itemIds.push(res.id);
  }

  let creationId;
  if (itemIds.length === 1) {
    // Single image: publish the container directly (no carousel wrapper).
    const params = new URLSearchParams({
      access_token: token,
      image_url: imageUrls[0],
      caption,
    });
    const res = await graphFetch(`${GRAPH}/${igUserId}/media?${params}`, { method: "POST" });
    creationId = res.id;
  } else {
    const params = new URLSearchParams({
      access_token: token,
      media_type: "CAROUSEL",
      children: itemIds.join(","),
      caption,
    });
    const res = await graphFetch(`${GRAPH}/${igUserId}/media?${params}`, { method: "POST" });
    creationId = res.id;
  }

  const publishParams = new URLSearchParams({
    access_token: token,
    creation_id: creationId,
  });
  const published = await graphFetch(`${GRAPH}/${igUserId}/media_publish?${publishParams}`, { method: "POST" });
  return { mediaId: published.id, containerId: creationId };
}
