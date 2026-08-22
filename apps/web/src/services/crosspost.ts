// Cross-posting client: server-side Instagram Graph publishing (token path,
// delegated to @lacasa/api-client's publish/auth resources) and the
// postMessage handshake with the La Casa browser extension (OLX + Instagram
// fallback path, using @lacasa/crosspost-protocol's message contract
// instead of hand-duplicating the envelope shapes). See docs/07 §2 and
// docs/09.
//
// CASING NOTE (deliberate deviation — mirrors
// apps/extension/src/lib/types.ts's CASING NOTE): @lacasa/crosspost-protocol's
// AssistedChannel is 'OLX' | 'INSTAGRAM' (the DB-enum casing). The wire
// format this file and apps/api/src/routes/publish.js's CHANNELS map
// actually speak is lowercase ("olx" | "instagram"). `CrosspostChannel`
// derives from AssistedChannel via `Lowercase<...>` so it keeps tracking the
// package's channel set without adopting its casing here — see
// apps/extension/src/lib/types.ts for the matching override on the other
// end of this postMessage bridge.
import type { IgPublishResult as ApiIgPublishResult, InstagramAccount } from "@lacasa/api-client";
import {
  EXT_SOURCE,
  PAGE_SOURCE,
  buildCrosspostPingMessage,
  isCrosspostPongMessage,
  isCrosspostResultMessage,
} from "@lacasa/crosspost-protocol";
import type { AssistedChannel, CrosspostRequestMessage } from "@lacasa/crosspost-protocol";
import { api, getAuthToken } from "../lib/api";
import { apiClient } from "../lib/apiClient";

export type CrosspostChannel = Lowercase<AssistedChannel>;

export interface AdPayload {
  [key: string]: unknown;
}

// Resolves true when the extension's content-script bridge answers the ping.
export function pingExtension(): Promise<boolean> {
  return new Promise((resolve) => {
    const id = crypto.randomUUID();
    const onMsg = (e: MessageEvent) => {
      if (e.source !== window || e.origin !== window.location.origin) return;
      if (isCrosspostPongMessage(e.data) && e.data.id === id) {
        window.removeEventListener("message", onMsg);
        resolve(true);
      }
    };
    window.addEventListener("message", onMsg);
    window.postMessage(buildCrosspostPingMessage(id), window.location.origin);
    setTimeout(() => {
      window.removeEventListener("message", onMsg);
      resolve(false);
    }, 500);
  });
}

// Hands the ad to the extension, which opens the target site in a new tab
// and runs the assisted-autofill flow there. Resolves once the background
// worker accepted (or refused) the job.
export function requestCrosspost(opts: {
  channel: CrosspostChannel;
  adId: string;
  ad: AdPayload;
  photoUrls: string[];
}): Promise<{ ok: boolean; error?: string }> {
  return new Promise((resolve) => {
    const requestId = crypto.randomUUID();
    // See the CASING NOTE above: channel stays lowercase on this bridge,
    // overriding CrosspostRequestMessage's (uppercase) `channel` field —
    // same override apps/extension/src/lib/types.ts's PageCrosspostRequest
    // makes on the receiving end.
    const message: Omit<CrosspostRequestMessage, "channel"> & { channel: CrosspostChannel } = {
      source: PAGE_SOURCE,
      type: "CROSSPOST_REQUEST",
      requestId,
      channel: opts.channel,
      adId: opts.adId,
      ad: opts.ad,
      photoUrls: opts.photoUrls,
      token: getAuthToken() ?? "",
      apiBase: api.defaults.baseURL ?? "",
    };
    const onMsg = (e: MessageEvent) => {
      if (e.source !== window || e.origin !== window.location.origin) return;
      if (e.data?.source === EXT_SOURCE && isCrosspostResultMessage(e.data) && e.data.requestId === requestId) {
        window.removeEventListener("message", onMsg);
        resolve({ ok: !!e.data.ok, error: e.data.error });
      }
    };
    window.addEventListener("message", onMsg);
    window.postMessage(message, window.location.origin);
    setTimeout(() => {
      window.removeEventListener("message", onMsg);
      resolve({ ok: false, error: "The extension did not respond" });
    }, 15000);
  });
}

// ---------------------------------------------------------------------------
// Server-side Instagram (stored token path) — request shaping now lives in
// @lacasa/api-client's publish/auth resources; this just re-exposes the
// subset apps/web's components call, with their existing signatures.

export type IgPublishResult = ApiIgPublishResult;

export async function publishInstagramServerSide(opts: {
  adId: string;
  caption: string;
  imageUrls: string[];
  igUserIds?: string[];
}): Promise<{ results: IgPublishResult[] }> {
  return apiClient.publish.publishInstagram(opts);
}

export async function getInstagramAccounts(): Promise<InstagramAccount[]> {
  const { accounts } = await apiClient.publish.getInstagramAccounts();
  return accounts;
}

export async function grantIgAssistConsent(): Promise<void> {
  await apiClient.publish.grantInstagramAssistConsent();
}

export async function getInstagramConnectUrl(): Promise<string> {
  const { url } = await apiClient.auth.getInstagramConnectUrl();
  return url;
}

export async function disconnectInstagram(igUserId: string): Promise<void> {
  await apiClient.auth.disconnectInstagram(igUserId);
}
