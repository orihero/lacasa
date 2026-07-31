import { ALL_CHANNELS } from "@lacasa/domain";
import { fetchAccountInfo, publishCarousel } from "../lib/instagram.js";
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
