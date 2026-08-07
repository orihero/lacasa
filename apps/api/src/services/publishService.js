import { ALL_CHANNELS } from "@lacasa/domain";
import { fetchAccountInfo, publishCarousel } from "../lib/instagram.js";
import { sendMediaGroup } from "../lib/telegram.js";
import { logActivityEvent } from "../lib/activity.js";
import { config } from "../lib/config.js";

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
      payload: { mechanism: "graph-api", results },
    },
    update: {
      status: succeeded.length ? "PUBLISHED" : "FAILED",
      externalId: succeeded[0]?.mediaId ?? null,
      attempts: { increment: 1 },
      lastAttemptAt: now,
      publishedAt: succeeded.length ? now : null,
      errorMessage: succeeded.length ? null : results.find((r) => !r.ok)?.error ?? null,
      requestedById: actor.user.id,
      payload: { mechanism: "graph-api", results },
    },
  });

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

  // Checked before any network call -- same reasoning as llm_unconfigured
  // in mapFieldsForChannel, a missing token can't be fixed by retrying. But
  // unlike llm_unconfigured (thrown before any publish attempt exists),
  // this call already represents one, so it must still land in
  // AdPublication or the status grid silently hides that it ever happened.
  if (!config.TG_CONFIGURED) {
    const message = "Telegram bot token is not configured on the server (TG_BOT_TOKEN). Ask an administrator to set it.";
    const results = targets.map((chatId) => ({ chatId, ok: false, error: message }));
    await ctx.prisma.adPublication.upsert({
      where: { adId_channel: { adId, channel: "TELEGRAM" } },
      create: {
        adId,
        channel: "TELEGRAM",
        status: "FAILED",
        attempts: 1,
        lastAttemptAt: now,
        errorMessage: message,
        requestedById: actor.user.id,
        payload: { mechanism: "bot-api", results },
      },
      update: {
        status: "FAILED",
        attempts: { increment: 1 },
        lastAttemptAt: now,
        errorMessage: message,
        requestedById: actor.user.id,
        payload: { mechanism: "bot-api", results },
      },
    });
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
      payload: { mechanism: "bot-api", results },
    },
    update: {
      status: succeeded.length ? "PUBLISHED" : "FAILED",
      externalId: succeeded[0]?.messageId != null ? String(succeeded[0].messageId) : null,
      attempts: { increment: 1 },
      lastAttemptAt: now,
      publishedAt: succeeded.length ? now : null,
      errorMessage: succeeded.length ? null : (results.find((r) => !r.ok)?.error ?? null),
      requestedById: actor.user.id,
      payload: { mechanism: "bot-api", results },
    },
  });

  return { publication: serializePublication(publication), results };
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
