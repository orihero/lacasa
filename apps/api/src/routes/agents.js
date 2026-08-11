import { Router } from "express";
import { z } from "zod";
import * as agentService from "../services/agentService.js";
import * as reviewService from "../services/reviewService.js";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";

const router = Router();

// Mirrors routes/ads.js's helper of the same name: reviewService throws
// httpError(status, code, message) and this maps it straight to the
// matching response; anything else falls through to next(e) / the app's
// generic 500 handler.
function handleServiceError(e, res, next) {
  if (e.status) {
    return res.status(e.status).json({ error: { code: e.code, message: e.message } });
  }
  next(e);
}

// Public: the agent directory and the agent card under a listing are both
// read by anonymous visitors.
router.get("/", async (req, res, next) => {
  try {
    res.json(await agentService.listAgents(req.ctx));
  } catch (e) {
    next(e);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    const agent = await agentService.getAgent(req.ctx, req.params.id);
    if (!agent) {
      return res.status(404).json({ error: { code: "not_found", message: "Agent not found" } });
    }
    res.json(agent);
  } catch (e) {
    next(e);
  }
});

const listReviewsQuerySchema = z.object({
  limit: z.coerce.number().int().min(1).max(50).optional(),
  cursor: z.string().uuid().optional(),
});

// Public, like the card itself: SCREENS.md §3.9's "Review: {rating}/5" row
// is read by anonymous visitors browsing the directory, same as adsCount.
router.get("/:id/reviews", async (req, res, next) => {
  try {
    const parsed = listReviewsQuerySchema.safeParse(req.query);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    res.json(await reviewService.listReviews(req.ctx, req.params.id, parsed.data));
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

// 200, not 201: this is an upsert, so a repeat post from the same author
// edits their existing review rather than creating a new one -- the second
// call must answer exactly like the first, same reasoning as
// routes/savedAds.js's POST.
router.post("/:id/reviews", requireAuth, loadCurrentUser, async (req, res, next) => {
  try {
    const review = await reviewService.createOrUpdateReview(req.ctx, req.params.id, req.currentUser.id, req.body);
    res.json(review);
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

router.delete("/:id/reviews/me", requireAuth, loadCurrentUser, async (req, res, next) => {
  try {
    await reviewService.deleteOwnReview(req.ctx, req.params.id, req.currentUser.id);
    res.status(204).end();
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

export default router;
