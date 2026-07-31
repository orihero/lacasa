import { z } from 'zod';
import { LEAD_STATUS } from '../enums/leads';
import { UZ_PHONE_REGEX } from '../validators/phone';
import { zodEnumFromKeys } from './zodEnum';

// Mirrors the field set apps/api/src/routes/leads.js's parseLeadInput()
// applies to POST/PATCH /api/leads bodies: every field is independently
// optional (PATCH sends a partial body), and an empty string on a nullable
// field means "clear it". The API itself doesn't enforce the phone regex
// server-side today (it just does `String(body.phone)`) — this schema does,
// reusing ../validators/phone's UZ_PHONE_REGEX instead of maintaining a
// second copy of it.

const emptyStringToNull = (value: unknown): unknown => (value === '' ? null : value);

export const leadInputSchema = z.object({
  fullName: z.string().min(1).max(200).optional(),
  phone: z.string().regex(UZ_PHONE_REGEX, 'Invalid Uzbekistan phone number').optional(),
  email: z.preprocess(emptyStringToNull, z.string().email().nullable()).optional(),
  budget: z.preprocess(emptyStringToNull, z.coerce.number().nonnegative().nullable()).optional(),
  comment: z.preprocess(emptyStringToNull, z.string().max(2000).nullable()).optional(),
  conversationComment: z.preprocess(emptyStringToNull, z.string().max(2000).nullable()).optional(),
  status: zodEnumFromKeys(LEAD_STATUS).optional(),
  source: z.preprocess(emptyStringToNull, z.string().max(200).nullable()).optional(),
  callbackDate: z.preprocess(emptyStringToNull, z.coerce.date().nullable()).optional(),
  active: z.coerce.boolean().optional(),
});

export type LeadInput = z.infer<typeof leadInputSchema>;
