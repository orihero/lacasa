/**
 * adFormFields — the Listing editor's pure form-state layer: the string-only
 * `AdFormState` a controlled `<PillInput>`/`<PillSelect>` grid actually
 * holds, and the two conversions either side of it —
 * `buildFormStateFromAd` (`Ad` -> `AdFormState`, edit mode) and
 * `buildAdInput` (`AdFormState` -> `AdInput`, both modes' save call).
 *
 * `Ad`'s only explicitly typed members are id/agentId/coworkerId/photos/
 * media/lat/lng/tour3dLink (packages/api-client/src/resources/ads.ts) —
 * every other field (title, city, rooms, active, …) comes through its index
 * signature as `unknown` (see MyAdsScreen.tsx's formatAdPrice call-site
 * comment, the established idiom this file follows). Every read below picks
 * a value out through a narrow*() guard instead of trusting a cast.
 *
 * `buildAdInput`'s own output has to satisfy `AdInput` (packages/domain/src/
 * schemas/ad.ts's `z.infer`) exactly — that schema's nullable numeric fields
 * (`rooms`/`area`/`storey`/`floors`) type as `number | null`, never `""`,
 * so an empty form field becomes a real `null`, matching the server's own
 * "empty string on a nullable field means clear it" coercion rather than
 * relying on it.
 */
import {
  AD_CATEGORY,
  AD_STAGE,
  AD_TYPE,
  CURRENCY_CODE,
  FURNITURE,
  REPAIRMENT,
  type AdCategoryKey,
  type AdInput,
  type AdStageKey,
  type AdTypeKey,
  type CurrencyCodeKey,
  type DateLike,
  type FurnitureKey,
  type RepairmentKey,
} from '@lacasa/domain';
import type { Ad } from '@lacasa/api-client';

export const AD_TYPE_KEYS = Object.keys(AD_TYPE) as AdTypeKey[];
export const AD_CATEGORY_KEYS = Object.keys(AD_CATEGORY) as AdCategoryKey[];
export const REPAIRMENT_KEYS = Object.keys(REPAIRMENT) as RepairmentKey[];
export const FURNITURE_KEYS = Object.keys(FURNITURE) as FurnitureKey[];
export const CURRENCY_CODE_KEYS = Object.keys(CURRENCY_CODE) as CurrencyCodeKey[];
const AD_STAGE_KEYS = Object.keys(AD_STAGE) as AdStageKey[];

export interface AdFormState {
  title: string;
  city: string;
  district: string;
  type: AdTypeKey | '';
  category: AdCategoryKey | '';
  price: string;
  priceType: CurrencyCodeKey;
  rooms: string;
  area: string;
  storey: string;
  floors: string;
  repairment: RepairmentKey | '';
  furniture: FurnitureKey | '';
  description: string;
  hashtags: string;
  photos: string[];
  /** Visible in search results — a real, separate `active` boolean column. */
  active: boolean;
  /**
   * Not its own Ad field — a UI-only signal that maps to `stage: '2'` on
   * save (see `buildAdInput`). Distinct from `active` on purpose: an ad can
   * be inactive without being sold, and vice versa (see this folder's report
   * for the reasoning behind not conflating the two).
   */
  markAsSold: boolean;
}

export const EMPTY_FORM_STATE: AdFormState = {
  title: '',
  city: '',
  district: '',
  type: '',
  category: '',
  price: '',
  priceType: 'usd',
  rooms: '',
  area: '',
  storey: '',
  floors: '',
  repairment: '',
  furniture: '',
  description: '',
  hashtags: '',
  photos: [],
  active: true,
  markAsSold: false,
};

function narrowString(value: unknown): string {
  return typeof value === 'string' ? value : '';
}

function narrowNumberString(value: unknown): string {
  if (typeof value === 'number' && Number.isFinite(value)) return String(value);
  if (typeof value === 'string' && value.trim() !== '') return value;
  return '';
}

function narrowEnumKey<K extends string>(value: unknown, validKeys: readonly K[]): K | '' {
  return typeof value === 'string' && (validKeys as readonly string[]).includes(value) ? (value as K) : '';
}

function narrowBool(value: unknown, fallback: boolean): boolean {
  return typeof value === 'boolean' ? value : fallback;
}

/** Edit mode's `Ad` -> the controlled form's starting state. */
export function buildFormStateFromAd(ad: Ad): AdFormState {
  const stage = narrowEnumKey(ad.stage, AD_STAGE_KEYS);
  return {
    title: narrowString(ad.title),
    city: narrowString(ad.city),
    district: narrowString(ad.district),
    type: narrowEnumKey(ad.type, AD_TYPE_KEYS),
    category: narrowEnumKey(ad.category, AD_CATEGORY_KEYS),
    price: narrowNumberString(ad.price),
    priceType: narrowEnumKey(ad.priceType, CURRENCY_CODE_KEYS) || 'usd',
    rooms: narrowNumberString(ad.rooms),
    area: narrowNumberString(ad.area),
    storey: narrowNumberString(ad.storey),
    floors: narrowNumberString(ad.floors),
    repairment: narrowEnumKey(ad.repairment, REPAIRMENT_KEYS),
    furniture: narrowEnumKey(ad.furniture, FURNITURE_KEYS),
    description: narrowString(ad.description),
    hashtags: narrowString(ad.hashtags),
    photos: [...ad.photos],
    active: narrowBool(ad.active, true),
    markAsSold: stage === '2',
  };
}

/**
 * The form -> the request body for `apiClient.ads.create`/`.update`.
 *
 * `stage` is computed from the two save actions the toolbar offers, not
 * carried as its own form field: "Save draft" always forces `'3'`
 * regardless of the Mark-as-sold switch; the regular "Save" button reflects
 * that switch (`'2'` when on, else `'1'`) — mirroring the mockup's own
 * control set, which has exactly those two buttons plus the switch, no
 * third "reactivate" affordance.
 */
export function buildAdInput(form: AdFormState, options: { forceDraft?: boolean } = {}): AdInput {
  const toNullableNumber = (value: string): number | null => (value.trim() === '' ? null : Number(value));
  const toNullableString = (value: string): string | null => (value.trim() === '' ? null : value.trim());

  return {
    title: form.title.trim(),
    city: form.city.trim(),
    district: form.district.trim(),
    type: form.type === '' ? undefined : form.type,
    category: form.category === '' ? undefined : form.category,
    price: form.price.trim() === '' ? 0 : Number(form.price),
    priceType: form.priceType,
    rooms: toNullableNumber(form.rooms),
    area: toNullableNumber(form.area),
    storey: toNullableNumber(form.storey),
    floors: toNullableNumber(form.floors),
    repairment: form.repairment === '' ? null : form.repairment,
    furniture: form.furniture === '' ? null : form.furniture,
    description: toNullableString(form.description),
    hashtags: toNullableString(form.hashtags),
    active: form.active,
    stage: options.forceDraft ? '3' : form.markAsSold ? '2' : '1',
    photos: form.photos,
  };
}

export interface FormErrors {
  title?: string;
  city?: string;
  district?: string;
  price?: string;
  hashtags?: string;
  description?: string;
  type?: string;
  category?: string;
}

/**
 * Client-side mirror of `adInputSchema`'s own length/type constraints
 * (packages/domain/src/schemas/ad.ts), plus a few required-for-a-useful-
 * listing checks the schema itself doesn't enforce (title/city/district/
 * price — the schema leaves every field optional because it also has to
 * accept partial PATCH bodies).
 *
 * `requireCore: false` (the "Save draft" button) drops the required-ness
 * checks — a draft is explicitly allowed to be incomplete — while still
 * catching real format violations (a too-long title, a non-numeric price)
 * on whatever *is* filled in, since those would still be rejected/garbled
 * server-side.
 */
export function validateForm(form: AdFormState, options: { requireCore?: boolean } = {}): FormErrors {
  const requireCore = options.requireCore ?? true;
  const errors: FormErrors = {};

  const title = form.title.trim();
  if (title.length === 0) {
    if (requireCore) errors.title = 'Title is required.';
  } else if (title.length > 300) {
    errors.title = 'Title must be 300 characters or fewer.';
  }

  const city = form.city.trim();
  if (city.length === 0) {
    if (requireCore) errors.city = 'City is required.';
  } else if (city.length > 200) {
    errors.city = 'City must be 200 characters or fewer.';
  }

  const district = form.district.trim();
  if (district.length === 0) {
    if (requireCore) errors.district = 'District is required.';
  } else if (district.length > 200) {
    errors.district = 'District must be 200 characters or fewer.';
  }

  const price = form.price.trim();
  if (price === '') {
    if (requireCore) errors.price = 'Price is required.';
  } else if (!Number.isFinite(Number(price)) || Number(price) < 0) {
    errors.price = 'Price must be a non-negative number.';
  }

  if (form.hashtags.length > 500) errors.hashtags = 'Hashtags must be 500 characters or fewer.';
  if (form.description.length > 5000) errors.description = 'Description must be 5000 characters or fewer.';

  // `type`/`category` are NOT NULL columns on the Ad row (schema.prisma) and
  // ListingEditorScreen's own submit gate used to check `form.type === '' ||
  // form.category === ''` *after* this function ran, silently refusing to
  // save with no error shown anywhere — a create-mode "Save draft" left
  // blank would instead reach the server and hit a raw Prisma NOT-NULL
  // failure. Both are real required-for-a-useful-listing checks (the schema
  // itself leaves them optional only because it also has to accept partial
  // PATCH bodies, same rationale as title/city/district/price above), so
  // they belong here, with the same requireCore relaxation for drafts.
  if (requireCore && form.type === '') errors.type = 'Type is required.';
  if (requireCore && form.category === '') errors.category = 'Category is required.';

  return errors;
}

export function isFormValid(form: AdFormState, options: { requireCore?: boolean } = {}): boolean {
  return Object.keys(validateForm(form, options)).length === 0;
}

/** "Untitled listing" fallback — same copy as publishStatus/helpers.ts's
 * `adTitle` (duplicated rather than imported: each screen folder owns its
 * own small display helpers here, see myAds/deriveMyAds.ts's `titleOf` and
 * publishStatus/helpers.ts's `adTitle` for the same pattern). */
export function adTitleOf(ad: Ad): string {
  return typeof ad.title === 'string' && ad.title.trim().length > 0 ? ad.title : 'Untitled listing';
}

export function adReferenceOf(ad: Ad): string | null {
  return typeof ad.reference === 'string' && ad.reference.length > 0 ? ad.reference : null;
}

export function stageKeyOf(ad: Ad): AdStageKey | undefined {
  return narrowEnumKey(ad.stage, AD_STAGE_KEYS) || undefined;
}

/** Narrows `ad.updatedAt` (`unknown`, via the index signature) into
 * `@lacasa/domain`'s `DateLike` union for `formatDateTime` — same idiom as
 * every other field in this file, just for the one date-shaped value the
 * toolbar's "updated …" caption needs. */
export function updatedAtOf(ad: Ad): DateLike {
  const value = ad.updatedAt;
  if (value === null || value === undefined) return null;
  if (typeof value === 'string' || typeof value === 'number' || value instanceof Date) return value;
  if (typeof value === 'object' && 'seconds' in value && typeof (value as { seconds: unknown }).seconds === 'number') {
    return value as { seconds: number };
  }
  return null;
}
