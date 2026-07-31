import { z } from 'zod';
import { CONFIRM_EVENTS } from '../enums/publish';

// Ported verbatim from the zod schemas in apps/api/src/routes/publish.js —
// the request bodies for the server-side Instagram publish, the
// extension-assisted field-mapping/confirm round trip, and the
// draft-ad-id reassignment endpoint.

export const igPublishSchema = z.object({
  adId: z.string().min(1).max(120),
  caption: z.string().max(2200),
  imageUrls: z.array(z.string().url()).min(1).max(20),
  igUserIds: z.array(z.string()).max(10).optional(),
});
export type IgPublishInput = z.infer<typeof igPublishSchema>;

export const mapFieldsSchema = z.object({
  adId: z.string().min(1).max(120),
  ad: z.object({}).passthrough(),
  step: z.string().min(1).max(40),
  snapshot: z.array(z.any()).min(1).max(250),
});
export type MapFieldsInput = z.infer<typeof mapFieldsSchema>;

export const confirmSchema = z.object({
  adId: z.string().min(1).max(120),
  event: z.enum(CONFIRM_EVENTS),
  externalId: z.string().max(200).optional(),
  externalUrl: z.string().url().max(500).optional(),
  errorMessage: z.string().max(1000).optional(),
});
export type ConfirmInput = z.infer<typeof confirmSchema>;

export const reassignSchema = z.object({
  fromAdId: z.string().min(1).max(120),
  toAdId: z.string().min(1).max(120),
});
export type ReassignInput = z.infer<typeof reassignSchema>;
