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
  photos: z.array(z.string()).optional(),
});

export type AdInput = z.infer<typeof adInputSchema>;
