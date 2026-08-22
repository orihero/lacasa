import { describe, expect, it } from 'vitest';
import { createApiClient } from '../core/client';
import { createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';
import { createAuthResource } from './auth';

function setup(response: unknown = {}) {
  const { transport, calls } = createFakeTransport(response);
  const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage(null), baseUrl: 'http://api.test' });
  return { auth: createAuthResource(client), calls };
}

describe('auth resource', () => {
  it('register POSTs /auth/register with the register input as body', async () => {
    const { auth, calls } = setup({ token: 't', user: {} });

    await auth.register({ fullName: 'Jane', email: 'jane@example.com', password: 'secret1' });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/auth/register',
      body: { fullName: 'Jane', email: 'jane@example.com', password: 'secret1' },
    });
  });

  it('login POSTs /auth/login with the login input as body', async () => {
    const { auth, calls } = setup({ token: 't', user: {} });

    await auth.login({ email: 'jane@example.com', password: 'secret1' });

    expect(calls[0]).toMatchObject({
      method: 'POST',
      url: 'http://api.test/auth/login',
      body: { email: 'jane@example.com', password: 'secret1' },
    });
  });

  it('me requests GET /auth/me', async () => {
    const { auth, calls } = setup({ user: { id: 'u-1' } });

    const result = await auth.me();

    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://api.test/auth/me' });
    expect(result).toEqual({ user: { id: 'u-1' } });
  });

  it('getInstagramConnectUrl POSTs /auth/instagram/connect-url', async () => {
    const { auth, calls } = setup({ url: 'https://facebook.com/oauth' });

    await auth.getInstagramConnectUrl();

    expect(calls[0]).toMatchObject({ method: 'POST', url: 'http://api.test/auth/instagram/connect-url' });
  });

  it('disconnectInstagram DELETEs /auth/instagram/:igUserId', async () => {
    const { auth, calls } = setup({ ok: true });

    await auth.disconnectInstagram('ig-42');

    expect(calls[0]).toMatchObject({ method: 'DELETE', url: 'http://api.test/auth/instagram/ig-42' });
  });
});
