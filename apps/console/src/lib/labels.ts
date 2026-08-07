/**
 * src/lib/labels — wire-key -> human label (+ Tag tone) maps for every
 * enum-shaped field the console displays. Every map here is a
 * `Record<SomeKey, X>` keyed off a domain enum's *key* type (AdStageKey,
 * LeadStatusKey, …), never a hand-typed string union — adding a member to
 * the enum in @lacasa/domain without updating the matching map here is a
 * compile error, not a blank cell an agent finds in production.
 *
 * Two maps below (PUBLISH_STATUS_* / PUBLISH_CHANNEL_LABEL) are the
 * exception: `AdPublication.status`/`.channel` are the raw Postgres enum
 * values verbatim on the wire (see apps/api/src/services/publishService.js's
 * serializePublication — no lowercase REV map, unlike Ad.stage/Lead.status).
 * @lacasa/domain has no key type for `.status`, so PUBLISH_STATUS_KEYS is
 * hand-maintained here against the schema's `PublishStatus` enum; `Channel`
 * does exist (@lacasa/domain/enums's ALL_CHANNELS) and PUBLISH_CHANNEL_LABEL
 * is keyed off it the same way the Ad/Lead maps are.
 */
import {
  ALL_CHANNELS,
  type AdCategoryKey,
  type AdStageKey,
  type Channel,
  type FurnitureKey,
  type LeadStatusKey,
  type RepairmentKey,
} from '@lacasa/domain';
import type { Tone } from '@/ui/Tag';

// ---------------------------------------------------------------------------
// Ad.stage — "1" | "2" | "3" (see the CRITICAL WIRE-FORMAT FACT in the build
// brief; these are NOT "ACTIVE"/"SOLD"/"DRAFT").

export const AD_STAGE_LABEL: Record<AdStageKey, string> = {
  '1': 'Active',
  '2': 'Sold',
  '3': 'Draft',
};

export const AD_STAGE_TONE: Record<AdStageKey, Tone> = {
  '1': 'ok',
  '2': 'info',
  '3': 'warn',
};

// ---------------------------------------------------------------------------
// Ad.category

export const AD_CATEGORY_LABEL: Record<AdCategoryKey, string> = {
  rent: 'Rent',
  sale: 'Sale',
};

// ---------------------------------------------------------------------------
// Ad.repairment / Ad.furniture — real Prisma enum strings, not the old
// prototype's drifted "Euro"/"Furnished" (PLAN.md §4).

export const REPAIRMENT_LABEL: Record<RepairmentKey, string> = {
  notRepaired: 'Not repaired',
  normal: 'Normal',
  good: 'Good',
  excellent: 'Excellent',
};

export const FURNITURE_LABEL: Record<FurnitureKey, string> = {
  withFurniture: 'With furniture',
  withoutFurniture: 'Without furniture',
};

// ---------------------------------------------------------------------------
// Lead.status — five members today. LeadStatusKey has no `success` key: the
// Kanban's 6th column and the Coworkers "Closed" metric both depend on a
// `SUCCESS` LeadStatus that does not exist in Prisma yet (PLAN.md §4,
// Decision 6.4) — screens must Flag that gap, never invent a 6th entry here.

export const LEAD_STATUS_LABEL: Record<LeadStatusKey, string> = {
  new: 'New',
  could_not_connect: 'Could not connect',
  need_to_call_back: 'Need to call back',
  rejected: 'Rejected',
  accepted: 'Accepted',
};

export const LEAD_STATUS_TONE: Record<LeadStatusKey, Tone> = {
  new: 'info',
  could_not_connect: 'mute',
  need_to_call_back: 'warn',
  rejected: 'err',
  accepted: 'ok',
};

// The Kanban column order (New -> Could not connect -> Need to call back ->
// Rejected -> Accepted) is the same order LEAD_STATUS's own keys are
// declared in @lacasa/domain/enums/leads.ts, which doubles as the ordered
// column set per that file's own comment — reusing `Object.keys` on the
// label map (rather than retyping the five keys a third time) keeps this
// from silently drifting out of sync with LEAD_STATUS_LABEL's key set.
export const LEAD_STATUS_ORDER = Object.keys(LEAD_STATUS_LABEL) as LeadStatusKey[];

// ---------------------------------------------------------------------------
// AdPublication.channel — apps/api/prisma/schema.prisma's PublishChannel
// enum, unchanged on the wire (@lacasa/domain/enums's ALL_CHANNELS / Channel).

export const PUBLISH_CHANNEL_LABEL: Record<Channel, string> = {
  TELEGRAM: 'Telegram',
  INSTAGRAM: 'Instagram',
  YOUTUBE: 'YouTube',
  OLX: 'OLX',
  REALTING: 'Realting',
};

export const PUBLISH_CHANNEL_ORDER: readonly Channel[] = ALL_CHANNELS;

// ---------------------------------------------------------------------------
// AdPublication.status — apps/api/prisma/schema.prisma's PublishStatus enum
// (PENDING / DRAFTED_AWAITING_REVIEW / PUBLISHED / FAILED), sent verbatim —
// see the file comment above for why this isn't keyed off a domain type.

export const PUBLISH_STATUS_KEYS = ['PENDING', 'DRAFTED_AWAITING_REVIEW', 'PUBLISHED', 'FAILED'] as const;
export type PublishStatusKey = (typeof PUBLISH_STATUS_KEYS)[number];

export const PUBLISH_STATUS_LABEL: Record<PublishStatusKey, string> = {
  PENDING: 'Not published',
  DRAFTED_AWAITING_REVIEW: 'Awaiting review',
  PUBLISHED: 'Published',
  FAILED: 'Failed',
};

export const PUBLISH_STATUS_TONE: Record<PublishStatusKey, Tone> = {
  PENDING: 'mute',
  DRAFTED_AWAITING_REVIEW: 'warn',
  PUBLISHED: 'ok',
  FAILED: 'err',
};
