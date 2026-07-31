/**
 * @lacasa/api-client/resources/utils — ports the currency-rate and
 * nearby-place-option reads out of apps/web/src/lib/utilsStore.js
 * (GET /utils/currency, GET /utils/nearby-places). Both are public,
 * unauthenticated reference-data endpoints — no auth required, same as
 * GET /ads.
 */
import type { ApiClient } from '../core/client';

export interface CurrencyRate {
  code: string;
  rate: number;
}

export function createUtilsResource(client: ApiClient) {
  return {
    getCurrency() {
      return client.request<CurrencyRate>({ method: 'GET', path: '/utils/currency' });
    },

    /** Ordered list of nearby-place option labels (e.g. "Metro", "School"). */
    getNearbyPlaces() {
      return client.request<string[]>({ method: 'GET', path: '/utils/nearby-places' });
    },
  };
}

export type UtilsResource = ReturnType<typeof createUtilsResource>;
