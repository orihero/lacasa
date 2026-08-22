// Notifications for `notifications` (mockups/SCREENS.md §22,
// apps/mobile_flutter/WORK_TAB_CONTRACT.md §7.11).
//
// -----------------------------------------------------------------------
// Why this is DERIVED, never stored.
// -----------------------------------------------------------------------
// There is no `Notification` table and this slice must not add one (the
// schema slice that ran alongside this one deliberately didn't either --
// nothing anywhere writes into a notification feed as its own side effect).
// Instead this feed is read straight off data that already has to exist for
// other reasons: leads, ad lifecycle events, coworker activity, and publish
// outcomes. That means there is no write path to get out of sync with
// reality, no notification can outlive the row it describes, and "did this
// really happen" is always answerable by looking at the source row.
//
// -----------------------------------------------------------------------
// The deterministic-id problem, and why it's the central design decision.
// -----------------------------------------------------------------------
// A derived feed has no id column of its own to hand out -- every "row" here
// is assembled fresh on every GET from whatever ActivityEvent/AdPublication
// rows currently match. If the id were minted per-request (e.g.
// `crypto.randomUUID()` at serialization time), the exact same underlying
// event would get a *different* notification id on every poll, which quietly
// breaks two things a client legitimately wants to do with an id: (a) dedupe
// against what it already rendered last poll, and (b) eventually mark a
// specific notification read/seen once there's somewhere to persist that
// (see the read-state section below). So every id here is built by
// concatenating the source model's own stable primary key(s) with a fixed
// prefix naming which source produced it:
//   - lead events:      `lead:<leadId>:<activityEventId>`
//   - sold events:       `sold:<adId>:<activityEventId>`
//   - coworker events:   `coworker:<coworkerId>:<activityEventId>`
//   - publish outcomes:  `publish:<adId>:<channel>:<epochSecondsOfLastAttempt>`
// The first three are trivially stable: ActivityEvent rows are
// insert-only (nothing in this codebase updates or deletes one), so its `id`
// column alone is already a permanent, collision-free key -- the extra
// `<leadId>`/`<adId>`/`<coworkerId>` segment is redundant for uniqueness but
// makes the id self-describing in logs/DevTools without a lookup. Publish
// outcomes are different: AdPublication is upserted in place on every retry
// (see publishService.js), so its own `id` column survives a retry but its
// *content* doesn't -- a FAILED->PUBLISHED transition on the same row would
// be invisible if keyed on `id` alone. Folding the last-attempt timestamp
// into the id means a retry that actually changes the outcome mints a new
// notification id (correct: it's new information), while polling the same
// unchanged row twice reproduces the exact same id both times (also
// correct: nothing new happened, so nothing should appear to "re-arrive").
//
// -----------------------------------------------------------------------
// Read state: no persistence, by design.
// -----------------------------------------------------------------------
// There is nowhere to durably store "agent X has read up to timestamp T" --
// no per-user settings table exists in this schema, and adding one is
// explicitly out of scope for this slice (adding a notifications table was
// already ruled out above for the feed itself; a *read-state* table would
// face the identical objection: it's a write path this slice isn't chartered
// to add). Inventing an in-memory or fake version of that would be worse
// than not having it -- a value that looks like real persistence but resets
// on every restart / isn't shared across app instances is exactly the kind
// of fabricated affordance the project's honesty rule forbids.
//
// The honest version of "read state" this slice CAN offer: the caller
// already knows the wall-clock time they last looked at this screen, so
// `GET /api/notifications?since=<ISO8601>` accepts that as a query param and
// computes `unread` client-relative (`unread = createdAt > since`) on every
// request, with no server-side memory of it at all. Two consequences worth
// being explicit about: (1) there is no `POST /api/notifications/read`
// route -- persisting "read" server-side would need exactly one of a)
// `User.notificationsReadAt DateTime?` column (simplest: this feed only
// ever needed one global watermark per agent, never a per-notification
// read/unread), or b) a proper per-notification read-state join table
// (needed only if per-row read/unread, not just a watermark, ever becomes a
// real product requirement) -- either is a schema change, which is
// deliberately out of scope here. (2) when `since` is omitted, `unread`
// defaults to `true` for every row: absent any boundary, the server has no
// basis to claim anything has been seen, and defaulting to "read" would be
// the fabrication this rule exists to prevent.
//
// -----------------------------------------------------------------------
// Why AD_CREATED only becomes a notification when coworker-authored.
// -----------------------------------------------------------------------
// ActivityEvent.AD_CREATED fires for every ad, whether the agent made it
// themselves or a coworker did (Lead/adService.js#createWithActivityEvent
// logs it unconditionally). Surfacing "you created a listing" back to the
// same person who just clicked Create in the same session tells them
// nothing they don't already know -- the create-listing flow's own success
// toast already covered that. What IS worth surfacing is a coworker doing it
// on the agent's behalf, which is why AD_CREATED is only read here when
// `coworkerId` is set, and folded into the `coworkerActivity` kind rather
// than a separate "ad created" kind -- this mirrors the precedent already
// set by the Flutter app's own best-effort live repository
// (lib/features/work_misc/data/live_notifications_repository.dart), which
// made the identical call for the identical reason.
//
// AD_SOLD, by contrast, is surfaced regardless of actor: a sale is
// significant business news for the agent even when they marked it sold
// themselves (SCREENS.md §4.4's own seed row for this kind carries no actor
// distinction either), so it isn't gated on `coworkerId` the way AD_CREATED
// is.
//
// -----------------------------------------------------------------------
// Publish outcomes: this backend can do better than the Flutter client's
// best-effort synthesis.
// -----------------------------------------------------------------------
// live_notifications_repository.dart's own header comment explains why it
// never synthesizes a `publish` notification: the only endpoint it has
// (`GET /publish/status`, `PublishResource.statusForAds`) deliberately omits
// `lastAttemptAt` on its bulk-status rows, leaving no timestamp to rank a
// publish outcome against everything else in the feed. That limitation is
// specific to that endpoint's trimmed wire shape, not to the underlying
// data -- server-side, `AdPublication.lastAttemptAt`/`updatedAt` are real
// columns on the row this service reads directly, so `publish` is fully
// synthesizable here and is the one kind the Flutter client's own attempt
// couldn't honestly produce.

import * as notificationRepository from "../repositories/notificationRepository.js";
import { LEAD_STATUS_REV } from "../lib/enums.js";

export const DEFAULT_LIMIT = 50;
export const MAX_LIMIT = 200;

// UI-only display labels for the title strings this service builds (matches
// SCREENS.md §4.4's fused "headline — detail" copy style). Not a wire enum
// like PUBLISH_CHANNEL_REV would be -- `channel` itself is still returned
// nowhere in this feed's response shape, only baked into the title text, so
// there is nothing here for a client to parse back out.
const CHANNEL_LABEL = {
  TELEGRAM: "Telegram",
  INSTAGRAM: "Instagram",
  YOUTUBE: "YouTube",
  OLX: "OLX",
};

function epochSeconds(date) {
  return Math.floor(new Date(date).getTime() / 1000);
}

// The four functions below are exported (in addition to being used by
// listNotifications, below) so pushService.js can build the exact same
// title copy for a real-time push as this module builds for the pull feed
// -- see pushService.js's header comment on why that reuse, rather than a
// second copy of this logic, is the whole point.
export function buildLeadNotification(event) {
  // Lead.onDelete is SetNull on this FK -- a deleted lead leaves the
  // ActivityEvent row behind with `lead: null`. There is no honest title to
  // render for a lead that no longer exists, so the event is dropped rather
  // than rendered with a blank/placeholder name.
  if (!event.lead) return null;
  const title =
    event.type === "LEAD_CREATED"
      ? `New lead: ${event.lead.fullName}`
      : `Lead updated: ${event.lead.fullName} is now ${LEAD_STATUS_REV[event.lead.status] ?? event.lead.status}`;
  return {
    id: `lead:${event.leadId}:${event.id}`,
    kind: "lead",
    title,
    targetId: event.leadId,
    timestamp: event.createdAt,
  };
}

export function buildSoldNotification(event) {
  // Same SetNull reasoning as buildLeadNotification: a deleted ad leaves
  // `ad: null` behind on this event.
  if (!event.ad) return null;
  return {
    id: `sold:${event.adId}:${event.id}`,
    kind: "sold",
    title: `Listing sold — ${event.ad.title} marked as Sold`,
    targetId: event.adId,
    timestamp: event.createdAt,
  };
}

export function buildCoworkerNotification(event) {
  // `coworker` should always resolve here (the repository query already
  // filters `coworkerId: { not: null }`, and User.onDelete for this FK is
  // SetNull -- if the coworker row were gone, `coworkerId` itself would have
  // been nulled and the query wouldn't have matched this row at all), but
  // `ad` can still be null if the ad itself was deleted since. Guard both
  // rather than assume.
  if (!event.ad || !event.coworker) return null;
  return {
    id: `coworker:${event.coworkerId}:${event.id}`,
    kind: "coworkerActivity",
    title: `Coworker added a new listing — ${event.coworker.fullName} created ${event.ad.title}`,
    targetId: event.coworkerId,
    timestamp: event.createdAt,
  };
}

export function buildPublishNotification(row, adsById) {
  const ad = adsById.get(row.adId);
  const channelLabel = CHANNEL_LABEL[row.channel] ?? row.channel;
  // `ad` is absent when the publication targets a still-open draft id
  // (`draft-<uuid>`, see publishService.js's file-header comment) or an ad
  // this query didn't fetch for some other reason -- render a title without
  // the listing name rather than fabricate one.
  const title =
    row.status === "PUBLISHED"
      ? ad
        ? `${channelLabel} post published — ${ad.title} is now live on ${channelLabel}`
        : `${channelLabel} post published`
      : ad
        ? `${channelLabel} publish failed — ${ad.title}`
        : `${channelLabel} publish failed`;
  // lastAttemptAt is set on every attempt (success or failure); updatedAt is
  // the fallback for the one theoretical case a row has neither (shouldn't
  // happen given the upsert always sets it, but a fallback costs nothing).
  const timestamp = row.lastAttemptAt ?? row.updatedAt;
  return {
    id: `publish:${row.adId}:${row.channel}:${epochSeconds(timestamp)}`,
    kind: "publish",
    title,
    targetId: row.adId,
    timestamp,
  };
}

function computeUnread(timestamp, since) {
  // No boundary at all -> the server has no basis to claim anything has
  // been seen (see this file's header comment on read-state honesty).
  if (!since) return true;
  return new Date(timestamp).getTime() > since.getTime();
}

// Returns the merged, newest-first feed for `agentId`, each row already
// serialized to the wire shape (`id`/`kind`/`title`/`createdAt`/`unread`/
// `targetId`) -- see this file's header comment for what each field means
// and why. `since`, if given, is a `Date`; `limit` is clamped to
// [1, MAX_LIMIT] by the caller (route), not here, so this function can be
// unit-tested with an already-valid limit.
export async function listNotifications(ctx, { agentId, since = null, limit = DEFAULT_LIMIT }) {
  const [leadEvents, soldEvents, coworkerEvents, agentAds] = await Promise.all([
    notificationRepository.findLeadActivityEvents(ctx.prisma, agentId),
    notificationRepository.findAdSoldEvents(ctx.prisma, agentId),
    notificationRepository.findCoworkerAdCreatedEvents(ctx.prisma, agentId),
    notificationRepository.findAgentAds(ctx.prisma, agentId),
  ]);

  const adsById = new Map(agentAds.map((ad) => [ad.id, ad]));
  const publications = await notificationRepository.findPublicationsForAdIds(ctx.prisma, [...adsById.keys()]);

  const items = [
    ...leadEvents.map(buildLeadNotification),
    ...soldEvents.map(buildSoldNotification),
    ...coworkerEvents.map(buildCoworkerNotification),
    ...publications.map((row) => buildPublishNotification(row, adsById)),
  ].filter(Boolean);

  items.sort((a, b) => new Date(b.timestamp).getTime() - new Date(a.timestamp).getTime());

  return items.slice(0, limit).map(({ timestamp, ...rest }) => ({
    ...rest,
    createdAt: { seconds: epochSeconds(timestamp) },
    unread: computeUnread(timestamp, since),
  }));
}
