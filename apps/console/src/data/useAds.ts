/**
 * src/data/useAds — the agent's own ad inventory. `useMyAds` always hits the
 * authenticated `scope: 'mine'` route (GET /my/ads, every stage including
 * drafts) — never `scope: 'public'`, which silently drops drafts and would
 * make My ads lie about what actually exists.
 *
 * `useDeleteAd` was originally a My ads-local hook (the FOUNDATION CONTRACT
 * fixed this module's exports before that screen existed) — promoted here
 * once a second consumer could plausibly want it, mirroring the sibling
 * create/delete mutation hooks in src/data/useCoworkers.ts and
 * src/data/useLeads.ts.
 */
import { useMutation, useQuery, useQueryClient, type UseMutationResult, type UseQueryResult } from '@tanstack/react-query';
import type { Ad, AdFilters, AdSort, AdStageCounts } from '@lacasa/api-client';
import type { ApiError } from '@lacasa/domain';
import { apiClient } from '@/lib/apiClient';
import { queryKeys } from './queryKeys';

export interface UseMyAdsOptions {
  filters?: AdFilters;
  sort?: AdSort;
}

export function useMyAds(options: UseMyAdsOptions = {}): UseQueryResult<Ad[]> {
  const { filters, sort } = options;
  return useQuery({
    queryKey: queryKeys.ads.mine(filters, sort),
    queryFn: () => apiClient.ads.getAds({ scope: 'mine', filters, sort }),
  });
}

export function useAd(id: string): UseQueryResult<Ad> {
  return useQuery({
    queryKey: queryKeys.ads.detail(id),
    queryFn: () => apiClient.ads.getById(id),
  });
}

export function useAdStageCounts(): UseQueryResult<AdStageCounts> {
  return useQuery({
    queryKey: queryKeys.ads.stageCounts(),
    queryFn: () => apiClient.ads.getStageCounts(),
  });
}

export function useDeleteAd(): UseMutationResult<void, ApiError, string> {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: (id: string) => apiClient.ads.remove(id),
    onSuccess: () => {
      // Invalidates the 'ads' prefix wholesale (mine/detail/stageCounts all
      // key off it) rather than just the current mine(filters, sort) entry —
      // a delete also has to be reflected in a different sort/filter combo
      // still sitting in cache, and in the stage-counts endpoint even though
      // My ads derives its own counts from the fetched list rather than
      // calling useAdStageCounts.
      void queryClient.invalidateQueries({ queryKey: queryKeys.ads.all });
    },
  });
}
