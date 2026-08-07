import { z } from 'zod';
import { UZ_PHONE_REGEX } from '../validators/phone';

// The marketing site's public contact form (apps/web/src/routes/aboutPageNew
// /components/ContactUs.jsx), relayed server-side to the office Telegram
// chat by POST /api/contact — see docs/05-migration-plan.md Phase E. This
// endpoint has no auth (there is no logged-in user on the public site) and
// is abuse-exposed, so every field is length-bound here rather than trusted
// to whatever the form happened to enforce client-side. Phone reuses the
// same +998XXXXXXXXX pattern the rest of the app already validates against
// (see validators/phone.ts's file header) — this form asked for the same
// pattern by hand before this schema existed.
export const contactSchema = z.object({
  name: z.string().trim().min(1, 'Name is required').max(120),
  phone: z.string().regex(UZ_PHONE_REGEX, 'Phone must be in +998XXXXXXXXX format'),
  message: z.string().trim().max(2000).optional().default(''),
});
export type ContactInput = z.infer<typeof contactSchema>;
