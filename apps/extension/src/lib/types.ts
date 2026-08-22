// apps/extension's contract types — sourced from @lacasa/crosspost-protocol,
// which now owns the field-map vocabulary (FieldAction, MapFieldsResponse,
// FieldNode, CategoryStepNode, SnapshotNode, PhotoPayload) and the confirm
// event enum previously hand-duplicated here.
//
// CASING NOTE (deliberate deviation): @lacasa/crosspost-protocol's
// AssistedChannel is typed against @lacasa/domain's ALL_CHANNELS —
// 'OLX' | 'INSTAGRAM', the DB-enum casing — per that package's own
// handoff/reconciliation notes. The actual wire format this extension speaks
// is still lowercase: apps/web/src/services/crosspost.ts's CrosspostChannel
// ("olx" | "instagram") is what puts a channel on the postMessage bridge, and
// apps/api/src/routes/publish.js's CHANNELS map keys its /publish/:channel/*
// routes on the same lowercase strings. Neither of those trees has migrated
// onto @lacasa/crosspost-protocol yet, so adopting AssistedChannel's casing
// here verbatim would silently break the OLX/Instagram autofill flow (wrong
// route segment, and the job.channel checks in content/olx-autofill.ts and
// content/instagram-autofill.ts would never match). `Channel` derives from
// AssistedChannel via `Lowercase<...>` so it keeps tracking the package's
// channel set, and `CrosspostJob` below overrides just the `channel` field's
// casing to match what actually crosses the wire today. Revisit this file
// when apps/web + apps/api adopt the package's casing — AssistedChannel may
// become authoritative end to end and this override can be deleted.
import type {
  AssistedChannel,
  ConfirmEventName,
  FieldAction,
  UnresolvedField,
  MapFieldsResponse,
  FieldNode,
  CategoryStepNode,
  SnapshotNode,
  PhotoPayload,
} from "@lacasa/crosspost-protocol";

export type Channel = Lowercase<AssistedChannel>;

// Ads still live in Firestore, so the web app sends the full listing payload
// with the trigger message instead of the extension fetching it by id.
export interface CrosspostJob {
  channel: Channel;
  adId: string;
  ad: Record<string, unknown>;
  photoUrls: string[];
  token: string;
  apiBase: string;
  createdAt: number;
}

export type ConfirmEvent = ConfirmEventName;

export type { FieldAction, UnresolvedField, MapFieldsResponse, FieldNode, CategoryStepNode, SnapshotNode, PhotoPayload };
