import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createAdsResource } from './ads';

function setup(response: unknown = {}) {
  const { transport, calls } = createFakeTransport(response);
  const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage(null), baseUrl: 'http://api.test' });
  return { ads: createAdsResource(client), calls };
}

describe('ads resource', () => {
  it('getAds({ scope: "mine" }) hits GET /my/ads and defaults sort to "newest"', async () => {
    const { ads, calls } = setup([]);

    await ads.getAds({ scope: 'mine' });

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/my/ads' });
    expect(calls[0]!.query).toMatchObject({ sort: 'newest' });
  });

  it('getAds({ scope: "mine", sort }) passes the explicit sort through', async () => {
    const { ads, calls } = setup([]);

    await ads.getAds({ scope: 'mine', sort: 'highestPrice' });

    expect(calls[0]!.query).toMatchObject({ sort: 'highestPrice' });
  });

  it('getAds({ scope: "public", agentId }) hits GET /ads with agentId in the query — not /my/ads, even for the caller\'s own id', async () => {
    const { ads, calls } = setup([]);

    await ads.getAds({ scope: 'public', agentId: 'agent-1' });

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/ads' });
    expect(calls[0]!.query).toMatchObject({ agentId: 'agent-1' });
  });

  it('getAds filters drop empty/undefined values but keep priceMin: 0', async () => {
    const { ads, calls } = setup([]);

    await ads.getAds({
      scope: 'mine',
      filters: { city: '', district: 'Yunusabad', priceMin: 0, priceMax: '' },
    });

    expect(calls[0]!.query?.city).toBeUndefined();
    expect(calls[0]!.query?.district).toBe('Yunusabad');
    expect(calls[0]!.query?.priceMin).toBe(0);
    expect(calls[0]!.query?.priceMax).toBeUndefined();
  });

  it('list() hits the public GET /ads', async () => {
    const { ads, calls } = setup([]);

    await ads.list({ city: 'Tashkent' });

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/ads' });
    expect(calls[0]!.query).toMatchObject({ city: 'Tashkent' });
  });

  it('getById requests GET /ads/:id', async () => {
    const { ads, calls } = setup({ id: 'ad-1' });

    await ads.getById('ad-1');

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/ads/ad-1' });
  });

  it('getStageCounts requests GET /my/ads/stage-counts', async () => {
    const { ads, calls } = setup({ stage1: 1, stage2: 2, stage3: 0 });

    const result = await ads.getStageCounts();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/my/ads/stage-counts' });
    expect(result).toEqual({ stage1: 1, stage2: 2, stage3: 0 });
  });

  it('create POSTs the ad input as the body to /ads', async () => {
    const { ads, calls } = setup({ id: 'new' });

    await ads.create({ title: 'Nice flat', photos: ['a.jpg'] });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/ads',
      body: { title: 'Nice flat', photos: ['a.jpg'] },
    });
  });

  it('update PATCHes /ads/:id', async () => {
    const { ads, calls } = setup({ id: 'ad-1' });

    await ads.update('ad-1', { stage: '2' });

    expect(calls[0]).toMatchObject({
      method: 'PATCH',
      url: 'http://api.test/ads/ad-1',
      body: { stage: '2' },
    });
  });

  it('remove DELETEs /ads/:id', async () => {
    const { ads, calls } = setup(undefined);

    await ads.remove('ad-1');

    expect(calls[0]).toMatchObject({ method: 'DELETE', url: 'http://api.test/ads/ad-1' });
  });
});
