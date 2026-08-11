import { ALL_CHANNELS } from "@lacasa/domain";
import { fetchAccountInfo, publishCarousel } from "../lib/instagram.js";
import { sendMediaGroup } from "../lib/telegram.js";
import { logActivityEvent } from "../lib/activity.js";
import { config } from "../lib/config.js";
import { effectiveAgentId } from "../middleware/roles.js";
import * as pushService from "./pushService.js";

// AdPublication.adId is a plain string, not an FK: the create page can
// cross-post before the ad row exists, so those publications are recorded
// against a client-generated `draft-<uuid>` id and re-keyed onto the real ad
// id by reassignDraft() once the ad is saved.

// Per-channel session/cap config for extension-assisted cross-posting, keyed
// by the lowercase `:channel` route param. `enum` is the matching
// @lacasa/domain PublishChannel value (also Prisma's PublishChannel enum) —
// asserted against ALL_CHANNELS by the drift-contract test in
// publishService.test.js, so a typo here can't silently create publications
// the status grid (which iterates ALL_CHANNELS) never renders.
export const CHANNELS = {
  olx: {
    enum: "OLX",
    sessionStartStep: "category",
    startEvent: "OLX_CROSSPOST_STARTED",
    abortEvent: "OLX_CROSSPOST_ABORTED",
    completeEvent: "OLX_CROSSPOST_COMPLETED",
    dailyCap: config.OLX_DAILY_CAP,
    requiresConsent: false,
  },
  instagram: {
    // "caption" runs exactly once per assisted session (the composer step is
    // usually handled heuristically without an LLM call), so it drives the cap.
    enum: "INSTAGRAM",
    sessionStartStep: "caption",
    startEvent: "IG_ASSIST_STARTED",
    abortEvent: "IG_ASSIST_ABORTED",
    completeEvent: "IG_ASSIST_COMPLETED",
    dailyCap: config.IG_ASSIST_DAILY_CAP,
    requiresConsent: true,
  },
};

function httpError(status, code, message) {
  const err = new Error(message);
  err.status = status;
  err.code = code;
  return err;
}

export function serializePublication(p) {
  return {
    id: p.id,
    adId: p.adId,
    channel: p.channel,
    status: p.status,
    externalId: p.externalId,
    externalUrl: p.externalUrl,
    attempts: p.attempts,
    lastAttemptAt: p.lastAttemptAt,
    publishedAt: p.publishedAt,
    errorMessage: p.errorMessage,
  };
}

export function statusGrid(adId, rows) {
  return ALL_CHANNELS.map((channel) => {
    const row = rows.find((r) => r.adId === adId && r.channel === channel);
    return row
      ? { channel, status: row.status, externalUrl: row.externalUrl, externalId: row.externalId, lastAttemptAt: row.lastAttemptAt, errorMessage: row.errorMessage }
      : { channel, status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null };
  });
}

// ---------------------------------------------------------------------------
// Server-side Instagram publish (token path, mechanism "graph-api")

export async function publishInstagramDirect(ctx, { adId, caption, imageUrls, igUserIds, actor }) {
  const tokens = await ctx.prisma.agentIgToken.findMany({
    where: {
      agentId: actor.agentId,
      ...(igUserIds?.length ? { igUserId: { in: igUserIds } } : {}),
    },
  });
  if (!tokens.length) {
    throw httpError(400, "no_connected_accounts", "No connected Instagram accounts");
  }

  const results = [];
  for (const t of tokens) {
    try {
      const r = await publishCarousel({ igUserId: t.igUserId, token: t.accessToken, imageUrls, caption });
      results.push({ igUserId: t.igUserId, igUsername: t.igUsername, ok: true, mediaId: r.mediaId });
    } catch (e) {
      results.push({ igUserId: t.igUserId, igUsername: t.igUsername, ok: false, error: e.message });
    }
  }

  const succeeded = results.filter((r) => r.ok);
  const now = new Date();
  // `request` is stashed alongside `mechanism`/`results` purely so a later
  // retry (retryPublish, below) has the exact caption/photos/target account
  // list to replay -- without it, retrying a FAILED row would have to guess
  // at what to re-send, which is exactly the "silent double-post from
  // re-deriving slightly different input" risk the retry endpoint exists to
  // avoid. It is never read by this function itself and never surfaces in
  // serializePublication's response shape, so storing it here doesn't change
  // this endpoint's own observable behaviour.
  const requestPayload = { caption, imageUrls, igUserIds: igUserIds ?? null };
  const publication = await ctx.prisma.adPublication.upsert({
    where: { adId_channel: { adId, channel: "INSTAGRAM" } },
    create: {
      adId,
      channel: "INSTAGRAM",
      status: succeeded.length ? "PUBLISHED" : "FAILED",
      externalId: succeeded[0]?.mediaId ?? null,
      attempts: 1,
      lastAttemptAt: now,
      publishedAt: succeeded.length ? now : null,
      errorMessage: succeeded.length ? null : results.find((r) => !r.ok)?.error ?? null,
      requestedById: actor.user.id,
      payload: { mechanism: "graph-api", request: requestPayload, results },
    },
    update: {
      status: succeeded.length ? "PUBLISHED" : "FAILED",
      externalId: succeeded[0]?.mediaId ?? null,
      attempts: { increment: 1 },
      lastAttemptAt: now,
      publishedAt: succeeded.length ? now : null,
      errorMessage: succeeded.length ? null : results.find((r) => !r.ok)?.error ?? null,
      requestedById: actor.user.id,
      payload: { mechanism: "graph-api", request: requestPayload, results },
    },
  });

  // Fire-and-forget: see pushService.js's file-header guarantee -- this can
  // never turn a successful (or already-failed-and-recorded) publish
  // attempt into a 500 the caller didn't cause.
  await pushService.notifyPublishOutcome(ctx, publication);

  return { publication: serializePublication(publication), results };
}

// Connected IG accounts with profile info, fetched server-side so tokens
// never reach the browser.
export async function listInstagramAccounts(ctx, actor) {
  const tokens = await ctx.prisma.agentIgToken.findMany({ where: { agentId: actor.agentId } });
  return Promise.all(
    tokens.map(async (t) => {
      const base = { igUserId: t.igUserId, username: t.igUsername, expiresAt: t.expiresAt };
      try {
        const info = await fetchAccountInfo(t.igUserId, t.accessToken);
        return { ...base, ...info, username: info.username ?? t.igUsername };
      } catch {
        return base;
      }
    }),
  );
}

// ---------------------------------------------------------------------------
// Server-side Telegram publish (token path, mechanism "bot-api")

// AdPublication.adId has no FK to Ad (see the file-header comment above), so
// there is nothing to own-check for a draft id -- reassignDraft() re-keys
// those onto a real ad id later, at which point this check starts applying.
// Shared by publishTelegramDirect and reportYoutubeStatus: both accept a
// caller-supplied adId and both need "may only act on your own ad" enforced
// the same way, unlike publishInstagramDirect (which never takes an
// arbitrary adId belonging to someone else's ad -- it only ever touches the
// caller's own AgentIgToken rows).
async function assertOwnsAd(ctx, adId, actor) {
  if (adId.startsWith("draft-")) return;
  const ad = await ctx.prisma.ad.findUnique({ where: { id: adId }, select: { agentId: true } });
  if (!ad) {
    throw httpError(404, "ad_not_found", "Ad not found");
  }
  if (ad.agentId !== actor.agentId) {
    throw httpError(403, "forbidden", "You may only publish your own ad");
  }
}

export async function publishTelegramDirect(ctx, { adId, caption, imageUrls, chatIds, actor }) {
  await assertOwnsAd(ctx, adId, actor);

  // Unlike Instagram (one AgentIgToken row per connected account, checked
  // against igUserIds), Telegram has no per-agent token table -- the bot
  // token is one global secret (config.TG_BOT_TOKEN) and the *targets* are
  // request-supplied chat ids. Without this check any authenticated agent
  // could point the bot at an arbitrary chat id; User.tgChatIds is the list
  // they're actually allowed to post to.
  //
  // tgChatIds lives on the AGENT's own row, never a coworker's -- same rule
  // auth.js's resolveAgentContext documents ("a coworker's connected IG/TG
  // accounts belong to their agent"). actor.user is req.currentUser, i.e.
  // the *caller's* row, which for a COWORKER is not the agent's row, so it
  // must never be read directly here -- doing so left coworkers unable to
  // ever pass this check (their own tgChatIds is always empty).
  const tgUser = actor.coworkerId
    ? await ctx.prisma.user.findUnique({ where: { id: actor.agentId }, select: { tgChatIds: true } })
    : actor.user;
  const allowed = new Set((tgUser?.tgChatIds ?? []).map((id) => String(id)));
  const targets = [...new Set(chatIds)].filter((id) => allowed.has(id));
  if (!targets.length) {
    throw httpError(400, "no_connected_accounts", "None of the requested chat ids are connected to this account");
  }

  const now = new Date();
  // See publishInstagramDirect's identical comment: stashed only so a later
  // retry can replay this exact caption/photos/chat-id list instead of a
  // freshly re-derived one. Audit-only, never read here, never in the
  // response shape.
  const requestPayload = { caption, imageUrls, chatIds };

  // Checked before any network call -- same reasoning as llm_unconfigured
  // in mapFieldsForChannel, a missing token can't be fixed by retrying. But
  // unlike llm_unconfigured (thrown before any publish attempt exists),
  // this call already represents one, so it must still land in
  // AdPublication or the status grid silently hides that it ever happened.
  if (!config.TG_CONFIGURED) {
    const message = "Telegram bot token is not configured on the server (TG_BOT_TOKEN). Ask an administrator to set it.";
    const results = targets.map((chatId) => ({ chatId, ok: false, error: message }));
    const publication = await ctx.prisma.adPublication.upsert({
      where: { adId_channel: { adId, channel: "TELEGRAM" } },
      create: {
        adId,
        channel: "TELEGRAM",
        status: "FAILED",
        attempts: 1,
        lastAttemptAt: now,
        errorMessage: message,
        requestedById: actor.user.id,
        payload: { mechanism: "bot-api", request: requestPayload, results },
      },
      update: {
        status: "FAILED",
        attempts: { increment: 1 },
        lastAttemptAt: now,
        errorMessage: message,
        requestedById: actor.user.id,
        payload: { mechanism: "bot-api", request: requestPayload, results },
      },
    });
    // This FAILED row is exactly as real a publish outcome as one that
    // failed after actually calling out to Telegram -- see
    // pushService.js's file-header guarantee for why this can't fail the
    // 503 being thrown right after it.
    await pushService.notifyPublishOutcome(ctx, publication);
    throw httpError(503, "tg_unconfigured", message);
  }

  const results = [];
  for (const chatId of targets) {
    try {
      const r = await sendMediaGroup({ chatId, imageUrls, caption });
      results.push({ chatId, ok: true, messageId: r.messageId });
    } catch (e) {
      results.push({ chatId, ok: false, error: e.message });
    }
  }

  const succeeded = results.filter((r) => r.ok);
  const publication = await ctx.prisma.adPublication.upsert({
    where: { adId_channel: { adId, channel: "TELEGRAM" } },
    create: {
      adId,
      channel: "TELEGRAM",
      status: succeeded.length ? "PUBLISHED" : "FAILED",
      externalId: succeeded[0]?.messageId != null ? String(succeeded[0].messageId) : null,
      attempts: 1,
      lastAttemptAt: now,
      publishedAt: succeeded.length ? now : null,
      errorMessage: succeeded.length ? null : (results.find((r) => !r.ok)?.error ?? null),
      requestedById: actor.user.id,
      payload: { mechanism: "bot-api", request: requestPayload, results },
    },
    update: {
      status: succeeded.length ? "PUBLISHED" : "FAILED",
      externalId: succeeded[0]?.messageId != null ? String(succeeded[0].messageId) : null,
      attempts: { increment: 1 },
      lastAttemptAt: now,
      publishedAt: succeeded.length ? now : null,
      errorMessage: succeeded.length ? null : (results.find((r) => !r.ok)?.error ?? null),
      requestedById: actor.user.id,
      payload: { mechanism: "bot-api", request: requestPayload, results },
    },
  });

  await pushService.notifyPublishOutcome(ctx, publication);

  return { publication: serializePublication(publication), results };
}

// ---------------------------------------------------------------------------
// Retry a failed direct-publish attempt.
//
// docs' documented gap this closes: publish-status's Retry button was
// visibly present but permanently disabled because neither
// publishInstagramDirect nor publishTelegramDirect could distinguish
// "re-attempt this exact failed request" from "publish fresh" -- retrying
// with freshly re-derived input risks a silent double-post if the retry
// picks a different photo set/caption/target list than the attempt an agent
// actually reviewed. This function is the dedicated path: it replays the
// exact request stashed in `payload.request` by the two functions above,
// through those same functions, so there is exactly one code path that
// talks to Telegram/Instagram and retry never diverges from it.

// Only channels with a real server-to-server publish call have anything to
// retry. YOUTUBE never had one -- reportYoutubeStatus is a report-back for
// an upload the browser already performed under the user's own Google
// session, so there is no server-side call to redo. OLX goes through the
// browser extension with a human clicking OLX's own Publish button, and
// REALTING is a cron-driven feed sync -- neither has a server-side "attempt"
// this endpoint could repeat. apps/console permanently disables the same
// Retry affordance for the same reason; this map is what finally lets
// Telegram/Instagram diverge from that blanket "disabled" state. Keyed by
// the lowercase :channel route param, same convention CHANNELS above uses.
const RETRYABLE_CHANNELS = { telegram: "TELEGRAM", instagram: "INSTAGRAM" };
const NON_RETRYABLE_REASONS = {
  youtube:
    "YouTube has no server-side publish call to retry -- the browser performs the upload itself under your own Google session. Upload again and report the result.",
  olx: "OLX posting happens through the browser extension with a human reviewing and clicking Publish. Retry the cross-post from the extension instead.",
  realting: "Realting listings sync through a scheduled feed, not a per-ad publish call. There is nothing here to retry.",
};

// The ownership signal retry actually has for a draft- id, closing the hole
// assertOwnsAd's early return leaves open there. Deliberately scoped to the
// draft- case only (the `if` below): for a real adId, assertOwnsAd's
// Ad.agentId check already ran and already proved ownership correctly, and
// this must not layer a second, stricter opinion on top of a check that
// already got the right answer -- see the requestedById-nullability comment
// just below for why that would matter (a departed coworker's old attempt
// could otherwise strand the agent who genuinely owns the ad).
//
// Unlike a fresh direct publish (publishTelegramDirect/publishInstagramDirect),
// which may be the very call that creates the AdPublication row, retry only
// ever runs once that row already exists -- so unlike those callers, retry
// always has `requestedById` (the User who made the attempt being replayed)
// to check against, even for a draft id with no Ad row to check instead.
// effectiveAgentId resolves both sides the same way roles.js resolves it
// everywhere else, so a coworker retrying their own agent's draft still
// passes, exactly like publishTelegramDirect's tgChatIds lookup above does.
async function assertOwnsPublicationRow(ctx, adId, row, actor) {
  if (!adId.startsWith("draft-")) return;

  // requestedById is nullable (`AdPublication.requestedById String? ...
  // onDelete: SetNull` in schema.prisma) -- it goes null when the User who
  // made this attempt is later deleted, not just on legacy rows. For a
  // draft id that leaves zero ownership signal to check, for anyone.
  // Treating "we can't tell" as "let it through" would turn deleting an
  // account into a way to make that account's draft publications retryable
  // by whoever finds the id -- the opposite of what deleting an account
  // should do -- so this fails closed instead: no verifiable requester, no
  // retry.
  if (!row.requestedById) {
    throw httpError(403, "forbidden", "This publish attempt's requester no longer exists; it can no longer be retried.");
  }
  const requester = await ctx.prisma.user.findUnique({
    where: { id: row.requestedById },
    select: { id: true, role: true, agentId: true },
  });
  if (!requester || effectiveAgentId(requester) !== actor.agentId) {
    throw httpError(403, "forbidden", "You may only retry your own publish attempts");
  }
}

export async function retryPublish(ctx, { adId, channelKey, actor }) {
  const channelEnum = RETRYABLE_CHANNELS[channelKey];
  if (!channelEnum) {
    const reason = NON_RETRYABLE_REASONS[channelKey];
    if (reason) throw httpError(400, "not_retryable", reason);
    throw httpError(404, "unknown_channel", "Unknown publish channel");
  }

  // Same ownership rule every other /publish/* route enforces (assertOwnsAd
  // is shared with publishTelegramDirect/reportYoutubeStatus above). Checked
  // explicitly here rather than left to publishTelegramDirect's own internal
  // check, because publishInstagramDirect has no such check at all -- IG
  // scopes purely by the caller's own AgentIgToken rows, never by ad
  // ownership.
  //
  // This is NOT, despite an earlier version of this comment claiming so, a
  // gate that "applies uniformly regardless of which channel-specific
  // function ends up doing the actual work." assertOwnsAd early-returns with
  // no check at all when adId starts with "draft-" (see its own comment) --
  // deliberately, for the *direct-publish* callers, because a draft has no
  // Ad row yet to check ownership against. For retry that early return is a
  // real hole, not a harmless gap: retry is reachable by anyone who knows a
  // draft-<uuid> publication id, not just the agent who created it, so a
  // no-op check here would let any authenticated agent force a retry cycle
  // on someone else's draft -- replaying that tenant's stored request
  // (caption/photos/target chat or IG account) on their connected channel.
  // assertOwnsPublicationRow, below, is what actually closes that gap; this
  // call only still matters for a real (non-draft) adId, where it 404s a
  // missing ad and 403s one the caller doesn't own before any AdPublication
  // row is even read.
  await assertOwnsAd(ctx, adId, actor);

  const row = await ctx.prisma.adPublication.findUnique({ where: { adId_channel: { adId, channel: channelEnum } } });

  // No row, or PENDING, means this channel was never attempted (or was
  // reset) -- that is what the normal publish endpoint is for. Retry only
  // has meaning once there is a recorded failure to retry.
  if (!row || row.status === "PENDING") {
    throw httpError(400, "not_failed", "This channel has not been published yet -- use the normal publish endpoint, not retry.");
  }
  // Retrying a PUBLISHED row is exactly how you get two live posts on the
  // same channel -- the one outcome this whole endpoint exists to prevent.
  if (row.status === "PUBLISHED") {
    throw httpError(409, "already_published", "This ad is already published on this channel; retrying would post it a second time.");
  }
  // DRAFTED_AWAITING_REVIEW means a human may be mid-flight in their own
  // browser tab (OLX's own form, or the IG extension-assisted caption
  // fallback). The server has no signal for "did they already click
  // Publish/Share" -- retrying here risks the exact same double-post as
  // retrying PUBLISHED would, the server just hasn't witnessed the second
  // half yet. (In practice only INSTAGRAM reaches retryPublish at all with
  // this status, since OLX isn't in RETRYABLE_CHANNELS -- kept as a status
  // guard rather than relying solely on the channel allowlist, so this stays
  // correct if a channel's mechanism ever changes.)
  if (row.status === "DRAFTED_AWAITING_REVIEW") {
    throw httpError(409, "awaiting_review", "A human may still be reviewing this draft; the server can't tell whether Publish was already clicked.");
  }

  // row.status === "FAILED" is the only state retryPublish ever acts on
  // past this point.

  // Retrying means replaying the exact request that failed -- re-deriving a
  // fresh caption/photo list here would silently publish something
  // different from what the agent reviewed and originally asked for.
  // publishInstagramDirect/publishTelegramDirect stash it on
  // `payload.request` on every attempt specifically so it exists to be
  // replayed; a FAILED row predating that field has nothing to replay, and
  // guessing at a replacement is exactly the kind of fabricated input this
  // codebase's honesty rule forbids.
  const request = row.payload?.request;
  if (!request) {
    throw httpError(
      409,
      "retry_unavailable",
      "This failed attempt predates retry support and has no stored request to replay -- publish again from the ad instead.",
    );
  }

  // The real ownership gate for a draft- adId (see assertOwnsAd's call
  // above for why that check alone doesn't cover this case). Placed here --
  // after every status/shape check has already decided this row is one
  // retryPublish would actually act on, and right before the claim that
  // starts doing so -- so a non-owner probing a guessed draft-<uuid> id
  // never gets to trigger a real retry cycle. It intentionally still learns
  // the generic not_failed/already_published/awaiting_review/retry_unavailable
  // outcomes first, same as any other caller; none of those reveal anything
  // beyond the row's status class, and none of them cause a retry to
  // actually run.
  await assertOwnsPublicationRow(ctx, adId, row, actor);

  // Concurrency guard against a double-retry. Two taps ~100ms apart both
  // read status === "FAILED" above from independent snapshots -- any design
  // built on "read the status, decide, then write" has a window where both
  // callers decide to proceed, however careful the read. This updateMany
  // instead compiles to a single `UPDATE ad_publications SET status =
  // 'PENDING' WHERE ad_id = $1 AND channel = $2 AND status = 'FAILED'`, and
  // Postgres evaluates that WHERE clause -- and takes the row lock -- at
  // execution time, not at some earlier read time. Whichever request's
  // UPDATE actually commits first is the only one that can still observe
  // status = 'FAILED'; once it commits and its lock releases, the second
  // request's WHERE clause is re-evaluated against the now-'PENDING' row and
  // matches zero rows. The claim *is* the concurrency guard -- no advisory
  // lock or explicit transaction wrapper is needed, because a single UPDATE
  // statement already gets that row-level serialization from Postgres for
  // free, and a read-then-write can't recreate it no matter how tight the
  // window between the read and the write is made.
  const claim = await ctx.prisma.adPublication.updateMany({
    where: { adId, channel: channelEnum, status: "FAILED" },
    data: { status: "PENDING" },
  });
  if (claim.count === 0) {
    throw httpError(409, "retry_in_progress", "Another retry for this channel is already in flight.");
  }

  try {
    return channelKey === "telegram"
      ? await publishTelegramDirect(ctx, { adId, caption: request.caption, imageUrls: request.imageUrls, chatIds: request.chatIds, actor })
      : await publishInstagramDirect(ctx, { adId, caption: request.caption, imageUrls: request.imageUrls, igUserIds: request.igUserIds, actor });
  } catch (e) {
    // publishTelegramDirect/publishInstagramDirect both have a couple of
    // error paths (e.g. no_connected_accounts) that throw *before* ever
    // touching the row -- by design, since those mean "there is nothing to
    // even attempt calling out for." Left alone here, that would strand the
    // row this function just claimed at PENDING forever: not FAILED (so a
    // future retry attempt would 400 as "not_failed" instead of finding
    // anything to retry), not PUBLISHED, just silently stuck looking like an
    // attempt that's perpetually in flight. This is the one place attempts
    // is incremented outside the two publish functions' own upserts, and it
    // is only reached when they didn't get far enough to record anything
    // themselves -- so it can never double-count against their own
    // increment.
    await ctx.prisma.adPublication.updateMany({
      where: { adId, channel: channelEnum, status: "PENDING" },
      data: { status: "FAILED", attempts: { increment: 1 }, lastAttemptAt: new Date(), errorMessage: e.message ?? "Retry failed" },
    });
    throw e;
  }
}

// ---------------------------------------------------------------------------
// YouTube status report-back (no server-side upload -- docs/08 §4: the
// browser uploads under the user's own OAuth and reports the outcome here so
// YOUTUBE shows up in the status grid alongside the other channels).

export async function reportYoutubeStatus(ctx, { adId, status, externalId, externalUrl, errorMessage, actor }) {
  await assertOwnsAd(ctx, adId, actor);

  const now = new Date();
  // externalUrl is validated (ytReportSchema) to already be a real
  // youtube.com/youtu.be watch link when the caller sends one; when they
  // don't, derive it from externalId rather than leaving it null, so a
  // report that only bothered to send the video id still gets a working
  // status-grid link.
  const resolvedUrl = externalUrl ?? (externalId ? `https://www.youtube.com/watch?v=${externalId}` : null);
  const data = {
    status,
    externalId: externalId ?? null,
    externalUrl: resolvedUrl,
    lastAttemptAt: now,
    publishedAt: status === "PUBLISHED" ? now : null,
    errorMessage: status === "FAILED" ? (errorMessage ?? null) : null,
    requestedById: actor.user.id,
    payload: { mechanism: "browser-oauth-report", reportedStatus: status },
  };
  const publication = await ctx.prisma.adPublication.upsert({
    where: { adId_channel: { adId, channel: "YOUTUBE" } },
    create: { adId, channel: "YOUTUBE", attempts: 1, ...data },
    update: { attempts: { increment: 1 }, ...data },
  });

  await pushService.notifyPublishOutcome(ctx, publication);

  return serializePublication(publication);
}

// One-time opt-in for extension-assisted Instagram posting (docs/09 §2.2).
export async function setIgConsent(ctx, userId) {
  const user = await ctx.prisma.user.update({ where: { id: userId }, data: { igAssistConsentAt: new Date() } });
  return user.igAssistConsentAt;
}

// ---------------------------------------------------------------------------
// Extension-assisted publishing (OLX + Instagram fallback)

export async function mapFieldsForChannel(ctx, channelKey, { adId, ad, step, snapshot, actor }) {
  const channel = CHANNELS[channelKey];
  if (!channel) {
    throw httpError(404, "unknown_channel", "Unknown publish channel");
  }

  if (channel.requiresConsent && !actor.user.igAssistConsentAt) {
    throw httpError(403, "consent_required", "Extension-assisted Instagram posting requires a one-time opt-in");
  }

  // Checked before the cap accounting below: a misconfigured server would
  // otherwise burn a daily-cap slot on every attempt that never reached the
  // model, locking the agent out for 24h over a missing env var.
  if (!ctx.llm.configured) {
    throw httpError(
      503,
      "llm_unconfigured",
      "AI field-mapping is not configured on the server (ANTHROPIC_API_KEY is missing). Ask an administrator to set it.",
    );
  }

  // The first call per run marks a session start and drives the per-agent
  // daily cap — enforced server-side so it can't be bypassed by
  // reinstalling the extension (docs/07 §7).
  if (step === channel.sessionStartStep) {
    const since = new Date(Date.now() - 24 * 3600 * 1000);
    const startedToday = await ctx.prisma.activityEvent.count({
      where: { agentId: actor.agentId, type: channel.startEvent, createdAt: { gt: since } },
    });
    if (startedToday >= channel.dailyCap) {
      throw httpError(429, "daily_cap", `Daily limit of ${channel.dailyCap} ${channelKey} cross-posts reached`);
    }
    await logActivityEvent(ctx, channel.startEvent, actor, { meta: { adId, channel: channel.enum } });
  }

  let map;
  try {
    map = await ctx.llm.mapFields({ channel: channelKey, ad, step, snapshot });
  } catch (e) {
    if (e.code === "llm_unconfigured") throw httpError(503, e.code, e.message);
    if (e.code === "llm_refusal" || e.code === "llm_empty") throw httpError(502, e.code, e.message);
    throw e;
  }

  const now = new Date();
  const publication = await ctx.prisma.adPublication.upsert({
    where: { adId_channel: { adId, channel: channel.enum } },
    create: {
      adId,
      channel: channel.enum,
      status: "PENDING",
      attempts: 1,
      lastAttemptAt: now,
      requestedById: actor.user.id,
      payload: { mechanism: "extension-assisted", lastStep: step, fieldMap: map },
    },
    update: {
      attempts: { increment: 1 },
      lastAttemptAt: now,
      requestedById: actor.user.id,
      payload: { mechanism: "extension-assisted", lastStep: step, fieldMap: map },
    },
  });

  return { ...map, publication: serializePublication(publication) };
}

// Status transitions per docs/08 §4: drafted -> DRAFTED_AWAITING_REVIEW,
// published/failed are terminal; aborted/dom-drift are audit-only.
export async function confirmChannelEvent(ctx, channelKey, { adId, event, externalId, externalUrl, errorMessage, actor }) {
  const channel = CHANNELS[channelKey];
  if (!channel) {
    throw httpError(404, "unknown_channel", "Unknown publish channel");
  }

  const now = new Date();
  const statusChange =
    event === "drafted"
      ? { status: "DRAFTED_AWAITING_REVIEW" }
      : event === "published"
        ? { status: "PUBLISHED", publishedAt: now, externalId: externalId ?? null, externalUrl: externalUrl ?? null, errorMessage: null }
        : event === "failed"
          ? { status: "FAILED", errorMessage: errorMessage ?? null }
          : {};

  const publication = await ctx.prisma.adPublication.upsert({
    where: { adId_channel: { adId, channel: channel.enum } },
    create: {
      adId,
      channel: channel.enum,
      requestedById: actor.user.id,
      lastAttemptAt: now,
      payload: { mechanism: "extension-assisted", lastEvent: event },
      ...statusChange,
    },
    update: { lastAttemptAt: now, ...statusChange },
  });

  // Only "drafted"/"published"/"failed" actually set `statusChange.status`
  // (see its definition above) -- "aborted" (and any unrecognised event)
  // leaves the row's existing status untouched, so there is no new outcome
  // to announce and calling notifyPublishOutcome would risk re-pushing a
  // stale PUBLISHED/FAILED result from a *previous* attempt that this event
  // had nothing to do with. notifyPublishOutcome itself additionally no-ops
  // for "drafted" (a non-terminal status) -- this check and that one
  // together are what let every other publishService.js call site call it
  // unconditionally, one line, no duplicated status logic.
  if ("status" in statusChange) {
    await pushService.notifyPublishOutcome(ctx, publication);
  }

  if (event === "published") {
    await logActivityEvent(ctx, channel.completeEvent, actor, { meta: { adId, channel: channel.enum, externalId, externalUrl } });
  } else if (event === "aborted") {
    await logActivityEvent(ctx, channel.abortEvent, actor, { meta: { adId, channel: channel.enum, errorMessage } });
  }

  return serializePublication(publication);
}

// ---------------------------------------------------------------------------
// Draft -> real ad re-keying

export async function reassignDraft(ctx, { fromAdId, toAdId, actor }) {
  // Draft ids are client-generated, so the source must look like one and the
  // rows must belong to the caller — that pair is what keeps this from
  // rewriting anyone else's publication history.
  if (!fromAdId.startsWith("draft-")) {
    throw httpError(400, "not_a_draft", "Only draft publications can be reassigned");
  }

  const rows = await ctx.prisma.adPublication.findMany({
    where: { adId: fromAdId, requestedById: actor.user.id },
  });

  for (const row of rows) {
    const data = {
      status: row.status,
      externalId: row.externalId,
      externalUrl: row.externalUrl,
      payload: row.payload ?? {},
      attempts: row.attempts,
      lastAttemptAt: row.lastAttemptAt,
      publishedAt: row.publishedAt,
      errorMessage: row.errorMessage,
      requestedById: row.requestedById,
    };
    await ctx.prisma.$transaction([
      ctx.prisma.adPublication.upsert({
        where: { adId_channel: { adId: toAdId, channel: row.channel } },
        create: { adId: toAdId, channel: row.channel, ...data },
        update: data,
      }),
      ctx.prisma.adPublication.delete({ where: { id: row.id } }),
    ]);
  }

  return rows.length;
}

// ---------------------------------------------------------------------------
// Publish status

export async function getAdStatus(ctx, adId) {
  const rows = await ctx.prisma.adPublication.findMany({ where: { adId } });
  return { adId, channels: statusGrid(adId, rows) };
}

export async function getStatusBulk(ctx, adIds) {
  if (!adIds.length) return {};
  const rows = await ctx.prisma.adPublication.findMany({ where: { adId: { in: adIds } } });
  const out = {};
  for (const adId of adIds) {
    out[adId] = rows.filter((r) => r.adId === adId).map((r) => ({ channel: r.channel, status: r.status }));
  }
  return out;
}
