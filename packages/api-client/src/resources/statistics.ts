/**
 * @lacasa/api-client/resources/statistics — ports
 * apps/web/src/lib/useStatisticsStore.js.
 */
import type { ApiClient } from '../core/client';

export type StatisticsFilterType = 'today' | 'thisWeek' | 'thisMonth' | 'all';

export interface AdsStatistics {
  adsNewCount: number;
  adsSoldCount: number;
}

export interface CoworkerStatisticEvent {
  id: string;
  agentId: string;
  coworkerId: string;
  adId: string;
  leadId: string;
  stage: string;
  createdAt: { seconds: number };
}

export function createStatisticsResource(client: ApiClient) {
  return {
    getAdsStatistics(filterType?: StatisticsFilterType) {
      return client.request<AdsStatistics>({
        method: 'GET',
        path: '/statistics/ads',
        query: { filterType },
      });
    },

    getCoworkerStatistics() {
      return client.request<CoworkerStatisticEvent[]>({ method: 'GET', path: '/statistics/coworkers' });
    },
  };
}

export type StatisticsResource = ReturnType<typeof createStatisticsResource>;
