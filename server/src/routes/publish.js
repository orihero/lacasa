import { Router } from "express";
import { z } from "zod";
import { prisma } from "../lib/prisma.js";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import { effectiveAgentId } from "../middleware/roles.js";
import { mapFields, llmConfigured } from "../lib/llm.js";
import { fetchAccountInfo, publishCarousel } from "../lib/instagram.js";

const router = Router();
router.use(requireAuth, loadCurrentUser);

// AdPublication.adId is a plain string, not an FK: the create page can
// cross-post before the ad row exists, so those publications are recorded
// against a client-generated `draft-<uuid>` id and re-keyed onto the real ad
// id by POST /reassign once the ad is saved.

const CHANNELS = {
  olx: {
    enum: "OLX",
    sessionStartStep: "category",
    startEvent: "OLX_CROSSPOST_STARTED",
    abortEvent: "OLX_CROSSPOST_ABORTED",
    completeEvent: "OLX_CROSSPOST_COMPLETED",
    dailyCap: Number(process.env.OLX_DAILY_CAP ?? 15),
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
    dailyCap: Number(process.env.IG_ASSIST_DAILY_CAP ?? 5),
    requiresConsent: true,
  },
};

// An AGENT publishes under their own id; a COWORKER publishes under their
// agent's, and is additionally recorded as the acting coworker.
function resolveActor(req) {
  const user = req.currentUser;
  const agentId = effectiveAgentId(user);
  if (!agentId) return null;
  return { user, agentId, coworkerId: user.role === "COWORKER" ? user.id : null };
}

function serializePublication(p) {
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

const adSchema = z.object({}).passthrough();

// ---------------------------------------------------------------------------
// Server-side Instagram publish (token path, mechanism "graph-api")

const igPublishSchema = z.object({
  adId: z.string().min(1).max(120),
  caption: z.string().max(2200),
  imageUrls: z.array(z.string().url()).min(1).max(20),
  igUserIds: z.array(z.string()).max(10).optional(),
});

router.post("/instagram", async (req, res, next) => {
  try {
    const parsed = igPublishSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const actor = resolveActor(req);
    if (!actor) {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents and coworkers can publish" } });
    }
    const { adId, caption, imageUrls, igUserIds } = parsed.data;

    const tokens = await prisma.agentIgToken.findMany({
      where: {
        agentId: actor.agentId,
        ...(igUserIds?.length ? { igUserId: { in: igUserIds } } : {}),
      },
    });
    if (!tokens.length) {
      return res.status(400).json({ error: { code: "no_connected_accounts", message: "No connected Instagram accounts" } });
    }

    const results = [];
    for (const t of tokens) {
      try {
        const r = await publishCarousel({
          igUserId: t.igUserId,
          token: t.accessToken,
          imageUrls,
          caption,
        });
        results.push({ igUserId: t.igUserId, igUsername: t.igUsername, ok: true, mediaId: r.mediaId });
      } catch (e) {
        results.push({ igUserId: t.igUserId, igUsername: t.igUsername, ok: false, error: e.message });
      }
    }

    const succeeded = results.filter((r) => r.ok);
    const now = new Date();
    const publication = await prisma.adPublication.upsert({
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

    res.json({ publication: serializePublication(publication), results });
  } catch (e) {
    next(e);
  }
});

// Connected IG accounts with profile info, fetched server-side so tokens
// never reach the browser.
router.get("/instagram/accounts", async (req, res, next) => {
  try {
    const actor = resolveActor(req);
    if (!actor) {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents and coworkers have Instagram accounts" } });
    }
    const tokens = await prisma.agentIgToken.findMany({ where: { agentId: actor.agentId } });
    const accounts = await Promise.all(
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
    res.json({ accounts });
  } catch (e) {
    next(e);
  }
});

// One-time opt-in for extension-assisted Instagram posting (docs/09 §2.2).
router.post("/instagram/consent", async (req, res, next) => {
  try {
    const user = await prisma.user.update({
      where: { id: req.auth.sub },
      data: { igAssistConsentAt: new Date() },
    });
    res.json({ ok: true, igAssistConsentAt: user.igAssistConsentAt });
  } catch (e) {
    next(e);
  }
});

// ---------------------------------------------------------------------------
// Extension-assisted publishing (OLX + Instagram fallback)

const mapFieldsSchema = z.object({
  adId: z.string().min(1).max(120),
  ad: adSchema,
  step: z.string().min(1).max(40),
  snapshot: z.array(z.any()).min(1).max(250),
});

router.post("/:channel/map-fields", async (req, res, next) => {
  try {
    const channel = CHANNELS[req.params.channel];
    if (!channel) {
      return res.status(404).json({ error: { code: "unknown_channel", message: "Unknown publish channel" } });
    }
    const parsed = mapFieldsSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const actor = resolveActor(req);
    if (!actor) {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents and coworkers can publish" } });
    }
    const { adId, ad, step, snapshot } = parsed.data;

    if (channel.requiresConsent && !actor.user.igAssistConsentAt) {
      return res.status(403).json({ error: { code: "consent_required", message: "Extension-assisted Instagram posting requires a one-time opt-in" } });
    }

    // Checked before the cap accounting below: a misconfigured server would
    // otherwise burn a daily-cap slot on every attempt that never reached the
    // model, locking the agent out for 24h over a missing env var.
    if (!llmConfigured) {
      return res.status(503).json({
        error: {
          code: "llm_unconfigured",
          message: "AI field-mapping is not configured on the server (ANTHROPIC_API_KEY is missing). Ask an administrator to set it.",
        },
      });
    }

    // The first call per run marks a session start and drives the per-agent
    // daily cap — enforced server-side so it can't be bypassed by
    // reinstalling the extension (docs/07 §7).
    if (step === channel.sessionStartStep) {
      const since = new Date(Date.now() - 24 * 3600 * 1000);
      const startedToday = await prisma.activityEvent.count({
        where: { agentId: actor.agentId, type: channel.startEvent, createdAt: { gt: since } },
      });
      if (startedToday >= channel.dailyCap) {
        return res.status(429).json({ error: { code: "daily_cap", message: `Daily limit of ${channel.dailyCap} ${req.params.channel} cross-posts reached` } });
      }
      await prisma.activityEvent.create({
        data: {
          type: channel.startEvent,
          agentId: actor.agentId,
          coworkerId: actor.coworkerId,
          meta: { adId, channel: channel.enum },
        },
      });
    }

    const map = await mapFields({ channel: req.params.channel, ad, step, snapshot });

    const now = new Date();
    const publication = await prisma.adPublication.upsert({
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

    res.json({ ...map, publication: serializePublication(publication) });
  } catch (e) {
    if (e.code === "llm_unconfigured") {
      return res.status(503).json({ error: { code: e.code, message: e.message } });
    }
    if (e.code === "llm_refusal" || e.code === "llm_empty") {
      return res.status(502).json({ error: { code: e.code, message: e.message } });
    }
    next(e);
  }
});

const confirmSchema = z.object({
  adId: z.string().min(1).max(120),
  event: z.enum(["drafted", "published", "failed", "aborted", "dom-drift"]),
  externalId: z.string().max(200).optional(),
  externalUrl: z.string().url().max(500).optional(),
  errorMessage: z.string().max(1000).optional(),
});

router.post("/:channel/confirm", async (req, res, next) => {
  try {
    const channel = CHANNELS[req.params.channel];
    if (!channel) {
      return res.status(404).json({ error: { code: "unknown_channel", message: "Unknown publish channel" } });
    }
    const parsed = confirmSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const actor = resolveActor(req);
    if (!actor) {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents and coworkers can publish" } });
    }
    const { adId, event, externalId, externalUrl, errorMessage } = parsed.data;

    const now = new Date();
    // Status transitions per docs/08 §4: drafted -> DRAFTED_AWAITING_REVIEW,
    // published/failed are terminal; aborted/dom-drift are audit-only.
    const statusChange =
      event === "drafted"
        ? { status: "DRAFTED_AWAITING_REVIEW" }
        : event === "published"
          ? { status: "PUBLISHED", publishedAt: now, externalId: externalId ?? null, externalUrl: externalUrl ?? null, errorMessage: null }
          : event === "failed"
            ? { status: "FAILED", errorMessage: errorMessage ?? null }
            : {};

    const publication = await prisma.adPublication.upsert({
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
      await prisma.activityEvent.create({
        data: {
          type: channel.completeEvent,
          agentId: actor.agentId,
          coworkerId: actor.coworkerId,
          meta: { adId, channel: channel.enum, externalId, externalUrl },
        },
      });
    } else if (event === "aborted") {
      await prisma.activityEvent.create({
        data: {
          type: channel.abortEvent,
          agentId: actor.agentId,
          coworkerId: actor.coworkerId,
          meta: { adId, channel: channel.enum, errorMessage },
        },
      });
    }

    res.json({ publication: serializePublication(publication) });
  } catch (e) {
    next(e);
  }
});

// ---------------------------------------------------------------------------
// Draft → real ad re-keying

const reassignSchema = z.object({
  fromAdId: z.string().min(1).max(120),
  toAdId: z.string().min(1).max(120),
});

router.post("/reassign", async (req, res, next) => {
  try {
    const parsed = reassignSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const actor = resolveActor(req);
    if (!actor) {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents and coworkers can publish" } });
    }
    const { fromAdId, toAdId } = parsed.data;
    // Draft ids are client-generated, so the source must look like one and the
    // rows must belong to the caller — that pair is what keeps this from
    // rewriting anyone else's publication history.
    if (!fromAdId.startsWith("draft-")) {
      return res.status(400).json({ error: { code: "not_a_draft", message: "Only draft publications can be reassigned" } });
    }
    const rows = await prisma.adPublication.findMany({
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
      await prisma.$transaction([
        prisma.adPublication.upsert({
          where: { adId_channel: { adId: toAdId, channel: row.channel } },
          create: { adId: toAdId, channel: row.channel, ...data },
          update: data,
        }),
        prisma.adPublication.delete({ where: { id: row.id } }),
      ]);
    }

    res.json({ moved: rows.length });
  } catch (e) {
    next(e);
  }
});

// ---------------------------------------------------------------------------
// Publish status

const ALL_CHANNELS = ["TELEGRAM", "INSTAGRAM", "YOUTUBE", "OLX", "REALTING"];

function statusGrid(adId, rows) {
  return ALL_CHANNELS.map((channel) => {
    const row = rows.find((r) => r.adId === adId && r.channel === channel);
    return row
      ? { channel, status: row.status, externalUrl: row.externalUrl, externalId: row.externalId, lastAttemptAt: row.lastAttemptAt, errorMessage: row.errorMessage }
      : { channel, status: "PENDING", externalUrl: null, externalId: null, lastAttemptAt: null, errorMessage: null };
  });
}

router.get("/ads/:adId/status", async (req, res, next) => {
  try {
    const rows = await prisma.adPublication.findMany({ where: { adId: req.params.adId } });
    res.json({ adId: req.params.adId, channels: statusGrid(req.params.adId, rows) });
  } catch (e) {
    next(e);
  }
});

router.get("/status", async (req, res, next) => {
  try {
    const adIds = String(req.query.adIds ?? "").split(",").filter(Boolean).slice(0, 200);
    if (!adIds.length) return res.json({});
    const rows = await prisma.adPublication.findMany({ where: { adId: { in: adIds } } });
    const out = {};
    for (const adId of adIds) {
      out[adId] = rows
        .filter((r) => r.adId === adId)
        .map((r) => ({ channel: r.channel, status: r.status }));
    }
    res.json(out);
  } catch (e) {
    next(e);
  }
});

export default router;
