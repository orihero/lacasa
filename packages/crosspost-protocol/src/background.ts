/**
 * @lacasa/crosspost-protocol/background — the content-script <->
 * service-worker `chrome.runtime.sendMessage` contract. This is the single
 * definition for what used to be the hand-rolled `BgRequest`/`BgResponse`
 * union in apps/extension/src/lib/messaging.ts. Extension messages are
 * JSON-serialized (no structured clone of DOM/Blob objects), so photo bytes
 * travel as base64 — see PhotoPayload in ./messages.
 */
import type { AssistedChannel, ConfirmEventName, CrosspostJob, MapFieldsResponse, PhotoPayload, SnapshotNode } from './messages';

// ---------------------------------------------------------------------------
// Content script -> background actions

export interface CrosspostRequestAction {
  type: 'CROSSPOST_REQUEST';
  job: Omit<CrosspostJob, 'createdAt'>;
}

export interface JobRequestAction {
  type: 'JOB_REQUEST';
}

export interface MapFieldsAction {
  type: 'MAP_FIELDS';
  step: string;
  snapshot: SnapshotNode[];
}

export interface ConfirmAction {
  type: 'CONFIRM';
  event: ConfirmEventName;
  externalId?: string;
  externalUrl?: string;
  errorMessage?: string;
}

export interface FetchPhotosAction {
  type: 'FETCH_PHOTOS';
  urls: string[];
}

export interface JobDoneAction {
  type: 'JOB_DONE';
}

export type BackgroundRequest = CrosspostRequestAction | JobRequestAction | MapFieldsAction | ConfirmAction | FetchPhotosAction | JobDoneAction;

export const BACKGROUND_REQUEST_TYPES = ['CROSSPOST_REQUEST', 'JOB_REQUEST', 'MAP_FIELDS', 'CONFIRM', 'FETCH_PHOTOS', 'JOB_DONE'] as const satisfies readonly BackgroundRequest['type'][];

export type BackgroundRequestType = (typeof BACKGROUND_REQUEST_TYPES)[number];

// ---------------------------------------------------------------------------
// Background -> content script responses. Every action responds through the
// same envelope; `data`'s shape per action is documented (not enforced,
// since chrome.runtime.sendMessage doesn't carry a request/response type
// link) in BackgroundResponseDataMap below.

export type BackgroundResponse<T = unknown> = { ok: true; data: T } | { ok: false; error: string };

export interface BackgroundResponseDataMap {
  CROSSPOST_REQUEST: { started: true };
  JOB_REQUEST: CrosspostJob | null;
  MAP_FIELDS: MapFieldsResponse;
  CONFIRM: { publication: Record<string, unknown> };
  FETCH_PHOTOS: PhotoPayload[];
  JOB_DONE: { ok: true };
}

export const START_URLS: Record<AssistedChannel, string> = {
  OLX: 'https://www.olx.uz/d/add/',
  INSTAGRAM: 'https://www.instagram.com/',
};

// ---------------------------------------------------------------------------
// Type guards — one per action, plus a top-level guard so a listener can
// validate an inbound message before switching on it. Keeping the switch in
// callers exhaustive is the point: adding a BackgroundRequest variant here
// forces every consumer switch to be updated to compile.

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

export function isBackgroundRequest(value: unknown): value is BackgroundRequest {
  return isRecord(value) && typeof value.type === 'string' && (BACKGROUND_REQUEST_TYPES as readonly string[]).includes(value.type);
}

export function isCrosspostRequestAction(msg: BackgroundRequest): msg is CrosspostRequestAction {
  return msg.type === 'CROSSPOST_REQUEST';
}

export function isJobRequestAction(msg: BackgroundRequest): msg is JobRequestAction {
  return msg.type === 'JOB_REQUEST';
}

export function isMapFieldsAction(msg: BackgroundRequest): msg is MapFieldsAction {
  return msg.type === 'MAP_FIELDS';
}

export function isConfirmAction(msg: BackgroundRequest): msg is ConfirmAction {
  return msg.type === 'CONFIRM';
}

export function isFetchPhotosAction(msg: BackgroundRequest): msg is FetchPhotosAction {
  return msg.type === 'FETCH_PHOTOS';
}

export function isJobDoneAction(msg: BackgroundRequest): msg is JobDoneAction {
  return msg.type === 'JOB_DONE';
}

export function isOkResponse<T>(res: BackgroundResponse<T>): res is { ok: true; data: T } {
  return res.ok === true;
}

export function isErrResponse<T>(res: BackgroundResponse<T>): res is { ok: false; error: string } {
  return res.ok === false;
}

// ---------------------------------------------------------------------------
// Action builders

export function buildCrosspostRequestAction(job: Omit<CrosspostJob, 'createdAt'>): CrosspostRequestAction {
  return { type: 'CROSSPOST_REQUEST', job };
}

export function buildJobRequestAction(): JobRequestAction {
  return { type: 'JOB_REQUEST' };
}

export function buildMapFieldsAction(step: string, snapshot: SnapshotNode[]): MapFieldsAction {
  return { type: 'MAP_FIELDS', step, snapshot };
}

export function buildConfirmAction(opts: { event: ConfirmEventName; externalId?: string; externalUrl?: string; errorMessage?: string }): ConfirmAction {
  return { type: 'CONFIRM', ...opts };
}

export function buildFetchPhotosAction(urls: string[]): FetchPhotosAction {
  return { type: 'FETCH_PHOTOS', urls };
}

export function buildJobDoneAction(): JobDoneAction {
  return { type: 'JOB_DONE' };
}

// ---------------------------------------------------------------------------
// Response builders

export function ok<T>(data: T): BackgroundResponse<T> {
  return { ok: true, data };
}

export function err(error: string): BackgroundResponse<never> {
  return { ok: false, error };
}
