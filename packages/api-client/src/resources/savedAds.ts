/**
 * @lacasa/api-client/resources/savedAds — the buyer's favourites (the heart
 * control, mockups/SCREENS.md §17).
 *
 * `SavedAd` writes out its fields rather than extending `Ad` from
 * ./ads: that interface carries a `[key: string]: unknown` index signature,
 * so every field but a handful types as `unknown`. docs/10 §7 asks new
 * resources to declare real fields instead of inheriting that escape hatch.
 *
 * Shapes below mirror apps/api/src/lib/adsSerializer.js#serializeAd exactly —
 * `photos` is a flat `string[]` of image URLs and `media` is the fuller
 * ordered photo/video set (see ./ads' `AdMedia` doc comment), and the
 * timestamps keep the legacy Firestore `{ seconds }` form the web
 * formatters still expect.
 */
import type { ApiClient } from '../core/client';
import type { AdMedia } from './ads';

export interface SavedAd {
  id: string;
  title: string;
  city: string;
  district: string;
  address: string | null;
  reference: string | null;
  type: string;
  category: string;
  /** Absent rather than null when the ad carries no repair state. */
  repairment?: string;
  rooms: number | null;
  area: number | null;
  storey: number | null;
  floors: number | null;
  furniture?: string;
  hashtags: string | null;
  price: number;
  priceType: string;
  stage: string;
  description: string | null;
  nearPlacesList: string[];
  optionList: unknown;
  active: boolean;
  agentId: string;
  /** Empty string, not null, when the ad has no coworker. */
  coworkerId: string;
  photos: string[];
  media: AdMedia[];
  /** Map pin, or null for both. See ./ads' `Ad.lat` for the "has a pin" rule. */
  lat: number | null;
  lng: number | null;
  /** Absolute http(s) tour URL, or null. Enforced server-side on write. */
  tour3dLink: string | null;
  createdAt: { seconds: number };
  updatedAt: { seconds: number };
  /** Always true — every entry in this list is, by definition, saved. */
  saved: true;
}

export function createSavedAdsResource(client: ApiClient) {
  return {
    list() {
      return client.request<SavedAd[]>({ method: 'GET', path: '/saved-ads' });
    },

    // Both writes are idempotent server-side, so callers can fire them
    // straight off a toggle without tracking the current state first.
    save(adId: string) {
      return client.request<{ ok: true }>({ method: 'POST', path: `/saved-ads/${adId}` });
    },

    unsave(adId: string) {
      return client.request<void>({ method: 'DELETE', path: `/saved-ads/${adId}` });
    },
  };
}

export type SavedAdsResource = ReturnType<typeof createSavedAdsResource>;
