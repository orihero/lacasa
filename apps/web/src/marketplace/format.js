// Display formatting for the marketplace surface. The price rule is the
// SCREENS.md "Formatting conventions" contract the mobile home feed already
// implements (apps/mobile_flutter .../home_formatters.dart): grouped integer,
// no decimals, `/month` suffix for a rent. Wire vocabulary is the frontend
// enum keys from @lacasa/domain (category `rent|sale`, type
// `residential|nonresidential`, priceType `usd|uzs`).

export function groupPrice(value) {
  const rounded = Math.round(Number(value) || 0);
  return Math.abs(rounded)
    .toString()
    .replace(/\B(?=(\d{3})+(?!\d))/g, ",")
    .replace(/^/, rounded < 0 ? "-" : "");
}

/** `{ body, suffix }` — the caller styles the `/month` suffix smaller. */
export function priceParts(ad) {
  const body =
    ad.priceType === "uzs" ? `${groupPrice(ad.price)} UZS` : `$${groupPrice(ad.price)}`;
  return { body, suffix: ad.category === "rent" ? "/month" : "" };
}

export function categoryLabel(ad) {
  return ad.category === "rent" ? "For rent" : "For sale";
}

export function typeLabel(ad) {
  return ad.type === "nonresidential" ? "Commercial" : "Residential";
}

const REPAIRMENT_LABELS = {
  notRepaired: "No repair",
  normal: "Normal",
  good: "Good",
  excellent: "Excellent",
};

export function repairmentLabel(ad) {
  return REPAIRMENT_LABELS[ad.repairment] ?? null;
}

/** "4/9", or just "4" when the building's floor count is unknown. */
export function floorLabel(ad) {
  if (ad.storey == null) return null;
  return ad.floors == null ? String(ad.storey) : `${ad.storey}/${ad.floors}`;
}

/** "Chilonzor, Tashkent" — skips whichever half is missing. */
export function locationLabel(ad) {
  return [ad.district, ad.city].filter(Boolean).join(", ");
}
