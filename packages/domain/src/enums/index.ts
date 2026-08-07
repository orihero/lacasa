/**
 * @lacasa/domain/enums — every wire-format enum shared across apps/web,
 * apps/api, and apps/extension, plus their derived reverse maps.
 *
 * Ported from apps/api/src/lib/enums.js (AD_*, REPAIRMENT, FURNITURE,
 * CURRENCY_CODE, LEAD_STATUS, EVENT_STAGE) and unified with the
 * publish/cross-post vocabulary previously duplicated between
 * apps/api/src/routes/publish.js and apps/extension/src/lib/types.ts
 * (ALL_CHANNELS, ConfirmEvent, ACTION_KINDS) — see ./publish.ts.
 */
export * from './ads';
export * from './leads';
export * from './events';
export * from './publish';
export * from './users';
