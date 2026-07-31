// apps/extension's chrome.runtime + window.postMessage wire types — sourced
// from @lacasa/crosspost-protocol's message/background contracts wherever
// the shapes agree with what actually crosses the wire today. See
// ./types.ts's CASING NOTE for why the one field that disagrees (`channel`)
// is overridden back to lowercase here too, and why CrosspostRequestAction
// (the only BackgroundRequest variant that embeds a channel, via job) is
// redefined locally instead of reused from the package as-is.
import { PAGE_SOURCE, EXT_SOURCE } from "@lacasa/crosspost-protocol";
import type {
  CrosspostPingMessage,
  CrosspostRequestMessage,
  JobRequestAction,
  MapFieldsAction,
  ConfirmAction,
  FetchPhotosAction,
  JobDoneAction,
  BackgroundResponse,
} from "@lacasa/crosspost-protocol";
import type { Channel, CrosspostJob, MapFieldsResponse, PhotoPayload } from "./types";

// Page <-> bridge (window.postMessage)
export { PAGE_SOURCE, EXT_SOURCE };

export type PagePing = CrosspostPingMessage;

export interface PageCrosspostRequest extends Omit<CrosspostRequestMessage, "channel"> {
  channel: Channel;
}

// Bridge/content <-> background (chrome.runtime.sendMessage). Extension
// messages are JSON-serialized, so photo bytes travel as base64.
export interface CrosspostRequestAction {
  type: "CROSSPOST_REQUEST";
  job: Omit<CrosspostJob, "createdAt">;
}

export type BgRequest = CrosspostRequestAction | JobRequestAction | MapFieldsAction | ConfirmAction | FetchPhotosAction | JobDoneAction;

export type BgResponse<T = unknown> = BackgroundResponse<T>;

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
