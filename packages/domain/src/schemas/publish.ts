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

// Server-side Telegram publish (apps/api/src/services/publishService.js's
// publishTelegramDirect — the direct-token twin of publishInstagramDirect,
// mirrored here the same way igPublishSchema is). 1024 rather than IG's 2200:
// that's Telegram's actual sendMediaGroup caption limit, not a copy-paste of
// the Instagram bound. chatIds are strings because a Telegram chat id is a
// 64-bit int that doesn't round-trip through JSON number precision safely,
// and because they're checked server-side against the caller's own
// User.tgChatIds (BigInt[] in Prisma) rather than trusted outright.
export const tgPublishSchema = z.object({
  adId: z.string().min(1).max(120),
  caption: z.string().max(1024),
  imageUrls: z.array(z.string().url()).min(1).max(20),
  chatIds: z.array(z.string().min(1).max(40)).min(1).max(10),
});
export type TgPublishInput = z.infer<typeof tgPublishSchema>;

// YouTube stays a client-side OAuth upload (docs/08 §4) — this is a
// report-back only, so the payload is untrusted caller input describing an
// upload that already happened. `externalId` is constrained to the actual
// shape of a YouTube video id (11 base64url-ish characters) and
// `externalUrl`, if sent at all, must actually point at a youtube.com/
// youtu.be watch link — both narrower than a bare `.url()` check so a
// caller can't self-report an arbitrary link into AdPublication.externalUrl,
// which the CRM later renders as a clickable "view" link.
const YT_VIDEO_ID = /^[A-Za-z0-9_-]{11}$/;
const YT_WATCH_URL = /^https:\/\/(www\.)?(youtube\.com\/watch\?v=|youtu\.be\/)[A-Za-z0-9_-]{11}(&\S*)?$/;

export const ytReportSchema = z
  .object({
    adId: z.string().min(1).max(120),
    status: z.enum(['PUBLISHED', 'FAILED']),
    externalId: z.string().regex(YT_VIDEO_ID, 'externalId must be an 11-character YouTube video id').optional(),
    externalUrl: z.string().regex(YT_WATCH_URL, 'externalUrl must be a youtube.com or youtu.be watch link').max(500).optional(),
    errorMessage: z.string().max(1000).optional(),
  })
  .refine((data) => data.status !== 'PUBLISHED' || Boolean(data.externalId), {
    message: 'externalId (YouTube video id) is required when status is PUBLISHED',
    path: ['externalId'],
  });
export type YtReportInput = z.infer<typeof ytReportSchema>;
