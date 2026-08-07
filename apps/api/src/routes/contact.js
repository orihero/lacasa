// The marketing site's public contact form (docs/05-migration-plan.md Phase
// E). Deliberately NOT behind requireAuth/loadCurrentUser -- there is no
// logged-in user on the public site, this is the same trust level as
// GET /api/ads. That makes it abuse-exposed in a way the rest of this app
// isn't, so every field is zod-validated + length-bound (contactSchema) and
// the route sits behind a small in-process rate limiter (lib/rateLimiter.js)
// keyed by IP. The caller's input is never echoed back in the response.
import { Router } from "express";
import { contactSchema } from "@lacasa/domain";
import { config } from "../lib/config.js";
import { sendMessage } from "../lib/telegram.js";
import { rateLimitMiddleware } from "../lib/rateLimiter.js";

const router = Router();

router.post(
  "/",
  rateLimitMiddleware({
    windowMs: 60_000,
    max: 5,
    code: "rate_limited",
    message: "Too many requests. Please try again in a minute.",
  }),
  async (req, res, next) => {
    try {
      const parsed = contactSchema.safeParse(req.body);
      if (!parsed.success) {
        return res.status(400).json({ error: { code: "validation", message: parsed.error.issues[0].message } });
      }

      if (!config.TG_CONFIGURED || !config.TG_CONTACT_CHAT_ID) {
        return res.status(503).json({
          error: {
            code: "contact_unconfigured",
            message: "The contact form is not configured on the server. Please try again later.",
          },
        });
      }

      const { name, phone, message } = parsed.data;
      const text = `New contact request\nName: ${name}\nPhone: ${phone}${message ? `\nMessage: ${message}` : ""}`;

      try {
        await sendMessage({ chatId: config.TG_CONTACT_CHAT_ID, text });
      } catch (e) {
        // Never surface the Telegram API's error detail (could reveal
        // chat/token specifics) to a public, unauthenticated caller, and
        // never echo their own input back.
        console.error("Contact form Telegram relay failed:", e.message);
        return res.status(502).json({
          error: { code: "contact_relay_failed", message: "Could not send your message right now. Please try again later." },
        });
      }

      res.status(202).json({ ok: true });
    } catch (e) {
      next(e);
    }
  },
);

export default router;
