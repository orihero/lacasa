// Cross-posting client: server-side Instagram Graph publishing (token path)
// and the postMessage handshake with the La Casa browser extension
// (OLX + Instagram fallback path). See docs/07 §2 and docs/09.
import { api, getAuthToken } from "../lib/api";

export type CrosspostChannel = "olx" | "instagram";

const PAGE_SOURCE = "lacasa-app";
const EXT_SOURCE = "lacasa-ext";

export interface AdPayload {
  [key: string]: unknown;
}

// Resolves true when the extension's content-script bridge answers the ping.
export function pingExtension(): Promise<boolean> {
  return new Promise((resolve) => {
    const id = crypto.randomUUID();
    const onMsg = (e: MessageEvent) => {
      if (e.source !== window || e.origin !== window.location.origin) return;
      if (e.data?.source === EXT_SOURCE && e.data?.type === "CROSSPOST_PONG" && e.data.id === id) {
        window.removeEventListener("message", onMsg);
        resolve(true);
      }
    };
    window.addEventListener("message", onMsg);
    window.postMessage({ source: PAGE_SOURCE, type: "CROSSPOST_PING", id }, window.location.origin);
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
    const onMsg = (e: MessageEvent) => {
      if (e.source !== window || e.origin !== window.location.origin) return;
      if (e.data?.source === EXT_SOURCE && e.data?.type === "CROSSPOST_RESULT" && e.data.requestId === requestId) {
        window.removeEventListener("message", onMsg);
        resolve({ ok: !!e.data.ok, error: e.data.error });
      }
    };
    window.addEventListener("message", onMsg);
    window.postMessage(
      {
        source: PAGE_SOURCE,
        type: "CROSSPOST_REQUEST",
        requestId,
        channel: opts.channel,
        adId: opts.adId,
        ad: opts.ad,
        photoUrls: opts.photoUrls,
        token: getAuthToken(),
        apiBase: api.defaults.baseURL,
      },
      window.location.origin,
    );
    setTimeout(() => {
      window.removeEventListener("message", onMsg);
      resolve({ ok: false, error: "The extension did not respond" });
    }, 15000);
  });
}

// ---------------------------------------------------------------------------
// Server-side Instagram (stored token path)

export interface IgPublishResult {
  igUserId: string;
  igUsername: string | null;
  ok: boolean;
  mediaId?: string;
  error?: string;
}

export async function publishInstagramServerSide(opts: {
  adId: string;
  caption: string;
  imageUrls: string[];
  igUserIds?: string[];
}): Promise<{ results: IgPublishResult[] }> {
  const { data } = await api.post("/publish/instagram", opts);
  return data;
}

export async function getInstagramAccounts() {
  const { data } = await api.get("/publish/instagram/accounts");
  return data.accounts as Array<{
    igUserId: string;
    username: string | null;
    expiresAt: string | null;
    id?: string;
    profile_picture_url?: string;
    followers_count?: number;
    follows_count?: number;
    media_count?: number;
  }>;
}

export async function grantIgAssistConsent() {
  await api.post("/publish/instagram/consent");
}

export async function getInstagramConnectUrl(): Promise<string> {
  const { data } = await api.post("/auth/instagram/connect-url");
  return data.url;
}

export async function disconnectInstagram(igUserId: string) {
  await api.delete(`/auth/instagram/${igUserId}`);
}
