import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createStatisticsResource } from './statistics';

function setup(response: unknown = {}) {
  const { transport, calls } = createFakeTransport(response);
  const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage('t'), baseUrl: 'http://api.test' });
  return { statistics: createStatisticsResource(client), calls };
}

describe('statistics resource', () => {
  it('getAdsStatistics requests GET /statistics/ads with filterType in the query', async () => {
    const { statistics, calls } = setup({ adsNewCount: 1, adsSoldCount: 2 });

    await statistics.getAdsStatistics('thisWeek');

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/statistics/ads' });
    expect(calls[0]!.query).toEqual({ filterType: 'thisWeek' });
  });

  it('getAdsStatistics with no filterType still sends the query key (undefined)', async () => {
    const { statistics, calls } = setup({ adsNewCount: 0, adsSoldCount: 0 });

    await statistics.getAdsStatistics();

    expect(calls[0]!.query).toEqual({ filterType: undefined });
  });

  it('getCoworkerStatistics requests GET /statistics/coworkers', async () => {
    const { statistics, calls } = setup([]);

    await statistics.getCoworkerStatistics();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/statistics/coworkers' });
  });
});
