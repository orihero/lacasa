import { Router } from "express";
import { igPublishSchema, mapFieldsSchema, confirmSchema, reassignSchema, tgPublishSchema, ytReportSchema } from "@lacasa/domain";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import { actorFields } from "../middleware/roles.js";
import * as publishService from "../services/publishService.js";

const router = Router();
router.use(requireAuth, loadCurrentUser);

// Any httpError thrown by publishService (see its `status`/`code`) maps
// straight to the matching HTTP response; anything else falls through to
// the app's generic error middleware.
function handleServiceError(e, res, next) {
  if (e.status) {
    return res.status(e.status).json({ error: { code: e.code, message: e.message } });
  }
  next(e);
}

router.post("/instagram", async (req, res, next) => {
  try {
    const parsed = igPublishSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const actor = actorFields(req.currentUser);
    if (!actor) {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents and coworkers can publish" } });
    }
    const result = await publishService.publishInstagramDirect(req.ctx, { ...parsed.data, actor });
    res.json(result);
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

router.get("/instagram/accounts", async (req, res, next) => {
  try {
    const actor = actorFields(req.currentUser);
    if (!actor) {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents and coworkers have Instagram accounts" } });
    }
    const accounts = await publishService.listInstagramAccounts(req.ctx, actor);
    res.json({ accounts });
  } catch (e) {
    next(e);
  }
});

router.post("/telegram", async (req, res, next) => {
  try {
    const parsed = tgPublishSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const actor = actorFields(req.currentUser);
    if (!actor) {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents and coworkers can publish" } });
    }
    const result = await publishService.publishTelegramDirect(req.ctx, { ...parsed.data, actor });
    res.json(result);
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

router.post("/youtube", async (req, res, next) => {
  try {
    const parsed = ytReportSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const actor = actorFields(req.currentUser);
    if (!actor) {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents and coworkers can report publish status" } });
    }
    const publication = await publishService.reportYoutubeStatus(req.ctx, { ...parsed.data, actor });
    res.json({ publication });
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

router.post("/instagram/consent", async (req, res, next) => {
  try {
    const igAssistConsentAt = await publishService.setIgConsent(req.ctx, req.auth.sub);
    res.json({ ok: true, igAssistConsentAt });
  } catch (e) {
    next(e);
  }
});

router.post("/:channel/map-fields", async (req, res, next) => {
  try {
    const parsed = mapFieldsSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const actor = actorFields(req.currentUser);
    if (!actor) {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents and coworkers can publish" } });
    }
    const result = await publishService.mapFieldsForChannel(req.ctx, req.params.channel, { ...parsed.data, actor });
    res.json(result);
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

router.post("/:channel/confirm", async (req, res, next) => {
  try {
    const parsed = confirmSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const actor = actorFields(req.currentUser);
    if (!actor) {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents and coworkers can publish" } });
    }
    const publication = await publishService.confirmChannelEvent(req.ctx, req.params.channel, { ...parsed.data, actor });
    res.json({ publication });
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

router.post("/reassign", async (req, res, next) => {
  try {
    const parsed = reassignSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    const actor = actorFields(req.currentUser);
    if (!actor) {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents and coworkers can publish" } });
    }
    const moved = await publishService.reassignDraft(req.ctx, { ...parsed.data, actor });
    res.json({ moved });
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

router.get("/ads/:adId/status", async (req, res, next) => {
  try {
    res.json(await publishService.getAdStatus(req.ctx, req.params.adId));
  } catch (e) {
    next(e);
  }
});

router.get("/status", async (req, res, next) => {
  try {
    const adIds = String(req.query.adIds ?? "").split(",").filter(Boolean).slice(0, 200);
    res.json(await publishService.getStatusBulk(req.ctx, adIds));
  } catch (e) {
    next(e);
  }
});

export default router;
