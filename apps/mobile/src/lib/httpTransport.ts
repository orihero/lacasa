/**
 * apps/mobile's implementation of @lacasa/api-client's two injected
 * contracts (see @lacasa/api-client's core/transport.ts):
 *
 *  - TokenStorage, backed by expo-secure-store. Unlike apps/web's
 *    localStorage-backed adapter (a sync API wrapped in Promise.resolve()),
 *    SecureStore.getItemAsync/setItemAsync are natively Promise-based — the
 *    exact reason the shared contract was written async-only from the
 *    start.
 *  - Transport, backed by fetch. Reconstructs a domain ApiError from any
 *    non-2xx JSON body shaped like `{ error: { code, message } }`, per
 *    transport.ts's Transport doc comment; falls back to a generic
 *    'internal' ApiError when the body isn't in that shape (network
 *    failure, HTML error page, etc).
 */
import * as SecureStore from 'expo-secure-store';
import { ApiError, type ApiErrorBody } from '@lacasa/domain/errors';
import type { Transport, TransportRequest, TokenStorage } from '@lacasa/api-client';

const TOKEN_KEY = 'lacasa_token';

export function resolveBaseUrl(envUrl: string | undefined): string {
  return envUrl ?? 'http://localhost:4200/api';
}

export const secureStoreTokenStorage: TokenStorage = {
  getToken(): Promise<string | null> {
    return SecureStore.getItemAsync(TOKEN_KEY);
  },
  async setToken(token: string | null): Promise<void> {
    if (token) {
      await SecureStore.setItemAsync(TOKEN_KEY, token);
    } else {
      await SecureStore.deleteItemAsync(TOKEN_KEY);
    }
  },
};

function buildUrl(url: string, query: TransportRequest['query']): string {
  if (!query) return url;
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null) continue;
    params.append(key, String(value));
  }
  const qs = params.toString();
  return qs ? `${url}?${qs}` : url;
}

function isApiErrorBody(value: unknown): value is { error: ApiErrorBody } {
  return (
    typeof value === 'object' &&
    value !== null &&
    'error' in value &&
    typeof (value as { error: unknown }).error === 'object' &&
    (value as { error: { code?: unknown } }).error !== null &&
    typeof (value as { error: { code?: unknown } }).error.code === 'string'
  );
}

export const fetchTransport: Transport = {
  async request<T>(req: TransportRequest): Promise<T> {
    const response = await fetch(buildUrl(req.url, req.query), {
      method: req.method,
      headers: {
        'Content-Type': 'application/json',
        ...req.headers,
      },
      body: req.body === undefined ? undefined : JSON.stringify(req.body),
    });

    const text = await response.text();
    const data = text ? JSON.parse(text) : undefined;

    if (!response.ok) {
      if (isApiErrorBody(data)) {
        throw ApiError.fromResponseBody(data, response.status);
      }
      throw new ApiError('internal', response.statusText || 'Request failed', response.status);
    }

    return data as T;
  },
};
