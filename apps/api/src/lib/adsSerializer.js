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
  AD_MEDIA_TYPE_REV,
} from "./enums.js";

// AdPhoto.mediaType (docs/10 §3) reaches clients via a new `media` array
// rather than by changing the shape of `photos`. `photos: string[]` is read
// by apps/web's AdsAdd/AdsEdit/Slider/HCard/Card/AdsList, and separately
// feeds the OLX/Instagram crosspost payloads (packages/crosspost-protocol's
// `photoUrls: string[]`, publishInstagramDirect's `imageUrls`) — every one
// of those treats an entry as an image URL to hand to an <img> tag or an
// image-only publish API. Turning `photos` into an array of objects (or
// splitting video into a same-array sibling) would break all of them in
// the same PR that only asked for a schema column. So: `photos` keeps its
// existing contract *and* narrows to PHOTO rows only (today that's every
// row — no producer sets mediaType — so this is a no-op today and a safety
// net once a producer starts sending video); `media` is new, additive, and
// carries the full ordered set with type tags for a future carousel that
// wants to render video and for crosspost call sites to filter on
// deliberately instead of accidentally.
function serializePhoto(p) {
  return { url: p.url, mediaType: AD_MEDIA_TYPE_REV[p.mediaType], position: p.position };
}

// DB row (Prisma enums, photos as AdPhoto[]) -> wire shape the React forms
// already speak (lowercase-string enums, photos as string[] of URLs,
// createdAt/updatedAt as {seconds} to match the old Firestore Timestamp shape
// formatCreatedAt() expects).
export function serializeAd(ad) {
  const orderedPhotos = (ad.photos ?? []).slice().sort((a, b) => a.position - b.position);

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
    // Listing-detail map pin (docs/10 §3). Both null-guarded the same way as
    // `area` above (nullable Decimal -> Number(...) or null; Number(null)
    // would silently become 0, which is a real coordinate, not "no pin") --
    // never Number(null). Always present (never `undefined`) so a client
    // can reliably branch on `lat !== null && lng !== null` to mean "has a
    // pin" without confusing an unset pin with one at (0, 0) off Africa's
    // coast, which Number(undefined) vs Number(null) can't distinguish but
    // an explicit null here does.
    lat: ad.lat !== null ? Number(ad.lat) : null,
    lng: ad.lng !== null ? Number(ad.lng) : null,
    agentId: ad.agentId,
    coworkerId: ad.coworkerId ?? "",
    photos: orderedPhotos.filter((p) => p.mediaType === "PHOTO").map((p) => p.url),
    media: orderedPhotos.map(serializePhoto),
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
  // Same "" -> null, else Number(...) coercion as `area`/`storey`/`floors`
  // above (nullable Decimal columns). Range (-90..90 / -180..180) and the
  // "both or neither" pairing rule are NOT checked here -- parseAdInput is
  // pure coercion, no validation, matching every other field in this
  // function -- they're enforced in adService.js#validateCoordinates, which
  // is the one place that also has the pre-existing row for a partial PATCH.
  if (body.lat !== undefined) data.lat = body.lat === "" ? null : Number(body.lat);
  if (body.lng !== undefined) data.lng = body.lng === "" ? null : Number(body.lng);

  return data;
}
