// Unifies the publish/cross-post vocabulary that used to be defined
// separately in apps/api/src/routes/publish.js (ALL_CHANNELS, the confirm
// event zod enum) and apps/extension/src/lib/types.ts (ConfirmEvent,
// FieldAction["action"]) — the API and the extension were speaking the same
// wire protocol from two hand-maintained copies.

// Every channel an ad can be published to, in the fixed order the status
// grid (GET /api/publish/ads/:adId/status) renders them.
export const ALL_CHANNELS = ['TELEGRAM', 'INSTAGRAM', 'YOUTUBE', 'OLX', 'REALTING'] as const;
export type Channel = (typeof ALL_CHANNELS)[number];

// The subset of channels the extension can currently autofill.
export const ASSISTED_CHANNELS = ['olx', 'instagram'] as const;
export type AssistedChannel = (typeof ASSISTED_CHANNELS)[number];

// Lifecycle events the extension content script reports back to
// POST /api/publish/:channel/confirm as an ad move through an
// extension-assisted publish (docs/08 §4).
export const CONFIRM_EVENTS = ['drafted', 'published', 'failed', 'aborted', 'dom-drift'] as const;
export type ConfirmEvent = (typeof CONFIRM_EVENTS)[number];

// The DOM actions the extension's field-mapping response can ask the
// content script's executor to perform on a page element.
export const ACTION_KINDS = ['set-value', 'select-option', 'click-radio'] as const;
export type ActionKind = (typeof ACTION_KINDS)[number];
