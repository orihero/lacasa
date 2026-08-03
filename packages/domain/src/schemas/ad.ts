import { z } from 'zod';
import { AD_TYPE, AD_CATEGORY, REPAIRMENT, FURNITURE, AD_STAGE, CURRENCY_CODE } from '../enums/ads';
import { zodEnumFromKeys } from './zodEnum';

// Mirrors the field set and coercions apps/api/src/lib/adsSerializer.js's
// parseAdInput() applies to POST/PATCH /api/ads bodies today: every field
// is independently optional (PATCH sends a partial body), numeric fields
// arrive as strings from uncontrolled <input type="number">, and an empty
// string on a nullable field means "clear it" rather than "0".

const emptyStringToNull = (value: unknown): unknown => (value === '' ? null : value);

const nullableCoercedNumber = () =>
  z.preprocess(emptyStringToNull, z.coerce.number().nullable());

const nullableCoercedNumberInRange = (min: number, max: number) =>
  z.preprocess(emptyStringToNull, z.coerce.number().min(min).max(max).nullable());

const nullableTrimmedString = (max: number) =>
  z.preprocess(emptyStringToNull, z.string().max(max).nullable());

export const adOptionEntrySchema = z.object({
  id: z.union([z.string(), z.number()]).optional(),
  key: z.string().optional(),
  value: z.string().optional(),
});

export const adInputSchema = z.object({
  title: z.string().min(1).max(300).optional(),
  city: z.string().min(1).max(200).optional(),
  district: z.string().min(1).max(200).optional(),
  address: nullableTrimmedString(500).optional(),
  reference: nullableTrimmedString(500).optional(),
  type: zodEnumFromKeys(AD_TYPE).optional(),
  category: zodEnumFromKeys(AD_CATEGORY).optional(),
  repairment: zodEnumFromKeys(REPAIRMENT).nullable().optional(),
  rooms: nullableCoercedNumber().optional(),
  area: nullableCoercedNumber().optional(),
  storey: nullableCoercedNumber().optional(),
  floors: nullableCoercedNumber().optional(),
  furniture: zodEnumFromKeys(FURNITURE).nullable().optional(),
  hashtags: nullableTrimmedString(500).optional(),
  price: z.coerce.number().nonnegative().optional(),
  priceType: zodEnumFromKeys(CURRENCY_CODE).optional(),
  stage: zodEnumFromKeys(AD_STAGE).optional(),
  description: nullableTrimmedString(5000).optional(),
  nearPlacesList: z.array(z.string()).optional(),
  optionList: z.array(adOptionEntrySchema).optional(),
  active: z.coerce.boolean().optional(),
  // Listing-detail map pin (docs/10 §3). Same "" -> null coercion as the
  // other nullable numeric fields above, plus a range clamp matching the
  // Decimal(9,6) column's real-world bounds. What this schema deliberately
  // does NOT encode: "lat and lng must be set together, or both left null."
  // That rule needs the ad's pre-existing row to evaluate on a partial
  // PATCH (e.g. `{lng: null}` alone is invalid only if lat is *currently*
  // set) -- not decidable from a single request body / a per-field schema,
  // and this schema isn't wired into the route request path today (see the
  // file-level comment above) to receive that context anyway. The real
  // check lives in apps/api/src/services/adService.js#validateCoordinates.
  lat: nullableCoercedNumberInRange(-90, 90).optional(),
  lng: nullableCoercedNumberInRange(-180, 180).optional(),
  // Stays a flat string[] of URLs on write (docs/10 §3 AdPhoto.mediaType
  // decision): AdsAdd/AdsEdit send exactly this shape today, and no CRM
  // upload flow produces a video AdPhoto row yet — every write goes through
  // photosCreateData (adService.js), which lets the AdPhoto.mediaType
  // column default to PHOTO. mediaType is read-only for now, surfaced via
  // the separate `media` array serializeAd adds alongside `photos`.
  photos: z.array(z.string()).optional(),
});

export type AdInput = z.infer<typeof adInputSchema>;
