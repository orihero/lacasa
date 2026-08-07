import { Router } from "express";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import { effectiveAgentId } from "../middleware/roles.js";
import * as adService from "../services/adService.js";

const router = Router();

// Mirrors routes/publish.js's helper of the same name: adService throws
// httpError(status, code, message) (currently only from
// validateCoordinates, for lat/lng) and this maps it straight to the
// matching response; anything else falls through to next(e) / the app's
// generic 500 handler.
function handleServiceError(e, res, next) {
  if (e.status) {
    return res.status(e.status).json({ error: { code: e.code, message: e.message } });
  }
  next(e);
}

router.get("/", async (req, res, next) => {
  try {
    res.json(await adService.listAds(req.ctx, req.query));
  } catch (e) {
    next(e);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    const ad = await adService.getAd(req.ctx, req.params.id);
    if (!ad) {
      return res.status(404).json({ error: { code: "not_found", message: "Ad not found" } });
    }
    res.json(ad);
  } catch (e) {
    next(e);
  }
});

router.post("/", requireAuth, loadCurrentUser, async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }
    const actor = { agentId, coworkerId: req.currentUser.role === "COWORKER" ? req.currentUser.id : null };
    const ad = await adService.createAd(req.ctx, req.body, actor);
    res.status(201).json(ad);
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

router.patch("/:id", requireAuth, loadCurrentUser, async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    const actor = { agentId, coworkerId: req.currentUser.role === "COWORKER" ? req.currentUser.id : null };
    const ad = await adService.updateAd(req.ctx, req.params.id, agentId, req.body, actor);
    if (!ad) {
      return res.status(404).json({ error: { code: "not_found", message: "Ad not found" } });
    }
    res.json(ad);
  } catch (e) {
    handleServiceError(e, res, next);
  }
});

router.delete("/:id", requireAuth, loadCurrentUser, async (req, res, next) => {
  try {
    if (req.currentUser.role !== "AGENT") {
      return res.status(403).json({ error: { code: "forbidden", message: "Only the owning agent can delete an ad" } });
    }
    const deleted = await adService.deleteAd(req.ctx, req.params.id, req.currentUser.id);
    if (!deleted) {
      return res.status(404).json({ error: { code: "not_found", message: "Ad not found" } });
    }
    res.status(204).end();
  } catch (e) {
    next(e);
  }
});

export default router;
