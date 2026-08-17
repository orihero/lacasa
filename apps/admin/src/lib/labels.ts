/**
 * src/lib/labels — wire-key -> human label (+ Tag tone) maps for every
 * enum-shaped field the control room displays. Every map is a
 * `Record<SomeKey, X>` keyed off a domain enum's *key* type (UserRoleKey,
 * RealtorStatusKey, …), never a hand-typed string union — adding a member to
 * an enum in @lacasa/domain without updating the matching map here is a
 * compile error, not a blank cell an admin finds while deciding someone's
 * account.
 *
 * TWO MAPS ARE THE EXCEPTION and are hand-maintained against
 * apps/api/prisma/schema.prisma instead, because @lacasa/domain has no key
 * type for either: `PUBLICATION_STATUS_*` (the overview's `publications`
 * block) and `AUDIT_TYPE_*` (ActivityEvent.type). Both are checked against
 * the schema by their own unit test, which is the closest thing to a compile
 * error available for a vocabulary the domain package does not own yet.
 *
 * HOW THE TONES ARE ALLOCATED — this is the rule the whole surface leans on:
 *   · `acc` (amber) means WAITING ON YOU. A pending application, a queue
 *     depth, an unreviewed item. Never decoration; the overview's queue
 *     counts are only scannable because nothing else is amber.
 *   · `danger` (magenta) means CAN DO SOMETHING IRREVERSIBLE. On a button
 *     that is the action itself; on the admin role badge it is the same
 *     warning read from the other direction.
 *   · `ok`/`err` are settled outcomes, `info` is a neutral classification,
 *     `mute` is the absence of one.
 */
import type {
  AdStageKey,
  LeadStatusKey,
  RealtorKindKey,
  RealtorStatusKey,
  TeamSizeKey,
  UserRoleKey,
} from "@lacasa/domain";
import type { Tone } from "@/ui/Tag";

// ---------------------------------------------------------------------------
// User.role. "Buyer" rather than "User" for the `user` key: on this surface
// every row is a user, so the word carries no information — what an admin
// needs to know is that this account browses listings rather than posting
// them. The contract's overview payload counts them as `buyers` for the same
// reason.

export const USER_ROLE_LABEL: Record<UserRoleKey, string> = {
  user: "Buyer",
  agent: "Agent",
  coworker: "Coworker",
  admin: "Admin",
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

export const USER_ROLE_ORDER = Object.keys(USER_ROLE_LABEL) as UserRoleKey[];

// ---------------------------------------------------------------------------
// User.realtorStatus — the application, not the permission. `approved` here
// and `role: "agent"` are two separate facts and this surface must never
// conflate them: approving writes both, but a later role change does not
// rewrite the application history.

export const REALTOR_STATUS_LABEL: Record<RealtorStatusKey, string> = {
  none: "None",
  pending: "Pending",
  approved: "Approved",
  rejected: "Rejected",
};

export const REALTOR_STATUS_TONE: Record<RealtorStatusKey, Tone> = {
  none: "mute",
  pending: "acc",
  approved: "ok",
  rejected: "err",
};

// ---------------------------------------------------------------------------
// User.realtorKind.
//
// The mockup draws Agency in amber and Solo in blue. This deviates: amber is
// spoken for (see the file header), and an agency application is not more
// urgent than a solo one — it is just a different shape. Both render as
// neutral classifications, and the queue's amber stays the count of things
// waiting on an admin.

export const REALTOR_KIND_LABEL: Record<RealtorKindKey, string> = {
  solo: "Solo",
  agency: "Agency",
};

export const REALTOR_KIND_TONE: Record<RealtorKindKey, Tone> = {
  solo: "mute",
  agency: "info",
};

// ---------------------------------------------------------------------------
// User.teamSize — self-reported buckets on an agency application. En dashes
// (not hyphens) in the ranges: these are spans, and the mockup sets them that
// way too ("6–10").

export const TEAM_SIZE_LABEL: Record<TeamSizeKey, string> = {
  just_me: "Just me",
  two_to_five: "2–5",
  six_to_fifteen: "6–15",
  sixteen_plus: "16+",
};

// ---------------------------------------------------------------------------
// Ad.stage — "1" | "2" | "3" on the wire (@lacasa/domain's AD_STAGE), NOT
// "ACTIVE"/"SOLD"/"DRAFT". The overview's `ads` block reports the same three
// buckets under their spelled-out names.

export const AD_STAGE_LABEL: Record<AdStageKey, string> = {
  "1": "Active",
  "2": "Sold",
  "3": "Draft",
};

export const AD_STAGE_TONE: Record<AdStageKey, Tone> = {
  "1": "ok",
  "2": "info",
  "3": "mute",
};

// ---------------------------------------------------------------------------
// Lead.status — the five members of @lacasa/domain's LEAD_STATUS, in the
// order that enum declares them, which doubles as the pipeline order the
// overview's `leads.byStatus` block is read in.

export const LEAD_STATUS_LABEL: Record<LeadStatusKey, string> = {
  new: "New",
  could_not_connect: "Could not connect",
  need_to_call_back: "Need to call back",
  rejected: "Rejected",
  accepted: "Accepted",
};

export const LEAD_STATUS_TONE: Record<LeadStatusKey, Tone> = {
  new: "info",
  could_not_connect: "mute",
  need_to_call_back: "acc",
  rejected: "err",
  accepted: "ok",
};

// Reusing Object.keys on the label map (rather than retyping the five keys)
// keeps the order from drifting out of sync with the labels themselves.
export const LEAD_STATUS_ORDER = Object.keys(LEAD_STATUS_LABEL) as LeadStatusKey[];

// ---------------------------------------------------------------------------
// AdPublication.status — hand-maintained against schema.prisma's
// `PublishStatus` (see the file header for why). The overview's
// `publications` block keys them lowercase, which is what these are.

export const PUBLICATION_STATUS_KEYS = [
  "published",
  "failed",
  "pending",
  "drafted_awaiting_review",
] as const;

export type PublicationStatusKey = (typeof PUBLICATION_STATUS_KEYS)[number];

export const PUBLICATION_STATUS_LABEL: Record<PublicationStatusKey, string> = {
  published: "Published",
  failed: "Failed",
  pending: "Not published",
  drafted_awaiting_review: "Awaiting review",
};

export const PUBLICATION_STATUS_TONE: Record<PublicationStatusKey, Tone> = {
  published: "ok",
  failed: "err",
  pending: "mute",
  // The only publication state that is genuinely waiting on a human.
  drafted_awaiting_review: "acc",
};

// ---------------------------------------------------------------------------
// ActivityEvent.type — the audit log's vocabulary, hand-maintained against
// schema.prisma's `EventType` (11 members) and lowercased the way the rest of
// the wire format is. Labels are `noun.verb` in monospace-friendly form
// rather than prose: the audit screen is a log, and a log is scanned by
// prefix ("everything olx.*"), which sentence-case labels destroy.

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

export const AUDIT_TYPE_LABEL: Record<AuditTypeKey, string> = {
  ad_created: "ad.created",
  ad_sold: "ad.sold",
  ad_draft_updated: "ad.draft_updated",
  lead_created: "lead.created",
  lead_status_changed: "lead.status_changed",
  olx_crosspost_started: "olx.crosspost_started",
  olx_crosspost_completed: "olx.crosspost_completed",
  olx_crosspost_aborted: "olx.crosspost_aborted",
  ig_assist_started: "ig.assist_started",
  ig_assist_completed: "ig.assist_completed",
  ig_assist_aborted: "ig.assist_aborted",
};

/**
 * The log's severity column. There is no severity field on ActivityEvent —
 * these are all successful, already-happened business events — so this maps
 * outcome, not error level: a completed crosspost reads `ok`, an aborted one
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

/**
 * A wire value this build does not know about still has to render as
 * something an admin can read and search for. The API's enum can gain a
 * member before this app is redeployed, and dropping such a row — or showing
 * a blank cell where the action should be — would hide exactly the event a
 * new feature's first incident is about.
 */
export function auditTypeLabel(type: string): string {
  return (AUDIT_TYPE_LABEL as Record<string, string | undefined>)[type] ?? type;
}

export function auditTypeTone(type: string): Tone {
  return (AUDIT_TYPE_TONE as Record<string, Tone | undefined>)[type] ?? "mute";
}
