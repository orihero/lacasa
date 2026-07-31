import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createCoworkersResource } from './coworkers';

function setup(response: unknown = {}) {
  const { transport, calls } = createFakeTransport(response);
  const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage('t'), baseUrl: 'http://api.test' });
  return { coworkers: createCoworkersResource(client), calls };
}

describe('coworkers resource', () => {
  it('list() requests GET /coworkers', async () => {
    const { coworkers, calls } = setup([]);

    await coworkers.list();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/coworkers' });
  });

  it('getById requests GET /coworkers/:id', async () => {
    const { coworkers, calls } = setup({ id: 'cw-1' });

    await coworkers.getById('cw-1');

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/coworkers/cw-1' });
  });

  it('create POSTs to /coworkers with the create input as body', async () => {
    const { coworkers, calls } = setup({ id: 'cw-1' });

    await coworkers.create({ fullName: 'Jane', email: 'jane@example.com', password: 'secret1' });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/coworkers',
      body: { fullName: 'Jane', email: 'jane@example.com', password: 'secret1' },
    });
  });

  it('update PATCHes /coworkers/:id', async () => {
    const { coworkers, calls } = setup({ id: 'cw-1' });

    await coworkers.update('cw-1', { fullName: 'Jane Doe' });

    expect(calls[0]).toMatchObject({
      method: 'PATCH',
      url: 'http://api.test/coworkers/cw-1',
      body: { fullName: 'Jane Doe' },
    });
  });

  it('remove DELETEs /coworkers/:id', async () => {
    const { coworkers, calls } = setup(undefined);

    await coworkers.remove('cw-1');

    expect(calls[0]).toMatchObject({ method: 'DELETE', url: 'http://api.test/coworkers/cw-1' });
  });
});
