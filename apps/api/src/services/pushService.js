// Server-side push-notification plumbing: device registration + delivery.
//
// -----------------------------------------------------------------------
// Scope: plumbing only, deliberately.
// -----------------------------------------------------------------------
// This slice builds the device-token table, the register/unregister routes,
// and a send path wired into this app's real trigger points -- but there is
// no Flutter code anywhere that calls POST /api/push/devices, no
// POST_NOTIFICATIONS permission declared, and permission_gateway.dart's
// short-circuit is untouched. Putting a permission prompt in front of a user
// for a capability that cannot yet deliver a single message is exactly what
// that gateway's existing stubs already refuse to do (same reasoning as
// docs/09's other not-yet-wired capabilities) -- this slice does not get to
// skip that just because the server side is now real. sendPushToUser below
// degrades to a logged no-op until FCM_SERVER_KEY is set (lib/config.js),
// which today it never is.
//
// -----------------------------------------------------------------------
// The "never fails the triggering write" guarantee.
// -----------------------------------------------------------------------
// Every exported function below that *sends* (sendPushToUser,
// notifyForActivityEvent, notifyPublishOutcome) is written to never throw
// and never reject, on purpose: they are invoked as a side effect of a
// write that has either already committed or is about to answer its caller
// (a lead being created, an ad being marked sold, a Telegram/Instagram
// publish attempt being recorded) — see lib/activity.js and
// publishService.js for the call sites. A push-provider outage, a
// malformed/expired device token, FCM_SERVER_KEY being unset, or a bug in
// this file's own lookup logic must never turn a successful lead creation
// or ad publish into a 500 the caller didn't cause and can't fix. Every
// failure path here is caught and logged instead of propagated -- see
// test/services/pushService.test.js for that guarantee under test.
//
// -----------------------------------------------------------------------
// Reusing notificationService.js's copy, not duplicating it.
// -----------------------------------------------------------------------
// buildLeadNotification/buildSoldNotification/buildCoworkerNotification/
// buildPublishNotification (imported below) already build the exact title
// string GET /api/notifications renders for these same four event kinds.
// Building a second, slightly-different string here for the push banner
// would let the pull feed and a push notification drift apart over time
// (docs/22's fused "headline — detail" copy would silently diverge). Instead
// this file re-fetches just enough relation data to call those same
// builders and reuses their output verbatim as the push body, so there is
// exactly one place that decides what a lead/sold/coworker/publish event is
// called.

import { config } from "../lib/config.js";
import { sendFcmPush } from "../lib/push.js";
import * as deviceTokenRepository from "../repositories/deviceTokenRepository.js";
import {
  buildLeadNotification,
  buildSoldNotification,
  buildCoworkerNotification,
  buildPublishNotification,
} from "./notificationService.js";

// Wire values the register/unregister routes accept -> the Prisma enum.
// Lowercase to match this app's other wire-vs-column conventions (e.g.
// AD_TYPE in @lacasa/domain/enums), kept local rather than promoted into
// that shared package since no other app reads/writes this table yet.
export const PLATFORM = { ios: "IOS", android: "ANDROID" };

// ---------------------------------------------------------------------------
// Device registration

// Idempotent: re-registering the same (userId, token) pair is the same
// fact, not an error -- see DeviceToken's @@unique in prisma/schema.prisma
// and deviceTokenRepository.js#upsertDeviceToken.
export async function registerDevice(ctx, userId, { token, platform }) {
  await deviceTokenRepository.upsertDeviceToken(ctx.prisma, userId, token, PLATFORM[platform]);
}

// Always succeeds. Unregistering a device that was never registered (or was
// already unregistered) leaves the caller in exactly the state they asked
// for, same reasoning as savedAdService.js#unsaveAd.
export async function unregisterDevice(ctx, userId, token) {
  await deviceTokenRepository.deleteDeviceToken(ctx.prisma, userId, token);
}

// ---------------------------------------------------------------------------
// Delivery

// The only function in this file that ever attempts to actually deliver a
// push. See this file's header comment for the "never throws" guarantee --
// every branch below returns a `{ sent, skipped }` result describing what
// happened instead of raising.
export async function sendPushToUser(ctx, userId, { title, body, targetId }) {
  try {
    if (!config.PUSH_CONFIGURED) {
      // Same "optional integration degrades to a clean, logged no-op"
      // contract as TG_CONFIGURED/LLM_CONFIGURED (config.js, app.js's
      // `if (!llm.configured)` warning) -- visible in the server log, never
      // surfaced to a caller as a failure.
      console.log(`[push] FCM_SERVER_KEY is not set — skipping push to user ${userId}: "${title}"`);
      return { sent: 0, skipped: "unconfigured" };
    }

    const tokens = await deviceTokenRepository.findDeviceTokensForUser(ctx.prisma, userId);
    if (!tokens.length) {
      return { sent: 0, skipped: "no_devices" };
    }

    // allSettled, not Promise.all: one device with a stale/expired token
    // must not stop delivery to that same user's other devices.
    const results = await Promise.allSettled(
      tokens.map((t) => sendFcmPush({ token: t.token, title, body, data: targetId ? { targetId } : undefined })),
    );
    let sent = 0;
    results.forEach((r, i) => {
      if (r.status === "fulfilled") {
        sent += 1;
      } else {
        console.error(`[push] delivery failed for device ${tokens[i].id}:`, r.reason?.message ?? r.reason);
      }
    });
    return { sent, skipped: null };
  } catch (e) {
    // Belt-and-suspenders: even a bug in the lookup above (an unexpected
    // Prisma error, a bad ctx.prisma stub in a test) must not escape this
    // function -- see the guarantee documented at the top of this file.
    console.error("[push] sendPushToUser failed unexpectedly:", e);
    return { sent: 0, skipped: "error" };
  }
}

// Display title shown above each push's body -- a short, static label per
// notification kind (the kinds notificationService.js's feed already
// defines), never itself describing a specific lead/ad/coworker. The
// specific, honest detail ("New lead: Jane Buyer") is exactly the string
// buildXNotification already produces, carried through unchanged as the
// push body below -- see this file's header comment on why that has to be
// reused rather than re-derived.
const KIND_TITLE = {
  lead: "New lead",
  sold: "Listing sold",
  coworkerActivity: "Coworker activity",
  publish: "Publish update",
};

// The real-time counterpart to GET /api/notifications: fired from
// lib/activity.js's logActivityEvent choke point on every ActivityEvent
// write, so it stays wired for any future model that starts logging
// through that same function without a second call site to remember.
//
// Only four EventType values have a corresponding notification kind
// (notificationService.js's own header explains why) -- everything else
// (the OLX/IG cross-post session start/complete/abort bookkeeping events)
// has no honest push copy to show and is silently skipped, not pushed with
// a placeholder.
//
// `event` is the freshly-created ActivityEvent row as returned by
// `ctx.prisma.activityEvent.create()` -- ids only, no relations loaded (see
// lib/activity.js). The relation each branch needs is fetched here rather
// than requiring every call site to eagerly include it, since this is the
// one place that needs it and it only runs as a best-effort side effect,
// never on the request's hot path in a way that can fail it.
export async function notifyForActivityEvent(ctx, event) {
  try {
    // Checked before any relation lookup below, not just inside
    // sendPushToUser: when no provider is configured (true for every
    // environment today) there is nothing this function could usefully do
    // with a freshly-fetched lead/ad/coworker row, so skip fetching one at
    // all rather than spend a query per ActivityEvent write on a lookup
    // whose only consumer is about to no-op anyway.
    if (!config.PUSH_CONFIGURED) return;

    let notification;

    if (event.type === "LEAD_CREATED" || event.type === "LEAD_STATUS_CHANGED") {
      if (!event.leadId) return;
      const lead = await ctx.prisma.lead.findUnique({ where: { id: event.leadId } });
      notification = buildLeadNotification({ ...event, lead });
    } else if (event.type === "AD_SOLD") {
      if (!event.adId) return;
      const ad = await ctx.prisma.ad.findUnique({ where: { id: event.adId } });
      notification = buildSoldNotification({ ...event, ad });
    } else if (event.type === "AD_CREATED" && event.coworkerId) {
      // Agent-authored AD_CREATED is intentionally not pushed either --
      // same "you already know, you just did it" reasoning
      // notificationService.js's header gives for excluding it from the
      // pull feed.
      if (!event.adId) return;
      const [ad, coworker] = await Promise.all([
        ctx.prisma.ad.findUnique({ where: { id: event.adId } }),
        ctx.prisma.user.findUnique({ where: { id: event.coworkerId } }),
      ]);
      notification = buildCoworkerNotification({ ...event, ad, coworker });
    } else {
      return; // not one of the four pushable kinds
    }

    // The builder itself can decline (e.g. the lead/ad was deleted between
    // the write and this best-effort lookup, same SetNull races
    // notificationService.js's builders already guard against) -- nothing
    // honest to push in that case either.
    if (!notification) return;

    await sendPushToUser(ctx, event.agentId, {
      title: KIND_TITLE[notification.kind],
      body: notification.title,
      targetId: notification.targetId,
    });
  } catch (e) {
    console.error("[push] notifyForActivityEvent failed unexpectedly:", e);
  }
}

// The publish-outcome counterpart, fired from publishService.js right after
// every AdPublication upsert (see that file's own call sites). Unlike
// notifyForActivityEvent, this is not reached through logActivityEvent --
// publish outcomes are written directly to AdPublication, never through an
// ActivityEvent row (see publishService.js's file header) -- so it needs
// its own call sites rather than one shared choke point.
export async function notifyPublishOutcome(ctx, publication) {
  try {
    // Same early-out as notifyForActivityEvent above, and for the same
    // reason: no provider configured means no ad lookup is worth doing.
    if (!config.PUSH_CONFIGURED) return;

    // buildPublishNotification only has honest copy for a terminal outcome
    // (see notificationRepository.js#findPublicationsForAdIds, which reads
    // only PUBLISHED/FAILED rows for the same reason) -- PENDING and
    // DRAFTED_AWAITING_REVIEW are mid-flight states with nothing to
    // announce yet. Calling this unconditionally after every upsert and
    // letting it no-op here is what keeps every publishService.js call site
    // a one-line "fire and forget" rather than each re-implementing this
    // status check.
    if (publication.status !== "PUBLISHED" && publication.status !== "FAILED") return;

    // adId has no FK (publishService.js's file header) -- a still-open
    // draft publication (`draft-<uuid>`) has no Ad row yet, and therefore
    // no agentId to notify. Nothing is lost: reassignDraft() re-keys the
    // row onto a real ad once one exists, at which point that ad's own
    // future publish/retry outcome gets its own notifyPublishOutcome call.
    const ad = await ctx.prisma.ad.findUnique({
      where: { id: publication.adId },
      select: { id: true, title: true, agentId: true },
    });
    if (!ad) return;

    const notification = buildPublishNotification(publication, new Map([[ad.id, ad]]));
    if (!notification) return;

    await sendPushToUser(ctx, ad.agentId, {
      title: KIND_TITLE[notification.kind],
      body: notification.title,
      targetId: notification.targetId,
    });
  } catch (e) {
    console.error("[push] notifyPublishOutcome failed unexpectedly:", e);
  }
}
