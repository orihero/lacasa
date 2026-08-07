// Ported from the identical price-preview expression duplicated in
// AdsAdd.tsx and AdsEdit.tsx (apps/web/src/components/{adsAdd,adsEdit}/*):
//
//   priceType == "uzs"
//     ? Math.floor(priceValue / (currency[0]?.currency ?? 1)) + " $"
//     : (currency[0]?.currency ?? 0) * priceValue + " so'm"
//
// `rate` here is that `currency[0]?.currency` value from useUtilsStore —
// UZS per 1 USD.
import type { CurrencyCodeKey } from '../enums/ads';

/**
 * Renders the *other* currency's equivalent of a price for the inline
 * preview next to the price input: entering a so'm amount previews the USD
 * equivalent, and vice versa.
 */
export function convertDisplayPrice(
  priceValue: number | string,
  priceType: CurrencyCodeKey,
  rate: number | undefined,
): string {
  const value = Number(priceValue);
  if (priceType === 'uzs') {
    return `${Math.floor(value / (rate ?? 1))} $`;
  }
  return `${(rate ?? 0) * value} so'm`;
}
