import { invert } from './invert';

// Legacy Firestore `statistics.stage` numeric codes — the frontend's
// statistics store/Chart component still filter on these numbers, so the
// wire values are preserved verbatim rather than renumbered.
export const EVENT_STAGE = {
  AD_CREATED: 1,
  AD_SOLD: 2,
  AD_DRAFT_UPDATED: 3,
  LEAD_CREATED: 4,
  LEAD_STATUS_CHANGED: 5,
} as const;

export type EventStageKey = keyof typeof EVENT_STAGE;

export const EVENT_STAGE_REV = invert(EVENT_STAGE);
