/**
 * Price per square metre for the listing-detail fact rail and the CRM form
 * (mockups/SCREENS.md §7).
 *
 * Deliberately computed rather than stored: docs/10 §5 rules out a
 * `pricePerSqm` column, since it is a pure function of `price` and `area`,
 * both already on the ad. Keeping it here means apps/web and apps/mobile
 * round it the same way instead of each rolling its own expression — the
 * mistake ../ads/currency.ts was written to undo.
 */

/**
 * Returns null rather than a number when the figure would be meaningless:
 * an ad with no area (it is nullable), or a zero/negative area that would
 * divide to Infinity. A zero price is left alone — free is a real price, and
 * 0 per m² is its honest answer.
 *
 * Rounds to a whole unit of currency, matching how
 * ../ads/currency.ts#convertDisplayPrice floors its conversion: these are
 * headline figures, and fractional so'm is noise.
 */
export function computePricePerSqm(price: number | string, area: number | string | null | undefined): number | null {
  if (area === null || area === undefined || area === '') return null;

  const areaValue = Number(area);
  const priceValue = Number(price);
  if (!Number.isFinite(areaValue) || !Number.isFinite(priceValue)) return null;
  if (areaValue <= 0) return null;

  return Math.round(priceValue / areaValue);
}
