/**
 * src/lib/apiClient — the control room's platform adapter for
 * @lacasa/api-client: an axios-based Transport + a localStorage-backed
 * TokenStorage.
 *
 * THE TOKEN KEY IS DELIBERATELY DIFFERENT from the console's and the web
 * app's `lacasa_token`. All three surfaces are served from localhost during
 * development, and localStorage is keyed per ORIGIN, not per port — so a
 * shared key would mean signing into the console silently signs you into the
 * control room in the next tab, and signing out of one signs you out of the
 * other. Neither is a security boundary (the server enforces the ADMIN role
 * on every request either way), but "I was already logged in, so I must be on
 * the right surface" is precisely the confusion this app exists to prevent.
 *
 * WHY AXIOS AND NOT `fetch`: apps/web's src/lib/httpTransport.js is the house
 * transport and axios is already a dependency of the monorepo's frontends.
 * Nothing about the *behaviour* below is axios's, though — the three things
 * this transport is actually responsible for are hand-rolled on purpose:
 *
 *  1. QUERY SERIALISATION. `buildUrl` skips BOTH `undefined` and `null` and
 *     omits the key entirely; it never relies on "null serialises as the
 *     string `null`", because it doesn't. Handing axios a `params` object
 *     instead would move that rule into axios's own encoder, whose escaping
 *     rules differ from URLSearchParams' (`:` and `[]` are left raw) and can
 *     change under a minor version. The one part of this file the tests pin
 *     is the exact URL that goes out, so the code that builds it lives here.
 *  2. ERROR NORMALISATION. Every caller on this surface catches ApiError and
 *     branches on `.code`/`.status`; an AxiosError leaking through would make
 *     `ApiError.isApiError(error)` false and quietly defeat both the 401
 *     token-clear rule and the retry policy in ./queryClient.
 *  3. EMPTY BODIES. A 204 (or a proxy's genuinely empty 200) must resolve to
 *     `undefined`, not to axios's `""`.
 *
 * A transport-level failure with no response at all (DNS, offline, CORS) is
 * rethrown UNCHANGED rather than dressed up as an ApiError. That is what
 * keeps lib/auth's "only a 401 clears the token" rule honest: a network blip
 * must not be able to look like a 401, and it must not be able to look like a
 * well-typed server error either.
 */
import axios from "axios";
import {
  createLaCasaApiClient,
  type LaCasaApiClient,
  type QueryParams,
  type Transport,
  type TokenStorage,
} from "@lacasa/api-client";
import { ApiError, type ErrorCode } from "@lacasa/domain";

/** Deliberately not the `lacasa_token` apps/web and apps/console share. */
export const TOKEN_KEY = "lacasa_admin_token";

export function resolveBaseUrl(envUrl?: string): string {
  return envUrl ?? "http://localhost:4200/api";
}

/**
 * The ONE module that knows how the token is persisted. AuthProvider never
 * reads localStorage directly — it asks this. It has to be exported on its
 * own because createLaCasaApiClient() returns only the resource groups
 * (auth, admin, …), not the underlying ApiClient's `.tokenStorage`.
 *
 * Async by contract (see @lacasa/api-client/core/transport): web's sync
 * localStorage reads are wrapped here so no caller has to care.
 */
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

/**
 * Every code the API's `{ error: { code, message } }` body can carry
 * (packages/domain/src/errors.ts's ERROR_CODES) — checked structurally rather
 * than trusted blindly, since a non-2xx body that isn't ours (a proxy's HTML
 * error page, a stray 502) must not be reconstructed into a well-typed
 * ApiError with a made-up code.
 */
export function isApiErrorBody(
  value: unknown,
): value is { error: { code: string; message: string } } {
  if (typeof value !== "object" || value === null || !("error" in value)) return false;
  const err = (value as { error: unknown }).error;
  return (
    typeof err === "object" &&
    err !== null &&
    typeof (err as { code: unknown }).code === "string" &&
    typeof (err as { message: unknown }).message === "string"
  );
}

/**
 * `url` plus a query string built from the defined entries only.
 *
 * A key whose value is `undefined` or `null` is OMITTED ENTIRELY — it never
 * becomes `?cursor=` or `?cursor=null`. Both of those mean something specific
 * to the admin endpoints (an empty cursor is not the same as no cursor), and
 * the keyset pagination on every list here is built out of exactly this.
 *
 * Returns `url` untouched when there is nothing to append, so a request with
 * an all-`undefined` filter set is byte-identical to one with no query at all
 * — which is what lets it share a react-query cache entry with it.
 */
export function buildUrl(url: string, query?: QueryParams): string {
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
 * Reconstructs a non-2xx response into the same ApiError shape every caller
 * branches on. A body that isn't `{ error: { code, message } }` — an upstream
 * proxy's plain-text 502, an HTML error page, a body that never parsed as
 * JSON at all — still has to become a real ApiError rather than a generic
 * thrown value, because callers only ever catch ApiError. It gets the honest
 * `internal` code and the status line as its message; a fabricated error code
 * would be worse than none.
 */
export function toApiError(status: number, statusText: string, body: unknown): ApiError {
  if (isApiErrorBody(body)) {
    return ApiError.fromResponseBody(body as { error: { code: ErrorCode; message: string } }, status);
  }
  return new ApiError("internal", statusText || `Request failed with status ${status}`, status);
}

export const axiosTransport: Transport = {
  async request<T>({ method, url, query, body, headers }: Parameters<Transport["request"]>[0]) {
    const finalHeaders: Record<string, string> = { ...headers };
    // Only set Content-Type when there is actually a body to describe — a
    // GET/DELETE with no body should not advertise a JSON payload that never
    // arrives.
    if (body !== undefined) {
      finalHeaders["Content-Type"] = "application/json";
    }

    let response;
    try {
      response = await axios.request<T>({
        method,
        // The query string is already on the URL; passing `params` as well
        // would let axios re-encode it under its own rules. See the file
        // header.
        url: buildUrl(url, query),
        data: body,
        headers: finalHeaders,
        // JSON in, JSON out. `transformResponse` is left at the default,
        // which parses when it can and hands back the raw string when it
        // cannot — exactly the fallback toApiError() is written against.
        responseType: "json",
      });
    } catch (error) {
      if (axios.isAxiosError(error) && error.response) {
        throw toApiError(error.response.status, error.response.statusText, error.response.data);
      }
      // No response: DNS failure, offline, a cancelled request, CORS. Not an
      // ApiError, on purpose — see the file header.
      throw error;
    }

    // A 204 has no JSON to parse. Content-Length is checked too because some
    // 200s (rare, but seen from proxies) come back genuinely empty, and axios
    // reports an empty body as the empty string rather than as `undefined`.
    if (response.status === 204) return undefined as T;
    if (response.headers["content-length"] === "0") return undefined as T;
    if (response.data === undefined || (response.data as unknown) === "") {
      return undefined as T;
    }
    return response.data;
  },
};

export const API_BASE_URL: string = resolveBaseUrl(import.meta.env.VITE_API_URL);

export const apiClient: LaCasaApiClient = createLaCasaApiClient({
  transport: axiosTransport,
  tokenStorage: localStorageTokenStorage,
  baseUrl: API_BASE_URL,
});
