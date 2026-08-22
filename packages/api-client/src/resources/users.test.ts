import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createUsersResource } from './users';

describe('users resource', () => {
  it('updateMe PATCHes /users/me with the update input as body', async () => {
    const { transport, calls } = createFakeTransport({ user: { id: 'u-1' } });
    const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage('t'), baseUrl: 'http://api.test' });
    const users = createUsersResource(client);

    const result = await users.updateMe({ fullName: 'New Name', avatar: 'https://x/avatar.png' });

    expect(calls[0]).toMatchObject({
      method: 'PATCH',
      url: 'http://api.test/users/me',
      body: { fullName: 'New Name', avatar: 'https://x/avatar.png' },
    });
    expect(result).toEqual({ user: { id: 'u-1' } });
  });
});
