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

// Absolute http(s) only. This is not URL hygiene for its own sake: the value
// ends up as an <iframe src> on the public listing-detail page
// (apps/web/src/components/slider/Slider.jsx, which sets no `sandbox`
// attribute), so a `javascript:` or `data:text/html` scheme would be code
// running in a visitor's origin rather than an inert bad link. Agents are
// authenticated but not trusted with that.
//
// `new URL()` with no base also rejects protocol-relative ("//evil.com") and
// bare-host ("evil.com") values, which would otherwise resolve against
// whatever origin the page happens to be on.
const isHttpUrl = (value: string): boolean => {
  try {
    const { protocol } = new URL(value);
    return protocol === 'http:' || protocol === 'https:';
  } catch {
    return false;
  }
};

const nullableHttpUrl = (max: number) =>
  z.preprocess(
    emptyStringToNull,
    z
      .string()
      .max(max)
      .refine(isHttpUrl, { message: 'must be an absolute http(s) URL' })
      .nullable(),
  );

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
  // Embedded 3D tour on listing detail (docs/10 §3, SCREENS.md §7). Unlike
  // lat/lng, this one IS enforced on the request path — see the route's
  // safeParse in apps/api/src/routes/ads.js — because the value reaches an
  // iframe src. See nullableHttpUrl above for why that matters.
  tour3dLink: nullableHttpUrl(2048).optional(),
});

export type AdInput = z.infer<typeof adInputSchema>;
