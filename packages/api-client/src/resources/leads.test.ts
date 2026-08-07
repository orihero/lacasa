import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createLeadsResource } from './leads';

function setup(response: unknown = {}) {
  const { transport, calls } = createFakeTransport(response);
  const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage('t'), baseUrl: 'http://api.test' });
  return { leads: createLeadsResource(client), calls };
}

describe('leads resource', () => {
  it('list() requests GET /leads', async () => {
    const { leads, calls } = setup([]);

    await leads.list();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/leads' });
  });

  it('getById requests GET /leads/:id', async () => {
    const { leads, calls } = setup({ id: 'lead-1' });

    await leads.getById('lead-1');

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/leads/lead-1' });
  });

  it('create POSTs to /leads with the lead input as body', async () => {
    const { leads, calls } = setup({ id: 'lead-1' });

    await leads.create({ fullName: 'John Doe', phone: '+998901234567' });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/leads',
      body: { fullName: 'John Doe', phone: '+998901234567' },
    });
  });

  it('update PATCHes /leads/:id', async () => {
    const { leads, calls } = setup({ id: 'lead-1' });

    await leads.update('lead-1', { status: 'need_to_call_back' });

    expect(calls[0]).toMatchObject({
      method: 'PATCH',
      url: 'http://api.test/leads/lead-1',
      body: { status: 'need_to_call_back' },
    });
  });

  it('remove DELETEs /leads/:id', async () => {
    const { leads, calls } = setup(undefined);

    await leads.remove('lead-1');

    expect(calls[0]).toMatchObject({ method: 'DELETE', url: 'http://api.test/leads/lead-1' });
  });
});
