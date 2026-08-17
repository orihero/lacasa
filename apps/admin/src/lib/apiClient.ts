/**
 * src/lib/apiClient — the control room's platform adapter for
 * @lacasa/api-client: a fetch-based Transport + a localStorage-backed
 * TokenStorage, mirroring apps/console/src/lib/apiClient.ts one-for-one.
 *
 * THE TOKEN KEY IS DELIBERATELY DIFFERENT from the console's and the web
 * app's `lacasa_token`. All three surfaces are served from localhost during
 * development, and localStorage is keyed per ORIGIN, not per port — so a
 * shared key would mean signing into the console silently signs you into the
 * control room in the next tab, and signing out of one signs you out of the
 * other. Neither is a security boundary (the server enforces the ADMIN role
 * on every request either way), but "I was already logged in, so I must be on
 * the right surface" is precisely the confusion this app's whole palette
 * exists to prevent.
 */
import {
  createLaCasaApiClient,
  type LaCasaApiClient,
  type Transport,
  type TokenStorage,
} from "@lacasa/api-client";
import { ApiError, type ErrorCode } from "@lacasa/domain";

export const TOKEN_KEY = "lacasa_admin_token";

export function resolveBaseUrl(envUrl?: string): string {
  return envUrl ?? "http://localhost:4200/api";
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
// (packages/domain/src/errors.ts's ERROR_CODES) — checked structurally rather
// than trusted blindly, since a non-2xx body that isn't ours (a proxy's HTML
// error page, a stray 502) must not be reconstructed into a well-typed
// ApiError with a made-up code.
function isApiErrorBody(value: unknown): value is { error: { code: string; message: string } } {
  if (typeof value !== "object" || value === null || !("error" in value)) return false;
  const err = (value as { error: unknown }).error;
  return (
    typeof err === "object" &&
    err !== null &&
    typeof (err as { code: unknown }).code === "string" &&
    typeof (err as { message: unknown }).message === "string"
  );
}

function buildUrl(
  url: string,
  query?: Record<string, string | number | boolean | undefined | null>,
): string {
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
 * branches on. A body that doesn't parse as JSON, or parses but isn't
 * `{ error: { code, message } }` (an upstream proxy's plain-text 502, e.g.),
 * still has to become a real ApiError rather than a generic thrown string —
 * callers only ever catch ApiError.
 */
async function toApiError(response: Response): Promise<ApiError> {
  let body: unknown;
  try {
    body = await response.json();
  } catch {
    body = undefined;
  }
  if (isApiErrorBody(body)) {
    return ApiError.fromResponseBody(
      body as { error: { code: ErrorCode; message: string } },
      response.status,
    );
  }
  return new ApiError(
    "internal",
    response.statusText || `Request failed with status ${response.status}`,
    response.status,
  );
}

export const fetchTransport: Transport = {
  async request<T>({ method, url, query, body, headers }: Parameters<Transport["request"]>[0]) {
    const finalHeaders: Record<string, string> = { ...headers };
    // Only set Content-Type when there's actually a body to describe — a
    // GET/DELETE with no body shouldn't advertise a JSON payload that never
    // arrives.
    if (body !== undefined) {
      finalHeaders["Content-Type"] = "application/json";
    }

    const response = await fetch(buildUrl(url, query), {
      method,
      headers: finalHeaders,
      body: body !== undefined ? JSON.stringify(body) : undefined,
    });

    if (!response.ok) {
      throw await toApiError(response);
    }

    // A 204 has no JSON to parse — trying anyway throws on the empty body.
    // Content-Length is also checked because some 200s (rare, but seen from
    // proxies) come back genuinely empty too.
    if (response.status === 204 || response.headers.get("content-length") === "0") {
      return undefined as T;
    }
    const text = await response.text();
    if (!text) return undefined as T;
    return JSON.parse(text) as T;
  },
};

export const API_BASE_URL = resolveBaseUrl(import.meta.env.VITE_API_URL);

export const apiClient: LaCasaApiClient = createLaCasaApiClient({
  transport: fetchTransport,
  tokenStorage: localStorageTokenStorage,
  baseUrl: API_BASE_URL,
});
