import {
  AD_TYPE,
  AD_TYPE_REV,
  AD_CATEGORY,
  AD_CATEGORY_REV,
  REPAIRMENT,
  REPAIRMENT_REV,
  FURNITURE,
  FURNITURE_REV,
  AD_STAGE,
  AD_STAGE_REV,
  CURRENCY_CODE,
  CURRENCY_CODE_REV,
} from "./enums.js";

// DB row (Prisma enums, photos as AdPhoto[]) -> wire shape the React forms
// already speak (lowercase-string enums, photos as string[] of URLs,
// createdAt/updatedAt as {seconds} to match the old Firestore Timestamp shape
// formatCreatedAt() expects).
export function serializeAd(ad) {
  return {
    id: ad.id,
    title: ad.title,
    city: ad.city,
    district: ad.district,
    address: ad.address,
    reference: ad.reference,
    type: AD_TYPE_REV[ad.type],
    category: AD_CATEGORY_REV[ad.category],
    repairment: ad.repairment ? REPAIRMENT_REV[ad.repairment] : undefined,
    rooms: ad.rooms,
    area: ad.area !== null ? Number(ad.area) : null,
    storey: ad.storey,
    floors: ad.floors,
    furniture: ad.furniture ? FURNITURE_REV[ad.furniture] : undefined,
    hashtags: ad.hashtags,
    price: Number(ad.price),
    priceType: CURRENCY_CODE_REV[ad.priceType],
    stage: AD_STAGE_REV[ad.stage],
    description: ad.description,
    nearPlacesList: ad.nearPlaces,
    optionList: ad.options,
    active: ad.active,
    agentId: ad.agentId,
    coworkerId: ad.coworkerId ?? "",
    photos: (ad.photos ?? []).sort((a, b) => a.position - b.position).map((p) => p.url),
    createdAt: { seconds: Math.floor(new Date(ad.createdAt).getTime() / 1000) },
    updatedAt: { seconds: Math.floor(new Date(ad.updatedAt).getTime() / 1000) },
  };
}

// Wire payload (POST/PATCH body) -> Prisma create/update data. Numeric
// fields arrive as strings from uncontrolled <input type="number"> — same
// as the old Firestore-era forms — so everything is coerced here.
export function parseAdInput(body) {
  const data = {};

  if (body.title !== undefined) data.title = String(body.title);
  if (body.city !== undefined) data.city = String(body.city);
  if (body.district !== undefined) data.district = String(body.district);
  if (body.address !== undefined) data.address = body.address || null;
  if (body.reference !== undefined) data.reference = body.reference || null;
  if (body.type !== undefined) data.type = AD_TYPE[body.type];
  if (body.category !== undefined) data.category = AD_CATEGORY[body.category];
  if (body.repairment !== undefined) data.repairment = body.repairment ? REPAIRMENT[body.repairment] : null;
  if (body.rooms !== undefined) data.rooms = body.rooms === "" ? null : Number(body.rooms);
  if (body.area !== undefined) data.area = body.area === "" ? null : Number(body.area);
  if (body.storey !== undefined) data.storey = body.storey === "" ? null : Number(body.storey);
  if (body.floors !== undefined) data.floors = body.floors === "" ? null : Number(body.floors);
  if (body.furniture !== undefined) data.furniture = body.furniture ? FURNITURE[body.furniture] : null;
  if (body.hashtags !== undefined) data.hashtags = body.hashtags || null;
  if (body.price !== undefined) data.price = Number(body.price);
  if (body.priceType !== undefined) data.priceType = CURRENCY_CODE[body.priceType] ?? "UZS";
  if (body.stage !== undefined) data.stage = AD_STAGE[body.stage] ?? "ACTIVE";
  if (body.description !== undefined) data.description = body.description || null;
  if (body.nearPlacesList !== undefined) data.nearPlaces = body.nearPlacesList ?? [];
  if (body.optionList !== undefined) data.options = body.optionList ?? [];
  if (body.active !== undefined) data.active = Boolean(body.active);

  return data;
}
