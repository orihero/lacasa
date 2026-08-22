import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createContactResource } from './contact';

describe('contact resource', () => {
  it('submit POSTs /contact with the payload as body', async () => {
    const { transport, calls } = createFakeTransport({ ok: true });
    const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage(null), baseUrl: 'http://api.test' });
    const contact = createContactResource(client);

    await contact.submit({ name: 'Aziz', phone: '+998901234567', message: 'Call me back' });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/contact',
      body: { name: 'Aziz', phone: '+998901234567', message: 'Call me back' },
    });
  });
});
