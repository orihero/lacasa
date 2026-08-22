import { describe, expect, it, beforeEach } from 'vitest';
import { http, HttpResponse } from 'msw';
import { server } from '@lacasa/config-vitest/react/server';
import { ApiError } from '@lacasa/domain';
import { fetchTransport, localStorageTokenStorage, resolveBaseUrl, TOKEN_KEY } from '../apiClient';

const BASE = 'http://localhost/api';

describe('resolveBaseUrl', () => {
  it('falls back to the local API when no env url is given', () => {
    expect(resolveBaseUrl(undefined)).toBe('http://localhost:4200/api');
  });

  it('passes through an explicit env url unchanged', () => {
    expect(resolveBaseUrl('https://api.example.com')).toBe('https://api.example.com');
  });
});

describe('localStorageTokenStorage', () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it('round-trips a token through localStorage', async () => {
    await localStorageTokenStorage.setToken('abc123');
    expect(localStorage.getItem(TOKEN_KEY)).toBe('abc123');
    await expect(localStorageTokenStorage.getToken()).resolves.toBe('abc123');
  });

  it('resolves null when nothing has been stored', async () => {
    await expect(localStorageTokenStorage.getToken()).resolves.toBeNull();
  });

  it('clears the token when set to null', async () => {
    await localStorageTokenStorage.setToken('abc123');
    await localStorageTokenStorage.setToken(null);
    expect(localStorage.getItem(TOKEN_KEY)).toBeNull();
    await expect(localStorageTokenStorage.getToken()).resolves.toBeNull();
  });
});

describe('fetchTransport', () => {
  it('serialises query params, skipping undefined and null', async () => {
    let capturedUrl = '';
    server.use(
      http.get(`${BASE}/things`, ({ request }) => {
        capturedUrl = request.url;
        return HttpResponse.json({ ok: true });
      }),
    );

    await fetchTransport.request({
      method: 'GET',
      url: `${BASE}/things`,
      query: { city: 'Tashkent', district: undefined, page: 2, active: null },
    });

    const params = new URL(capturedUrl).searchParams;
    expect(params.get('city')).toBe('Tashkent');
    expect(params.get('page')).toBe('2');
    expect(params.has('district')).toBe(false);
    expect(params.has('active')).toBe(false);
  });

  it('omits the query string entirely when there are no params', async () => {
    let capturedUrl = '';
    server.use(
      http.get(`${BASE}/things`, ({ request }) => {
        capturedUrl = request.url;
        return HttpResponse.json([]);
      }),
    );

    await fetchTransport.request({ method: 'GET', url: `${BASE}/things` });
    expect(capturedUrl).toBe(`${BASE}/things`);
  });

  it('sends Content-Type: application/json only when there is a body', async () => {
    let getContentType: string | null = null;
    let postContentType: string | null = null;
    server.use(
      http.get(`${BASE}/no-body`, ({ request }) => {
        getContentType = request.headers.get('content-type');
        return new HttpResponse(null, { status: 204 });
      }),
      http.post(`${BASE}/with-body`, ({ request }) => {
        postContentType = request.headers.get('content-type');
        return HttpResponse.json({ ok: true });
      }),
    );

    await fetchTransport.request({ method: 'GET', url: `${BASE}/no-body` });
    await fetchTransport.request({ method: 'POST', url: `${BASE}/with-body`, body: { a: 1 } });

    expect(getContentType).toBeNull();
    expect(postContentType).toContain('application/json');
  });

  it('reconstructs a non-2xx { error: { code, message } } body into an ApiError', async () => {
    server.use(
      http.post(`${BASE}/leads`, () =>
        HttpResponse.json({ error: { code: 'validation', message: 'fullName is required' } }, { status: 400 }),
      ),
    );

    const call = fetchTransport.request({ method: 'POST', url: `${BASE}/leads`, body: {} });
    await expect(call).rejects.toBeInstanceOf(ApiError);
    await call.catch((error: ApiError) => {
      expect(error.code).toBe('validation');
      expect(error.message).toBe('fullName is required');
      expect(error.status).toBe(400);
    });
  });

  it('falls back to a generic ApiError when a non-2xx body is not the expected shape', async () => {
    server.use(http.get(`${BASE}/broken`, () => new HttpResponse('<html>Bad Gateway</html>', { status: 502 })));

    const call = fetchTransport.request({ method: 'GET', url: `${BASE}/broken` });
    await expect(call).rejects.toBeInstanceOf(ApiError);
    await call.catch((error: ApiError) => {
      expect(error.status).toBe(502);
      expect(error.code).toBe('internal');
    });
  });

  it('resolves undefined for a 204 with no body instead of throwing on empty JSON', async () => {
    server.use(http.delete(`${BASE}/leads/1`, () => new HttpResponse(null, { status: 204 })));

    await expect(fetchTransport.request({ method: 'DELETE', url: `${BASE}/leads/1` })).resolves.toBeUndefined();
  });

  it('parses a normal 2xx JSON body', async () => {
    server.use(http.get(`${BASE}/leads/1`, () => HttpResponse.json({ id: '1', fullName: 'Aziz Karimov' })));

    await expect(fetchTransport.request({ method: 'GET', url: `${BASE}/leads/1` })).resolves.toEqual({
      id: '1',
      fullName: 'Aziz Karimov',
    });
  });
});
