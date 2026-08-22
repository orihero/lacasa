/**
 * src/data/queryKeys — every react-query key factory in one place, so a
 * cache invalidation (`queryClient.invalidateQueries`) and the `useQuery`
 * call it's meant to catch can never drift onto two hand-typed key arrays
 * that only look the same.
 */
import type { AdFilters, AdSort } from '@lacasa/api-client';
import type { StatisticsFilterType } from '@lacasa/api-client';

export const queryKeys = {
  ads: {
    all: ['ads'] as const,
    // `sort` is folded to `null` when it's either unset or the server's own
    // default ('newest', see @lacasa/api-client's ads.ts#getAds) — Rail's
    // badge query calls useMyAds() with no options at all, MyAdsScreen calls
    // useMyAds({ sort }) starting from that same 'newest' default, and both
    // hit the identical GET /my/ads?sort=newest; without this fold they'd
    // land on two different cache keys and double-fetch on every visit.
    mine: (filters?: AdFilters, sort?: AdSort) =>
      ['ads', 'mine', filters ?? null, sort && sort !== 'newest' ? sort : null] as const,
    detail: (id: string) => ['ads', 'detail', id] as const,
    stageCounts: () => ['ads', 'stageCounts'] as const,
  },
  leads: {
    all: ['leads'] as const,
    list: () => ['leads', 'list'] as const,
  },
  coworkers: {
    all: ['coworkers'] as const,
    list: () => ['coworkers', 'list'] as const,
  },
  publish: {
    all: ['publish'] as const,
    forAd: (adId: string) => ['publish', 'ad', adId] as const,
    forAds: (adIds: string[]) => ['publish', 'ads', [...adIds].sort()] as const,
    instagramAccounts: () => ['publish', 'instagramAccounts'] as const,
  },
  statistics: {
    all: ['statistics'] as const,
    ads: (filter?: StatisticsFilterType) => ['statistics', 'ads', filter ?? null] as const,
    coworkers: () => ['statistics', 'coworkers'] as const,
  },
} as const;
