/**
 * src/lib/labels — wire-key -> i18n key (+ Tag tone) maps for every
 * enum-shaped field the control room displays.
 *
 * TWO STRUCTURAL RULES, both load-bearing:
 *
 * 1. EVERY MAP IS KEYED OFF A DOMAIN ENUM'S *KEY* TYPE (`UserRoleKey`,
 *    `RealtorStatusKey`, …), never a hand-typed string union. Adding a member
 *    to an enum in @lacasa/domain without updating the matching map here is a
 *    COMPILE ERROR, not a blank cell an admin finds while deciding someone's
 *    account. Two maps are the exception and are hand-maintained against
 *    apps/api/prisma/schema.prisma, because @lacasa/domain has no key type for
 *    either — `PUBLICATION_STATUS_*` (schema's `PublishStatus`) and
 *    `AUDIT_TYPE_*` (schema's `EventType`). Both are pinned to the schema by
 *    ./labels.test.ts, which is the closest thing to a compile error available
 *    for a vocabulary the domain package does not own yet.
 *
 * 2. THE MAPS HOLD i18n KEYS, NOT ENGLISH. Labels are user-facing copy and
 *    this app ships in en/ru/uz, so the map's value is the key
 *    (`roleUser`, `auditTypeAdCreated`, …) and the resolver functions below
 *    take the `t` from `useTranslation()`. The four `auditType*` families and
 *    the record-prefix strings are identical in all three locale files ON
 *    PURPOSE — a log is scanned by prefix ("everything olx.*") and translating
 *    `olx.crosspost_aborted` destroys that.
 *
 * AND ONE BEHAVIOURAL RULE: **every lookup falls back to the raw wire value.**
 * The reference was inconsistent here (overview and audit fell back, users and
 * applications rendered an empty Tag); this widens all of them. A value this
 * build does not know about still has to render as something an admin can read
 * and search for — the API's enum can gain a member before this app is
 * redeployed, and a blank cell where a role or an event type should be would
 * hide exactly the row a new feature's first incident is about.
 *
 * HOW THE TONES ARE ALLOCATED — the rule the whole surface leans on:
 *   · `acc` means WAITING ON YOU. A pending application, a queue depth, an
 *     unreviewed item. Never decoration; the overview's queue counts are only
 *     scannable because nothing else uses it.
 *   · `danger` means CAN DO SOMETHING IRREVERSIBLE. On a button that is the
 *     action itself; on the admin role badge it is the same warning read from
 *     the other direction.
 *   · `ok`/`err` are settled outcomes, `info` is a neutral classification,
 *     `mute` is the absence of one.
 */
import type {
  LeadStatusKey,
  RealtorKindKey,
  RealtorStatusKey,
  TeamSizeKey,
  UserRoleKey,
} from "@lacasa/domain";

/**
 * The Tag vocabulary. Declared HERE rather than in `@/ui/Tag` because tone is
 * allocated by the maps below — it is a statement about what a value means, not
 * about how a pill is painted. `@/ui/Tag` imports (or re-exports) this type;
 * it must not declare a second one.
 */
export type Tone = "ok" | "acc" | "err" | "info" | "mute" | "danger";

/**
 * The narrowest thing every resolver needs out of react-i18next: `t`.
 * Structural rather than `TFunction` so a caller can pass a stub in a test
 * without constructing an i18next instance.
 */
export type Translate = (key: string) => string;

/**
 * The shared shape of every resolver below: look the wire value up in a
 * key map, translate it if it is known, and hand back the RAW VALUE if it is
 * not. Nothing on this surface may render blank because a vocabulary grew.
 */
function resolveLabel(
  keys: Record<string, string | undefined>,
  t: Translate,
  value: string | null | undefined,
): string {
  if (!value) return "";
  const key = keys[value];
  return key ? t(key) : value;
}

function resolveTone(tones: Record<string, Tone | undefined>, value: string | null | undefined): Tone {
  if (!value) return "mute";
  return tones[value] ?? "mute";
}

// ---------------------------------------------------------------------------
// User.role. "Buyer" rather than "User" for the `user` key: on this surface
// every row is a user, so the word carries no information — what an admin
// needs to know is that this account browses listings rather than posting
// them. (The overview payload counts them as `buyers` for the same reason.)

export const USER_ROLE_LABEL_KEY: Record<UserRoleKey, string> = {
  user: "roleUser",
  agent: "roleAgent",
  coworker: "roleCoworker",
  admin: "roleAdmin",
};

/**
 * Grouped by POWER, not by alphabet: `mute` for an account with no scope over
 * anyone, `info` for the two roles that act inside one agent's data, and
 * `danger` for the one role that acts across everybody's. An admin scanning
 * the users table is looking for exactly that last group.
 */
export const USER_ROLE_TONE: Record<UserRoleKey, Tone> = {
  user: "mute",
  agent: "info",
  coworker: "info",
  admin: "danger",
};

/** Derived from the label map so the order cannot drift from the labels. */
export const USER_ROLE_ORDER = Object.keys(USER_ROLE_LABEL_KEY) as UserRoleKey[];

export function userRoleLabel(t: Translate, role: string | null | undefined): string {
  return resolveLabel(USER_ROLE_LABEL_KEY, t, role);
}

export function userRoleTone(role: string | null | undefined): Tone {
  return resolveTone(USER_ROLE_TONE, role);
}

// ---------------------------------------------------------------------------
// User.realtorStatus — THE APPLICATION, NOT THE PERMISSION. `approved` here
// and `role: "agent"` are two separate facts and this surface must never
// conflate them: approving writes both, but a later role change does not
// rewrite the application history.

export const REALTOR_STATUS_LABEL_KEY: Record<RealtorStatusKey, string> = {
  none: "realtorStatusNone",
  pending: "realtorStatusPending",
  approved: "realtorStatusApproved",
  rejected: "realtorStatusRejected",
};

export const REALTOR_STATUS_TONE: Record<RealtorStatusKey, Tone> = {
  none: "mute",
  pending: "acc",
  approved: "ok",
  rejected: "err",
};

export const REALTOR_STATUS_ORDER = Object.keys(REALTOR_STATUS_LABEL_KEY) as RealtorStatusKey[];

export function realtorStatusLabel(t: Translate, status: string | null | undefined): string {
  return resolveLabel(REALTOR_STATUS_LABEL_KEY, t, status);
}

export function realtorStatusTone(status: string | null | undefined): Tone {
  return resolveTone(REALTOR_STATUS_TONE, status);
}

// ---------------------------------------------------------------------------
// User.realtorKind.
//
// Both render as neutral classifications, which is a deliberate deviation from
// the mockup's amber Agency: amber is spoken for (see the file header), and an
// agency application is not more URGENT than a solo one — it is just a
// different shape. The queue's amber stays the count of things waiting on an
// admin.

export const REALTOR_KIND_LABEL_KEY: Record<RealtorKindKey, string> = {
  solo: "realtorKindSolo",
  agency: "realtorKindAgency",
};

export const REALTOR_KIND_TONE: Record<RealtorKindKey, Tone> = {
  solo: "mute",
  agency: "info",
};

export function realtorKindLabel(t: Translate, kind: string | null | undefined): string {
  return resolveLabel(REALTOR_KIND_LABEL_KEY, t, kind);
}

export function realtorKindTone(kind: string | null | undefined): Tone {
  return resolveTone(REALTOR_KIND_TONE, kind);
}

// ---------------------------------------------------------------------------
// User.teamSize — self-reported buckets on an agency application. The locale
// files spell the ranges with EN DASHES (U+2013), not hyphens: these are
// spans. No tone map — team size is a fact about a company, not a state.

export const TEAM_SIZE_LABEL_KEY: Record<TeamSizeKey, string> = {
  just_me: "teamSizeJustMe",
  two_to_five: "teamSizeTwoToFive",
  six_to_fifteen: "teamSizeSixToFifteen",
  sixteen_plus: "teamSizeSixteenPlus",
};

export function teamSizeLabel(t: Translate, size: string | null | undefined): string {
  return resolveLabel(TEAM_SIZE_LABEL_KEY, t, size);
}

// ---------------------------------------------------------------------------
// Lead.status — the five members of @lacasa/domain's LEAD_STATUS, in the order
// that enum declares them, which doubles as the pipeline order the overview's
// `leads.byStatus` block is read in.
//
// No tone map: lead status renders as plain text inside the overview's counts
// breakdown, never as a Tag, so a tone map here would be dead code that
// invites someone to start colouring a second amber.

export const LEAD_STATUS_LABEL_KEY: Record<LeadStatusKey, string> = {
  new: "leadStatusNew",
  could_not_connect: "leadStatusCouldNotConnect",
  need_to_call_back: "leadStatusNeedToCallBack",
  rejected: "leadStatusRejected",
  accepted: "leadStatusAccepted",
};

/** Derived rather than retyped, so order cannot drift from the labels. */
export const LEAD_STATUS_ORDER = Object.keys(LEAD_STATUS_LABEL_KEY) as LeadStatusKey[];

export function leadStatusLabel(t: Translate, status: string | null | undefined): string {
  return resolveLabel(LEAD_STATUS_LABEL_KEY, t, status);
}

// ---------------------------------------------------------------------------
// AdPublication.status — hand-maintained against schema.prisma's
// `PublishStatus` (see the file header), lowercased the way the overview's
// `publications` block keys them. Pinned to the schema by ./labels.test.ts.
//
// No tone map: publication status renders as plain text inside the counts
// breakdown, never as a Tag.

export const PUBLICATION_STATUS_KEYS = [
  "published",
  "failed",
  "pending",
  "drafted_awaiting_review",
] as const;

export type PublicationStatusKey = (typeof PUBLICATION_STATUS_KEYS)[number];

export const PUBLICATION_STATUS_LABEL_KEY: Record<PublicationStatusKey, string> = {
  published: "publicationStatusPublished",
  failed: "publicationStatusFailed",
  // "Not published", not "Pending": on a screen that also has a pending
  // APPLICATIONS queue, a second "Pending" that means "nobody ever tried"
  // reads as a second queue waiting on someone.
  pending: "publicationStatusPending",
  drafted_awaiting_review: "publicationStatusDraftedAwaitingReview",
};

export function publicationStatusLabel(t: Translate, status: string | null | undefined): string {
  return resolveLabel(PUBLICATION_STATUS_LABEL_KEY, t, status);
}

// ---------------------------------------------------------------------------
// ActivityEvent.type — the audit log's vocabulary, hand-maintained against
// schema.prisma's `EventType` (11 members) and lowercased the way the rest of
// the wire format is. Pinned to the schema by ./labels.test.ts.
//
// The labels themselves are `noun.verb` in monospace-friendly form rather than
// prose, and are IDENTICAL IN ALL THREE LOCALES on purpose: the audit screen
// is a log, and a log is scanned by prefix ("everything olx.*"), which
// sentence-case — or translated — labels destroy.

export const AUDIT_TYPE_KEYS = [
  "ad_created",
  "ad_sold",
  "ad_draft_updated",
  "lead_created",
  "lead_status_changed",
  "olx_crosspost_started",
  "olx_crosspost_completed",
  "olx_crosspost_aborted",
  "ig_assist_started",
  "ig_assist_completed",
  "ig_assist_aborted",
] as const;

export type AuditTypeKey = (typeof AUDIT_TYPE_KEYS)[number];

export const AUDIT_TYPE_LABEL_KEY: Record<AuditTypeKey, string> = {
  ad_created: "auditTypeAdCreated",
  ad_sold: "auditTypeAdSold",
  ad_draft_updated: "auditTypeAdDraftUpdated",
  lead_created: "auditTypeLeadCreated",
  lead_status_changed: "auditTypeLeadStatusChanged",
  olx_crosspost_started: "auditTypeOlxCrosspostStarted",
  olx_crosspost_completed: "auditTypeOlxCrosspostCompleted",
  olx_crosspost_aborted: "auditTypeOlxCrosspostAborted",
  ig_assist_started: "auditTypeIgAssistStarted",
  ig_assist_completed: "auditTypeIgAssistCompleted",
  ig_assist_aborted: "auditTypeIgAssistAborted",
};

/**
 * The log's colour column. THERE IS NO SEVERITY FIELD on ActivityEvent —
 * these are all successful, already-happened business events — so this maps
 * OUTCOME, not error level: a completed crosspost reads `ok`, an ABORTED one
 * reads `err` (something a person started and did not finish is the row worth
 * finding), and everything else is a neutral `info` record.
 */
export const AUDIT_TYPE_TONE: Record<AuditTypeKey, Tone> = {
  ad_created: "info",
  ad_sold: "ok",
  ad_draft_updated: "info",
  lead_created: "info",
  lead_status_changed: "info",
  olx_crosspost_started: "info",
  olx_crosspost_completed: "ok",
  olx_crosspost_aborted: "err",
  ig_assist_started: "info",
  ig_assist_completed: "ok",
  ig_assist_aborted: "err",
};

export function auditTypeLabel(t: Translate, type: string | null | undefined): string {
  return resolveLabel(AUDIT_TYPE_LABEL_KEY, t, type);
}

export function auditTypeTone(type: string | null | undefined): Tone {
  return resolveTone(AUDIT_TYPE_TONE, type);
}
