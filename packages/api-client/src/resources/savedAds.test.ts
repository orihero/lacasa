import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createSavedAdsResource } from './savedAds';

function setup(response: unknown = {}) {
  const { transport, calls } = createFakeTransport(response);
  const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage('t'), baseUrl: 'http://api.test' });
  return { savedAds: createSavedAdsResource(client), calls };
}

describe('savedAds resource', () => {
  it('list() requests GET /saved-ads', async () => {
    const { savedAds, calls } = setup([]);

    await savedAds.list();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/saved-ads' });
  });

  it('save() POSTs to /saved-ads/:adId with no body', async () => {
    const { savedAds, calls } = setup({ ok: true });

    await savedAds.save('ad-1');

    expect(calls[0]).toMatchObject({ method: 'POST', url: 'http://api.test/saved-ads/ad-1' });
    expect(calls[0]!.body).toBeUndefined();
  });

  it('unsave() requests DELETE /saved-ads/:adId', async () => {
    const { savedAds, calls } = setup();

    await savedAds.unsave('ad-1');

    expect(calls[0]).toMatchObject({ method: 'DELETE', url: 'http://api.test/saved-ads/ad-1' });
  });
});
