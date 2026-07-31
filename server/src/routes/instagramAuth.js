import { Router } from "express";
import crypto from "crypto";
import jwt from "jsonwebtoken";
import { prisma } from "../lib/prisma.js";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import {
  buildAuthorizeUrl,
  exchangeCode,
  exchangeLongLived,
  fetchMe,
} from "../lib/instagram.js";

const router = Router();

const APP_URL = process.env.APP_URL ?? "http://localhost:5273";

// Settings live at /profile/:agentId/setting; fall back to the app root when
// the agent id is unknown (e.g. state validation failed).
function settingsRedirect(res, status, agentId) {
  const path = agentId ? `/profile/${agentId}/setting` : "/";
  res.redirect(`${APP_URL}${path}?ig=${status}`);
}

// The connect button can't send an Authorization header on a plain
// window.open, so the frontend asks for the Meta authorize URL over XHR and
// opens what it gets back. `state` is a short-lived signed JWT binding the
// callback to the requesting agent (CSRF protection, docs/09 §1.2).
router.post("/connect-url", requireAuth, loadCurrentUser, async (req, res, next) => {
  try {
    if (req.currentUser.role !== "AGENT") {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents can connect an Instagram account" } });
    }
    const state = jwt.sign(
      { purpose: "ig_oauth", agentId: req.auth.sub, nonce: crypto.randomUUID() },
      process.env.JWT_SECRET,
      { expiresIn: "15m" },
    );
    res.json({ url: buildAuthorizeUrl(state) });
  } catch (e) {
    if (e.code === "ig_not_configured") {
      return res.status(503).json({ error: { code: e.code, message: e.message } });
    }
    next(e);
  }
});

// Public — Meta redirects the agent's browser here.
router.get("/callback", async (req, res) => {
  const { code, state, error_description: errorDescription } = req.query;
  if (!code || !state) {
    console.error("IG callback missing code/state:", errorDescription ?? req.query.error);
    return settingsRedirect(res, "error");
  }
  let agentId;
  try {
    const payload = jwt.verify(state, process.env.JWT_SECRET);
    if (payload.purpose !== "ig_oauth") throw new Error("wrong state purpose");
    agentId = payload.agentId;
  } catch (e) {
    console.error("IG callback state validation failed:", e.message);
    return settingsRedirect(res, "error");
  }

  try {
    const short = await exchangeCode(String(code));
    const long = await exchangeLongLived(short.access_token);
    const me = await fetchMe(long.access_token);
    const igUserId = String(me.user_id ?? me.id);
    const expiresAt = new Date(Date.now() + (long.expires_in ?? 60 * 24 * 3600) * 1000);

    await prisma.agentIgToken.upsert({
      where: { agentId_igUserId: { agentId, igUserId } },
      create: {
        agentId,
        igUserId,
        igUsername: me.username ?? null,
        accessToken: long.access_token,
        expiresAt,
      },
      update: {
        accessToken: long.access_token,
        igUsername: me.username ?? null,
        expiresAt,
        refreshedAt: new Date(),
      },
    });
    settingsRedirect(res, "connected", agentId);
  } catch (e) {
    console.error("IG OAuth exchange failed:", e.message);
    settingsRedirect(res, "error", agentId);
  }
});

// Disconnect one account.
router.delete("/:igUserId", requireAuth, loadCurrentUser, async (req, res, next) => {
  try {
    if (req.currentUser.role !== "AGENT") {
      return res.status(403).json({ error: { code: "forbidden", message: "Only agents can disconnect an Instagram account" } });
    }
    await prisma.agentIgToken.deleteMany({
      where: { agentId: req.currentUser.id, igUserId: req.params.igUserId },
    });
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

export default router;
