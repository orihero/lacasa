/**
 * src/data/usePublish — the per-ad channel status grid (Publish status
 * screen, and the small status glance My ads' row actions want). Both hooks
 * are `enabled`-guarded rather than firing on an undefined/empty id: a
 * request to `/publish/ads/undefined/status` is a bug, not a 404 to render.
 */
import { useQuery, type UseQueryResult } from '@tanstack/react-query';
import { apiClient } from '@/lib/apiClient';
import { queryKeys } from './queryKeys';

type PublishStatusForAd = Awaited<ReturnType<typeof apiClient.publish.getStatusForAd>>;
type PublishStatusForAds = Awaited<ReturnType<typeof apiClient.publish.getStatusForAds>>;

export function usePublishStatusForAd(adId?: string): UseQueryResult<PublishStatusForAd> {
  return useQuery({
    queryKey: queryKeys.publish.forAd(adId ?? ''),
    queryFn: () => {
      if (!adId) throw new Error('usePublishStatusForAd called without an adId');
      return apiClient.publish.getStatusForAd(adId);
    },
    enabled: Boolean(adId),
  });
}

export function usePublishStatusForAds(adIds: string[]): UseQueryResult<PublishStatusForAds> {
  return useQuery({
    queryKey: queryKeys.publish.forAds(adIds),
    queryFn: () => apiClient.publish.getStatusForAds(adIds),
    enabled: adIds.length > 0,
  });
}
