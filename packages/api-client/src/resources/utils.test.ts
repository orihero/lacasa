import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createUtilsResource } from './utils';

function setup(response: unknown = {}) {
  const { transport, calls } = createFakeTransport(response);
  const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage(null), baseUrl: 'http://api.test' });
  return { utils: createUtilsResource(client), calls };
}

describe('utils resource', () => {
  it('getCurrency requests GET /utils/currency', async () => {
    const { utils, calls } = setup({ code: 'USD', rate: 12750 });

    const result = await utils.getCurrency();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/utils/currency' });
    expect(result).toEqual({ code: 'USD', rate: 12750 });
  });

  it('getNearbyPlaces requests GET /utils/nearby-places', async () => {
    const { utils, calls } = setup(['Metro', 'School']);

    const result = await utils.getNearbyPlaces();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/utils/nearby-places' });
    expect(result).toEqual(['Metro', 'School']);
  });
});
