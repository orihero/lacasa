// POST /api/push/devices, DELETE /api/push/devices/:token — server-side
// device-token registration for push notifications. See pushService.js's
// file-header comment for the full scope note: this is plumbing only, there
// is no client anywhere in this monorepo that calls either route yet.
//
// Deliberately open to any authenticated role (USER/AGENT/COWORKER), unlike
// e.g. savedAds.js's buyer-only gate -- every role can eventually receive a
// push (today only agents do, via pushService.js#notifyForActivityEvent /
// notifyPublishOutcome, but there is nothing role-specific about "this
// device belongs to this account").
import { Router } from "express";
import { z } from "zod";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import * as pushService from "../services/pushService.js";

const router = Router();

router.use(requireAuth, loadCurrentUser);

const registerSchema = z.object({
  // FCM registration tokens run well past 150 characters in practice; 4096
  // is a generous ceiling that rejects garbage input without needing to
  // track any particular provider's exact format.
  token: z.string().min(1).max(4096),
  platform: z.enum(Object.keys(pushService.PLATFORM)),
});

router.post("/devices", async (req, res, next) => {
  try {
    const parsed = registerSchema.safeParse(req.body);
    if (!parsed.success) {
      return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
    }
    await pushService.registerDevice(req.ctx, req.currentUser.id, parsed.data);
    // 200, not 201: re-registering the same device is the same fact, not a
    // new resource (upsertDeviceToken is idempotent) -- same reasoning as
    // savedAds.js's POST /:adId.
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

router.delete("/devices/:token", async (req, res, next) => {
  try {
    await pushService.unregisterDevice(req.ctx, req.currentUser.id, req.params.token);
    // Always 204, even for a token that was never registered -- unregistering
    // something not registered leaves the caller in exactly the state they
    // asked for, same as savedAds.js's DELETE /:adId.
    res.status(204).end();
  } catch (e) {
    next(e);
  }
});

export default router;
