import { invert } from './invert';

// Bidirectional maps between the wire/frontend string values (unchanged
// since the Firestore era — every ad form already speaks this vocabulary)
// and the Postgres enum values in apps/api/prisma/schema.prisma. Keeping
// the wire format stable means the React forms need no changes beyond
// swapping their data source from Firestore to the API.

export const AD_TYPE = {
  residential: 'RESIDENTIAL',
  nonresidential: 'NONRESIDENTIAL',
} as const;

export const AD_CATEGORY = {
  rent: 'RENT',
  sale: 'SALE',
} as const;

export const REPAIRMENT = {
  notRepaired: 'NOT_REPAIRED',
  normal: 'NORMAL',
  good: 'GOOD',
  excellent: 'EXCELLENT',
} as const;

export const FURNITURE = {
  withFurniture: 'WITH',
  withoutFurniture: 'WITHOUT',
} as const;

// Keys are the numeric-looking form values <select name="stage"> options
// send ("1"/"2"/"3") — JS/JSON object keys are always strings anyway, so
// this is written with string literal keys instead of numeric ones to keep
// the TypeScript side honest about what actually flows through the forms.
export const AD_STAGE = {
  '1': 'ACTIVE',
  '2': 'SOLD',
  '3': 'DRAFT',
} as const;

export const CURRENCY_CODE = {
  uzs: 'UZS',
  usd: 'USD',
} as const;

// AdPhoto.mediaType — distinguishes a photo from the video the CRM upload
// form already accepts (docs/10 §3). No producer sets this on write today;
// it exists so serializeAd's `media` array can tell clients which renderer
// (<img> vs <video>) a given AdPhoto row needs.
export const AD_MEDIA_TYPE = {
  photo: 'PHOTO',
  video: 'VIDEO',
} as const;

export type AdTypeKey = keyof typeof AD_TYPE;
export type AdCategoryKey = keyof typeof AD_CATEGORY;
export type RepairmentKey = keyof typeof REPAIRMENT;
export type FurnitureKey = keyof typeof FURNITURE;
export type AdStageKey = keyof typeof AD_STAGE;
export type CurrencyCodeKey = keyof typeof CURRENCY_CODE;
export type AdMediaTypeKey = keyof typeof AD_MEDIA_TYPE;

export const AD_TYPE_REV = invert(AD_TYPE);
export const AD_CATEGORY_REV = invert(AD_CATEGORY);
export const REPAIRMENT_REV = invert(REPAIRMENT);
export const FURNITURE_REV = invert(FURNITURE);
export const AD_STAGE_REV = invert(AD_STAGE); // e.g. ACTIVE -> "1"
export const CURRENCY_CODE_REV = invert(CURRENCY_CODE);
export const AD_MEDIA_TYPE_REV = invert(AD_MEDIA_TYPE);
