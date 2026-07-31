/**
 * @lacasa/api-client/core/transport — the two contracts every environment
 * (apps/web's axios+localStorage today, apps/mobile's fetch+expo-secure-store
 * tomorrow) must implement to plug into createApiClient (./client.ts).
 *
 * Nothing in this file — or anywhere under src/core — may assume a browser:
 * no axios, no localStorage, no fetch, no `import.meta`. That's enforced
 * mechanically by @lacasa/config-eslint/boundaries (see this package's
 * .eslintrc.cjs), not just by convention.
 */

export type HttpMethod = 'GET' | 'POST' | 'PATCH' | 'PUT' | 'DELETE';

export type QueryValue = string | number | boolean | undefined | null;
export type QueryParams = Record<string, QueryValue>;

/** A single outbound HTTP call, already resolved to an absolute URL. */
export interface TransportRequest {
  method: HttpMethod;
  url: string;
  query?: QueryParams;
  body?: unknown;
  headers?: Record<string, string>;
}

/**
 * The one thing every platform must supply: a function that turns a
 * TransportRequest into a parsed response body, or throws/rejects for a
 * non-2xx response. @lacasa/domain's ApiError is the shape a Transport
 * implementation should reconstruct failures into, so callers on every
 * platform can branch on the same `{ code, message, status }`.
 */
export interface Transport {
  request<T>(req: TransportRequest): Promise<T>;
}

/**
 * Token persistence, injected. MUST be async from the start: this is the
 * one decision that has to be right before apps/mobile exists. Expo's
 * expo-secure-store exposes only getItemAsync/setItemAsync (Promise-only) —
 * a sync interface here (the way apps/web/src/lib/api.js's localStorage
 * reads work today) would force every consumer of this package to be
 * rewritten the day mobile lands. Web's adapter just wraps its sync
 * localStorage reads in Promise.resolve(); that costs nothing there and
 * saves a rewrite later.
 */
export interface TokenStorage {
  getToken(): Promise<string | null>;
  setToken(token: string | null): Promise<void>;
}
