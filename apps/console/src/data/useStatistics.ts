/**
 * src/data/useStatistics — the two real aggregate endpoints behind the
 * Statistics screen's stat cards. There is no activity-feed endpoint (the
 * prototype's "Recent activity" list, PLAN.md §3.1) — that screen must Flag
 * it rather than assemble one out of `useCoworkerStatistics()`'s raw
 * events, which carry no human-readable sentence, only
 * `{ stage, adId, leadId, createdAt }`.
 */
import { useQuery, type UseQueryResult } from '@tanstack/react-query';
import type { AdsStatistics, CoworkerStatisticEvent, StatisticsFilterType } from '@lacasa/api-client';
import { apiClient } from '@/lib/apiClient';
import { queryKeys } from './queryKeys';

export function useAdsStatistics(filter?: StatisticsFilterType): UseQueryResult<AdsStatistics> {
  return useQuery({
    queryKey: queryKeys.statistics.ads(filter),
    queryFn: () => apiClient.statistics.getAdsStatistics(filter),
  });
}

export function useCoworkerStatistics(): UseQueryResult<CoworkerStatisticEvent[]> {
  return useQuery({
    queryKey: queryKeys.statistics.coworkers(),
    queryFn: () => apiClient.statistics.getCoworkerStatistics(),
  });
}
