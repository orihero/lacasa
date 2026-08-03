/**
 * @lacasa/api-client/resources/ads — ports the request shaping that used to
 * live in apps/web/src/lib/adsListStore.js.
 *
 * getAds() takes an explicit `{ scope, agentId }` instead of reaching into
 * useUserStore.getState() the way adsListStore.fetchAdsByAgentId did: the
 * store compared the requested agentId against the caller's own scope
 * (derived from a *different* zustand store) to decide between the
 * authenticated GET /my/ads (every stage, including drafts) and the public
 * GET /ads (active listings only). That hidden cross-store read only works
 * inside a component tree already wired to useUserStore — it's exactly what
 * makes the old code unusable from apps/mobile. Here the caller already
 * knows which scope it means (its own dashboard vs. someone's public
 * profile) and says so explicitly.
 */
import type { AdInput } from '@lacasa/domain';
import type { ApiClient } from '../core/client';
import type { QueryParams } from '../core/transport';

export interface AdFilters {
  city?: string;
  district?: string;
  category?: string;
  type?: string;
  rooms?: string | number;
  repairment?: string;
  storey?: string | number;
  furniture?: string;
  areaMin?: string | number;
  areaMax?: string | number;
  priceMin?: string | number;
  priceMax?: string | number;
}

export type AdSort = 'newest' | 'highestPrice' | 'lowestPrice';

/**
 * One entry of `Ad.media` — the full ordered photo/video set, each row
 * tagged with its AdMediaType (docs/10 §3). `Ad.photos` stays a flat
 * string[] of image URLs (unchanged wire contract every existing consumer —
 * AdsAdd/AdsEdit/Slider/HCard/Card/AdsList, plus the OLX/Instagram crosspost
 * payloads — already reads); `media` is additive, for a future carousel
 * that needs to tell photos and video apart.
 */
export interface AdMedia {
  url: string;
  mediaType: 'photo' | 'video';
  position: number;
}

export interface Ad {
  id: string;
  agentId: string;
  coworkerId?: string | null;
  /** Flat array of photo URLs only — see AdMedia doc comment above. */
  photos: string[];
  media: AdMedia[];
  /**
   * Listing-detail map pin (docs/10 §3). Always present on the wire (never
   * omitted), `number | null` — never both `null` and both non-null never
   * mixed (enforced server-side, see adService.js#validateCoordinates), so
   * `lat !== null && lng !== null` is the reliable "has a pin" check. Do
   * not treat a falsy check (`!ad.lat`) as "no pin" — a real pin at
   * latitude 0 is falsy but valid.
   */
  lat: number | null;
  lng: number | null;
  /**
   * Embedded 3D tour URL, or null. Guaranteed absolute http(s) — the API
   * rejects any other scheme on write, because this lands in an iframe src.
   */
  tour3dLink: string | null;
  [key: string]: unknown;
}

export interface AdStageCounts {
  stage1: number;
  stage2: number;
  stage3: number;
}

export interface GetAdsParams {
  /**
   * 'mine' hits the authenticated GET /my/ads (every stage, including
   * drafts, scoped to the caller's own agent/coworker context by the auth
   * token). 'public' hits the anonymous GET /ads (active listings only),
   * optionally narrowed to one agent via `agentId`.
   */
  scope: 'mine' | 'public';
  agentId?: string;
  filters?: AdFilters;
  sort?: AdSort;
}

// Empty string / undefined both mean "no filter" — mirrors the ?? undefined
// coalescing adsListStore.js did before spreading filters into axios params.
// priceMin/priceMax specifically only treated "" as absent (0 is a real
// filter value there), so they get their own check.
function toQuery(filters: AdFilters = {}): QueryParams {
  return {
    city: filters.city || undefined,
    district: filters.district || undefined,
    category: filters.category || undefined,
    type: filters.type || undefined,
    rooms: filters.rooms || undefined,
    repairment: filters.repairment || undefined,
    storey: filters.storey || undefined,
    furniture: filters.furniture || undefined,
    areaMin: filters.areaMin || undefined,
    areaMax: filters.areaMax || undefined,
    priceMin: filters.priceMin === '' || filters.priceMin == null ? undefined : filters.priceMin,
    priceMax: filters.priceMax === '' || filters.priceMax == null ? undefined : filters.priceMax,
  };
}

export function createAdsResource(client: ApiClient) {
  return {
    getAds({ scope, agentId, filters, sort }: GetAdsParams) {
      const query = toQuery(filters);
      if (scope === 'mine') {
        return client.request<Ad[]>({
          method: 'GET',
          path: '/my/ads',
          query: { ...query, sort: sort ?? 'newest' },
        });
      }
      return client.request<Ad[]>({
        method: 'GET',
        path: '/ads',
        query: { ...query, agentId },
      });
    },

    /** The public, anonymous listing (active ads only) — no auth required. */
    list(filters?: AdFilters) {
      return client.request<Ad[]>({ method: 'GET', path: '/ads', query: toQuery(filters) });
    },

    getById(id: string) {
      return client.request<Ad>({ method: 'GET', path: `/ads/${id}` });
    },

    getStageCounts() {
      return client.request<AdStageCounts>({ method: 'GET', path: '/my/ads/stage-counts' });
    },

    create(input: AdInput) {
      return client.request<Ad>({ method: 'POST', path: '/ads', body: input });
    },

    update(id: string, input: AdInput) {
      return client.request<Ad>({ method: 'PATCH', path: `/ads/${id}`, body: input });
    },

    remove(id: string) {
      return client.request<void>({ method: 'DELETE', path: `/ads/${id}` });
    },
  };
}

export type AdsResource = ReturnType<typeof createAdsResource>;
