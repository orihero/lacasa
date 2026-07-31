import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest';
import { ApiError } from '@lacasa/domain/errors';

// A fake expo-secure-store: getItemAsync/setItemAsync/deleteItemAsync all
// Promise-based, backed by an in-memory map — exercises
// secureStoreTokenStorage without touching any native module. vi.mock
// calls are hoisted above imports by vitest, so this runs before
// ./httpTransport (below) evaluates its `import * as SecureStore` — see
// apps/web/src/lib/userStore.test.js for the same pattern.
const store = new Map<string, string>();
vi.mock('expo-secure-store', () => ({
  getItemAsync: vi.fn((key: string) => Promise.resolve(store.get(key) ?? null)),
  setItemAsync: vi.fn((key: string, value: string) => {
    store.set(key, value);
    return Promise.resolve();
  }),
  deleteItemAsync: vi.fn((key: string) => {
    store.delete(key);
    return Promise.resolve();
  }),
}));

import { secureStoreTokenStorage, fetchTransport, resolveBaseUrl } from './httpTransport';

describe('resolveBaseUrl', () => {
  it('falls back to localhost when no env url is configured', () => {
    expect(resolveBaseUrl(undefined)).toBe('http://localhost:4200/api');
  });

  it('passes through an explicit env url', () => {
    expect(resolveBaseUrl('https://api.example.com')).toBe('https://api.example.com');
  });
});

describe('secureStoreTokenStorage', () => {
  beforeEach(() => {
    store.clear();
  });

  it('returns null before any token has been set', async () => {
    await expect(secureStoreTokenStorage.getToken()).resolves.toBeNull();
  });

  it('round-trips a token through setToken/getToken', async () => {
    await secureStoreTokenStorage.setToken('secret-token');
    await expect(secureStoreTokenStorage.getToken()).resolves.toBe('secret-token');
  });

  it('deletes the stored token when set to null', async () => {
    await secureStoreTokenStorage.setToken('secret-token');
    await secureStoreTokenStorage.setToken(null);
    await expect(secureStoreTokenStorage.getToken()).resolves.toBeNull();
  });
});

describe('fetchTransport', () => {
  const originalFetch = global.fetch;

  afterEach(() => {
    global.fetch = originalFetch;
  });

  it('sends method/url/headers/body and returns the parsed JSON body', async () => {
    const fetchMock = vi.fn(async () => ({
      ok: true,
      status: 200,
      statusText: 'OK',
      text: async () => JSON.stringify({ id: '1' }),
    }));
    global.fetch = fetchMock as unknown as typeof fetch;

    const result = await fetchTransport.request<{ id: string }>({
      method: 'POST',
      url: 'https://api.example.com/leads',
      query: { page: 2, active: true, missing: undefined },
      body: { name: 'Jane' },
      headers: { Authorization: 'Bearer abc' },
    });

    expect(result).toEqual({ id: '1' });
    expect(fetchMock).toHaveBeenCalledWith(
      'https://api.example.com/leads?page=2&active=true',
      expect.objectContaining({
        method: 'POST',
        headers: { 'Content-Type': 'application/json', Authorization: 'Bearer abc' },
        body: JSON.stringify({ name: 'Jane' }),
      }),
    );
  });

  it('reconstructs an ApiError from a well-formed error body', async () => {
    global.fetch = vi.fn(async () => ({
      ok: false,
      status: 404,
      statusText: 'Not Found',
      text: async () => JSON.stringify({ error: { code: 'not_found', message: 'Lead not found' } }),
    })) as unknown as typeof fetch;

    await expect(
      fetchTransport.request({ method: 'GET', url: 'https://api.example.com/leads/1' }),
    ).rejects.toMatchObject(new ApiError('not_found', 'Lead not found', 404));
  });

  it('falls back to a generic internal ApiError for a non-JSON-error response', async () => {
    global.fetch = vi.fn(async () => ({
      ok: false,
      status: 500,
      statusText: 'Internal Server Error',
      text: async () => '',
    })) as unknown as typeof fetch;

    await expect(
      fetchTransport.request({ method: 'GET', url: 'https://api.example.com/leads/1' }),
    ).rejects.toMatchObject(new ApiError('internal', 'Internal Server Error', 500));
  });
});
