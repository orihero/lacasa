/**
 * @lacasa/crosspost-protocol/messages — the web app <-> browser extension
 * `window.postMessage` contract, plus the field-map vocabulary shared by
 * every hop of a cross-post (web -> extension -> background -> server and
 * back). This is the single definition for what used to be hand-duplicated
 * across apps/web/src/services/crosspost.ts, apps/extension/src/lib/types.ts
 * and apps/extension/src/lib/messaging.ts. See docs/07 §2 and docs/09.
 *
 * NOTE: ALL_CHANNELS / ACTION_KINDS / CONFIRM_EVENTS are expected from
 * @lacasa/domain/enums (still a placeholder module at the time this file was
 * written — see the package's return value / handoff notes for the
 * reconciliation this depends on).
 */
import { ALL_CHANNELS, ACTION_KINDS, CONFIRM_EVENTS } from '@lacasa/domain/enums';

// ---------------------------------------------------------------------------
// Channel / action-kind / confirm-event vocabulary (re-exported from domain)

export type ChannelName = (typeof ALL_CHANNELS)[number];
export type ActionKind = (typeof ACTION_KINDS)[number];
export type ConfirmEventName = (typeof CONFIRM_EVENTS)[number];

/**
 * Channels the browser extension can actually drive end to end today (OLX,
 * and Instagram as a fallback to the server-side Graph API path). A strict
 * subset of @lacasa/domain's ALL_CHANNELS — narrowed here, not redefined.
 */
export const ASSISTED_CHANNELS = ['OLX', 'INSTAGRAM'] as const satisfies readonly ChannelName[];

export type AssistedChannel = (typeof ASSISTED_CHANNELS)[number];

export function isAssistedChannel(value: unknown): value is AssistedChannel {
  return typeof value === 'string' && (ASSISTED_CHANNELS as readonly string[]).includes(value);
}

// ---------------------------------------------------------------------------
// postMessage origin tags

export const PAGE_SOURCE = 'lacasa-app';
export const EXT_SOURCE = 'lacasa-ext';

// ---------------------------------------------------------------------------
// Field-map shapes — produced by POST /publish/:channel/map-fields, carried
// content-script -> background -> web (and, one level down, DOM-applied by
// the content script). Defined once here; src/background.ts reuses them.

export interface FieldAction {
  ref: string;
  action: ActionKind;
  value: string;
  confidence: number;
}

export interface UnresolvedField {
  ref: string;
  reason: string;
  suggestedAdField?: string | null;
}

export interface MapFieldsResponse {
  categoryClick: { ref: string; label: string } | null;
  fields: FieldAction[];
  unresolved: UnresolvedField[];
  confidence: number;
}

export interface FieldNode {
  ref: string;
  tag: string;
  role?: string;
  type?: string;
  name?: string;
  id?: string;
  label?: string;
  placeholder?: string;
  value?: string;
  options?: string[];
  required?: boolean;
  path: number[];
}

export interface CategoryStepNode {
  ref: string;
  kind: 'category-step';
  level: number;
  options: { ref: string; label: string }[];
}

export type SnapshotNode = FieldNode | CategoryStepNode;

export interface PhotoPayload {
  b64: string;
  mime: string;
  filename: string;
}

// ---------------------------------------------------------------------------
// The job handed from the page to the extension, and on into background
// storage. `createdAt` is stamped by the background worker, not the page —
// see CrosspostRequestMessage below, which omits it.

export interface CrosspostJob {
  channel: AssistedChannel;
  adId: string;
  ad: Record<string, unknown>;
  photoUrls: string[];
  token: string;
  apiBase: string;
  createdAt: number;
}

// ---------------------------------------------------------------------------
// Page -> extension (content-script bridge) request envelopes

export interface CrosspostRequestMessage {
  source: typeof PAGE_SOURCE;
  type: 'CROSSPOST_REQUEST';
  requestId: string;
  channel: AssistedChannel;
  adId: string;
  ad: Record<string, unknown>;
  photoUrls: string[];
  token: string;
  apiBase: string;
}

export interface CrosspostPingMessage {
  source: typeof PAGE_SOURCE;
  type: 'CROSSPOST_PING';
  id: string;
}

export type PageMessage = CrosspostRequestMessage | CrosspostPingMessage;

// ---------------------------------------------------------------------------
// Extension -> page response envelopes

export interface CrosspostPongMessage {
  source: typeof EXT_SOURCE;
  type: 'CROSSPOST_PONG';
  id: string;
}

export interface CrosspostResultMessage {
  source: typeof EXT_SOURCE;
  type: 'CROSSPOST_RESULT';
  requestId: string;
  ok: boolean;
  error?: string;
}

export type ExtensionMessage = CrosspostPongMessage | CrosspostResultMessage;

/** Every shape that can cross the page <-> extension postMessage boundary. */
export type PostMessageEnvelope = PageMessage | ExtensionMessage;

// ---------------------------------------------------------------------------
// Type guards — narrow `MessageEvent["data"]` (typed `unknown` at the
// listener boundary) down to a discriminated envelope. Each one is a single
// runtime check so a consumer `switch (msg.type)` stays exhaustively
// checkable against PageMessage / ExtensionMessage.

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === 'object' && value !== null;
}

export function isPageMessage(data: unknown): data is PageMessage {
  return isRecord(data) && data.source === PAGE_SOURCE && (data.type === 'CROSSPOST_REQUEST' || data.type === 'CROSSPOST_PING');
}

export function isExtensionMessage(data: unknown): data is ExtensionMessage {
  return isRecord(data) && data.source === EXT_SOURCE && (data.type === 'CROSSPOST_PONG' || data.type === 'CROSSPOST_RESULT');
}

export function isCrosspostRequestMessage(data: unknown): data is CrosspostRequestMessage {
  return isPageMessage(data) && data.type === 'CROSSPOST_REQUEST';
}

export function isCrosspostPingMessage(data: unknown): data is CrosspostPingMessage {
  return isPageMessage(data) && data.type === 'CROSSPOST_PING';
}

export function isCrosspostPongMessage(data: unknown): data is CrosspostPongMessage {
  return isExtensionMessage(data) && data.type === 'CROSSPOST_PONG';
}

export function isCrosspostResultMessage(data: unknown): data is CrosspostResultMessage {
  return isExtensionMessage(data) && data.type === 'CROSSPOST_RESULT';
}

// ---------------------------------------------------------------------------
// Envelope builders — the only place literal `source`/`type` tags get typed
// in, so callers can't typo a channel string past the AssistedChannel type.

export function buildCrosspostRequestMessage(opts: {
  requestId: string;
  channel: AssistedChannel;
  adId: string;
  ad: Record<string, unknown>;
  photoUrls: string[];
  token: string;
  apiBase: string;
}): CrosspostRequestMessage {
  return { source: PAGE_SOURCE, type: 'CROSSPOST_REQUEST', ...opts };
}

export function buildCrosspostPingMessage(id: string): CrosspostPingMessage {
  return { source: PAGE_SOURCE, type: 'CROSSPOST_PING', id };
}

export function buildCrosspostPongMessage(id: string): CrosspostPongMessage {
  return { source: EXT_SOURCE, type: 'CROSSPOST_PONG', id };
}

export function buildCrosspostResultMessage(opts: { requestId: string; ok: boolean; error?: string }): CrosspostResultMessage {
  return { source: EXT_SOURCE, type: 'CROSSPOST_RESULT', ...opts };
}
