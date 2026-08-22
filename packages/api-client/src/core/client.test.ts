import { describe, expect, it } from 'vitest';
import { createApiClient } from './client';
import { createDelayedTokenStorage, createFakeTokenStorage, createFakeTransport } from '../testing/fakeTransport';

describe('createApiClient', () => {
  it('joins baseUrl and path into the transport request url', async () => {
    const { transport, calls } = createFakeTransport({ ok: true });
    const client = createApiClient({
      transport,
      tokenStorage: createFakeTokenStorage(null),
      baseUrl: 'http://localhost:4200/api',
    });

    await client.request({ method: 'GET', path: '/ads' });

    expect(calls).toHaveLength(1);
    expect(calls[0]).toMatchObject({ method: 'GET', url: 'http://localhost:4200/api/ads' });
  });

  it('forwards query and body through untouched', async () => {
    const { transport, calls } = createFakeTransport({});
    const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage(null), baseUrl: '' });

    await client.request({
      method: 'POST',
      path: '/leads',
      query: { active: true },
      body: { fullName: 'Test Lead' },
    });

    expect(calls[0]!.query).toEqual({ active: true });
    expect(calls[0]!.body).toEqual({ fullName: 'Test Lead' });
  });

  it('omits the Authorization header when there is no token', async () => {
    const { transport, calls } = createFakeTransport({});
    const client = createApiClient({ transport, tokenStorage: createFakeTokenStorage(null), baseUrl: '' });

    await client.request({ method: 'GET', path: '/ads' });

    expect(calls[0]!.headers?.Authorization).toBeUndefined();
  });

  it('attaches "Bearer <token>" once tokenStorage resolves synchronously', async () => {
    const { transport, calls } = createFakeTransport({});
    const client = createApiClient({
      transport,
      tokenStorage: createFakeTokenStorage('abc123'),
      baseUrl: '',
    });

    await client.request({ method: 'GET', path: '/ads' });

    expect(calls[0]!.headers?.Authorization).toBe('Bearer abc123');
  });

  it('preserves caller-supplied headers alongside Authorization', async () => {
    const { transport, calls } = createFakeTransport({});
    const client = createApiClient({
      transport,
      tokenStorage: createFakeTokenStorage('abc123'),
      baseUrl: '',
    });

    await client.request({
      method: 'GET',
      path: '/ads',
      headers: { 'X-Custom': 'yes' },
    });

    expect(calls[0]!.headers).toEqual({ 'X-Custom': 'yes', Authorization: 'Bearer abc123' });
  });

  // The mobile cold-start auth race: expo-secure-store's getItemAsync is
  // Promise-only and can be slow on a cold launch. A client that built the
  // Authorization header off a sync-looking read would fire the request
  // before the token ever attached. This proves createApiClient can't do
  // that, regardless of how slow tokenStorage.getToken() is.
  it('waits for a delayed TokenStorage.getToken() before invoking the transport', async () => {
    const { transport, calls } = createFakeTransport({});
    const { tokenStorage, resolved } = createDelayedTokenStorage('cold-start-token', 30);
    const client = createApiClient({ transport, tokenStorage, baseUrl: '' });

    const pending = client.request({ method: 'GET', path: '/ads' });

    // Synchronously after calling request(), the delayed token hasn't
    // resolved yet, so the transport must not have fired.
    expect(resolved.current).toBe(false);
    expect(calls).toHaveLength(0);

    const result = await pending;

    expect(resolved.current).toBe(true);
    expect(calls).toHaveLength(1);
    expect(calls[0]!.headers?.Authorization).toBe('Bearer cold-start-token');
    expect(result).toEqual({});
  });
});
