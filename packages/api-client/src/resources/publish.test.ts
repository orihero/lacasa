import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createPublishResource } from './publish';

function setup(response: unknown = {}) {
  const { transport, calls } = createFakeTransport(response);
  const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage('t'), baseUrl: 'http://api.test' });
  return { publish: createPublishResource(client), calls };
}

describe('publish resource', () => {
  it('publishInstagram POSTs /publish/instagram with the payload as body', async () => {
    const { publish, calls } = setup({ publication: {}, results: [] });

    await publish.publishInstagram({
      adId: 'ad-1',
      caption: 'For sale',
      imageUrls: ['https://x/1.jpg'],
    });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/publish/instagram',
      body: { adId: 'ad-1', caption: 'For sale', imageUrls: ['https://x/1.jpg'] },
    });
  });

  it('getInstagramAccounts requests GET /publish/instagram/accounts', async () => {
    const { publish, calls } = setup({ accounts: [] });

    await publish.getInstagramAccounts();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/publish/instagram/accounts' });
  });

  it('grantInstagramAssistConsent POSTs /publish/instagram/consent', async () => {
    const { publish, calls } = setup({ ok: true, igAssistConsentAt: '2026-01-01' });

    await publish.grantInstagramAssistConsent();

    expect(calls[0]).toMatchObject({ method: 'POST', url: 'http://api.test/publish/instagram/consent' });
  });

  it('publishTelegram POSTs /publish/telegram with the payload as body', async () => {
    const { publish, calls } = setup({ publication: {}, results: [] });

    await publish.publishTelegram({
      adId: 'ad-1',
      caption: 'For sale',
      imageUrls: ['https://x/1.jpg'],
      chatIds: ['-100123'],
    });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/publish/telegram',
      body: { adId: 'ad-1', caption: 'For sale', imageUrls: ['https://x/1.jpg'], chatIds: ['-100123'] },
    });
  });

  it('reportYoutubeStatus POSTs /publish/youtube with the payload as body', async () => {
    const { publish, calls } = setup({ publication: {} });

    await publish.reportYoutubeStatus({ adId: 'ad-1', status: 'PUBLISHED', externalId: 'dQw4w9WgXcQ' });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/publish/youtube',
      body: { adId: 'ad-1', status: 'PUBLISHED', externalId: 'dQw4w9WgXcQ' },
    });
  });

  it('mapFields POSTs /publish/:channel/map-fields', async () => {
    const { publish, calls } = setup({});

    await publish.mapFields('olx', { adId: 'ad-1', ad: {}, step: 'category', snapshot: [{}] });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/publish/olx/map-fields',
      body: { adId: 'ad-1', ad: {}, step: 'category', snapshot: [{}] },
    });
  });

  it('confirm POSTs /publish/:channel/confirm', async () => {
    const { publish, calls } = setup({ publication: {} });

    await publish.confirm('instagram', { adId: 'ad-1', event: 'published' });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/publish/instagram/confirm',
      body: { adId: 'ad-1', event: 'published' },
    });
  });

  it('reassign POSTs /publish/reassign', async () => {
    const { publish, calls } = setup({ moved: 2 });

    await publish.reassign({ fromAdId: 'draft-1', toAdId: 'ad-1' });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/publish/reassign',
      body: { fromAdId: 'draft-1', toAdId: 'ad-1' },
    });
  });

  it('getStatusForAd requests GET /publish/ads/:adId/status', async () => {
    const { publish, calls } = setup({ adId: 'ad-1', channels: [] });

    await publish.getStatusForAd('ad-1');

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/publish/ads/ad-1/status' });
  });

  it('getStatusForAds requests GET /publish/status with adIds joined by comma', async () => {
    const { publish, calls } = setup({});

    await publish.getStatusForAds(['ad-1', 'ad-2']);

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/publish/status' });
    expect(calls[0]!.query).toEqual({ adIds: 'ad-1,ad-2' });
  });
});
