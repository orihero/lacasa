import type { Channel, ConfirmEvent, CrosspostJob, MapFieldsResponse, PhotoPayload, SnapshotNode } from "./types";

// Page <-> bridge (window.postMessage)
export const PAGE_SOURCE = "lacasa-app";
export const EXT_SOURCE = "lacasa-ext";

export interface PageCrosspostRequest {
  source: typeof PAGE_SOURCE;
  type: "CROSSPOST_REQUEST";
  channel: Channel;
  adId: string;
  ad: Record<string, unknown>;
  photoUrls: string[];
  token: string;
  apiBase: string;
  requestId: string;
}

export interface PagePing {
  source: typeof PAGE_SOURCE;
  type: "CROSSPOST_PING";
  id: string;
}

// Bridge/content <-> background (chrome.runtime.sendMessage). Extension
// messages are JSON-serialized, so photo bytes travel as base64.
export type BgRequest =
  | { type: "CROSSPOST_REQUEST"; job: Omit<CrosspostJob, "createdAt"> }
  | { type: "JOB_REQUEST" }
  | { type: "MAP_FIELDS"; step: string; snapshot: SnapshotNode[] }
  | { type: "CONFIRM"; event: ConfirmEvent; externalId?: string; externalUrl?: string; errorMessage?: string }
  | { type: "FETCH_PHOTOS"; urls: string[] }
  | { type: "JOB_DONE" };

export type BgResponse<T = unknown> = { ok: true; data: T } | { ok: false; error: string };

export function sendToBackground<T = unknown>(msg: BgRequest): Promise<BgResponse<T>> {
  return new Promise((resolve) => {
    chrome.runtime.sendMessage(msg, (response) => {
      if (chrome.runtime.lastError) {
        resolve({ ok: false, error: chrome.runtime.lastError.message ?? "extension messaging error" });
      } else {
        resolve(response ?? { ok: false, error: "no response from background" });
      }
    });
  });
}

export type MapFieldsResult = MapFieldsResponse;
export type PhotosResult = PhotoPayload[];
