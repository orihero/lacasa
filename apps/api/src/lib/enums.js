// Bidirectional maps between the wire/frontend string values (unchanged since
// the Firestore era — every ad/lead form already speaks this vocabulary) and
// the Postgres enum values in prisma/schema.prisma. Keeping the wire format
// stable means the React forms need no changes beyond swapping their data
// source from Firestore to this API.

export const AD_TYPE = { residential: "RESIDENTIAL", nonresidential: "NONRESIDENTIAL" };
export const AD_CATEGORY = { rent: "RENT", sale: "SALE" };
export const REPAIRMENT = {
  notRepaired: "NOT_REPAIRED",
  normal: "NORMAL",
  good: "GOOD",
  excellent: "EXCELLENT",
};
export const FURNITURE = { withFurniture: "WITH", withoutFurniture: "WITHOUT" };
export const AD_STAGE = { 1: "ACTIVE", 2: "SOLD", 3: "DRAFT" };
export const CURRENCY_CODE = { uzs: "UZS", usd: "USD" };
export const LEAD_STATUS = {
  new: "NEW",
  could_not_connect: "COULD_NOT_CONNECT",
  need_to_call_back: "NEED_TO_CALL_BACK",
  rejected: "REJECTED",
  accepted: "ACCEPTED",
};

// Legacy Firestore `statistics.stage` numeric codes — the frontend's
// statistics store/Chart component still filter on these numbers.
export const EVENT_STAGE = {
  AD_CREATED: 1,
  AD_SOLD: 2,
  AD_DRAFT_UPDATED: 3,
  LEAD_CREATED: 4,
  LEAD_STATUS_CHANGED: 5,
};

function invert(map) {
  return Object.fromEntries(Object.entries(map).map(([k, v]) => [v, k]));
}

export const AD_TYPE_REV = invert(AD_TYPE);
export const AD_CATEGORY_REV = invert(AD_CATEGORY);
export const REPAIRMENT_REV = invert(REPAIRMENT);
export const FURNITURE_REV = invert(FURNITURE);
export const AD_STAGE_REV = invert(AD_STAGE); // e.g. ACTIVE -> "1"
export const CURRENCY_CODE_REV = invert(CURRENCY_CODE);
export const LEAD_STATUS_REV = invert(LEAD_STATUS);
