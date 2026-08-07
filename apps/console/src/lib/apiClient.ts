/**
 * src/lib/apiClient — the console's platform adapter for @lacasa/api-client:
 * a fetch-based Transport + a localStorage-backed TokenStorage, mirroring
 * apps/web/src/lib/httpTransport.js's axios adapter one-for-one (same
 * TOKEN_KEY, same baseUrl fallback, same async-wrapped-sync TokenStorage —
 * see core/transport.ts's doc comment on why that has to stay async even
 * though localStorage itself is sync). This app has no axios dependency and
 * doesn't need one: fetch already does everything the transport contract
 * asks for.
 */
import { createLaCasaApiClient, type LaCasaApiClient, type Transport, type TokenStorage } from '@lacasa/api-client';
import { ApiError, type ErrorCode } from '@lacasa/domain';

export const TOKEN_KEY = 'lacasa_token';

export function resolveBaseUrl(envUrl?: string): string {
  return envUrl ?? 'http://localhost:4200/api';
}

export const localStorageTokenStorage: TokenStorage = {
  getToken() {
    return Promise.resolve(localStorage.getItem(TOKEN_KEY));
  },
  setToken(token: string | null) {
    if (token) {
      localStorage.setItem(TOKEN_KEY, token);
    } else {
      localStorage.removeItem(TOKEN_KEY);
    }
    return Promise.resolve();
  },
};

// Every code the API's `{ error: { code, message } }` body can carry
// (packages/domain/src/errors.ts's ERROR_CODES) — checked structurally
// rather than trusted blindly, since a non-2xx body that isn't ours (a
// proxy's HTML error page, a stray 502) must not be reconstructed into a
// well-typed ApiError with a made-up code.
function isApiErrorBody(value: unknown): value is { error: { code: string; message: string } } {
  if (typeof value !== 'object' || value === null || !('error' in value)) return false;
  const err = (value as { error: unknown }).error;
  return (
    typeof err === 'object' &&
    err !== null &&
    typeof (err as { code: unknown }).code === 'string' &&
    typeof (err as { message: unknown }).message === 'string'
  );
}

function buildUrl(url: string, query?: Record<string, string | number | boolean | undefined | null>): string {
  if (!query) return url;
  const params = new URLSearchParams();
  for (const [key, value] of Object.entries(query)) {
    if (value === undefined || value === null) continue;
    params.set(key, String(value));
  }
  const qs = params.toString();
  return qs ? `${url}?${qs}` : url;
}

/**
 * Reconstructs a non-2xx response into the same ApiError shape every
 * platform's callers branch on. A body that doesn't parse as JSON, or
 * parses but isn't `{ error: { code, message } }` (an upstream proxy's
 * plain-text 502, e.g.), still has to become a real ApiError rather than a
 * generic thrown string — callers only ever catch ApiError.
 */
async function toApiError(response: Response): Promise<ApiError> {
  let body: unknown;
  try {
    body = await response.json();
  } catch {
    body = undefined;
  }
  if (isApiErrorBody(body)) {
    return ApiError.fromResponseBody(body as { error: { code: ErrorCode; message: string } }, response.status);
  }
  return new ApiError('internal', response.statusText || `Request failed with status ${response.status}`, response.status);
}

export const fetchTransport: Transport = {
  async request<T>({ method, url, query, body, headers }: Parameters<Transport['request']>[0]) {
    const finalHeaders: Record<string, string> = { ...headers };
    // Only set Content-Type when there's actually a body to describe — a
    // GET/DELETE with no body shouldn't advertise a JSON payload that never
    // arrives.
    if (body !== undefined) {
      finalHeaders['Content-Type'] = 'application/json';
    }

    const response = await fetch(buildUrl(url, query), {
      method,
      headers: finalHeaders,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });

    if (!response.ok) {
      throw await toApiError(response);
    }

    // A 204 (DELETE, most often) has no JSON to parse — trying anyway
    // throws on the empty body. Content-Length is also checked because some
    // 200s (rare, but seen from proxies) come back genuinely empty too.
    if (response.status === 204 || response.headers.get('content-length') === '0') {
      return undefined as T;
    }
    const text = await response.text();
    if (!text) return undefined as T;
    return JSON.parse(text) as T;
  },
};

export const apiClient: LaCasaApiClient = createLaCasaApiClient({
  transport: fetchTransport,
  tokenStorage: localStorageTokenStorage,
  baseUrl: resolveBaseUrl(import.meta.env.VITE_API_URL),
});
