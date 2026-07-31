import axios from "axios";

// Formerly src/lib/api.js. Same axios instance, same localStorage-backed
// bearer token, same baseURL fallback — every call site that hasn't been
// migrated onto ./apiClient.js yet still imports `api`/`getAuthToken`/
// `setAuthToken` from ./api.js, which now just re-exports them from here.
const TOKEN_KEY = "lacasa_token";

export function resolveBaseUrl(envUrl) {
  return envUrl ?? "http://localhost:4200/api";
}

export const api = axios.create({
  baseURL: resolveBaseUrl(import.meta.env.VITE_API_URL),
});

export function attachAuthHeader(config) {
  const token = getAuthToken();
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
}

api.interceptors.request.use(attachAuthHeader);

export function getAuthToken() {
  return localStorage.getItem(TOKEN_KEY);
}

export function setAuthToken(token) {
  if (token) {
    localStorage.setItem(TOKEN_KEY, token);
  } else {
    localStorage.removeItem(TOKEN_KEY);
  }
}

// ---------------------------------------------------------------------------
// @lacasa/api-client adapter — see src/lib/apiClient.js for the wiring.

/**
 * TokenStorage: @lacasa/api-client's contract is async-only from the start
 * (apps/mobile's future expo-secure-store only exposes getItemAsync, which
 * is Promise-only — a sync interface here would force every consumer to be
 * rewritten once mobile lands). The synchronous localStorage reads/writes
 * above get wrapped in Promise.resolve() so this adapter, not every
 * caller, absorbs the one place web's storage happens to be sync.
 */
export const localStorageTokenStorage = {
  getToken() {
    return Promise.resolve(getAuthToken());
  },
  setToken(token) {
    setAuthToken(token);
    return Promise.resolve();
  },
};

/**
 * Transport: @lacasa/api-client's core/client.ts already resolves the full
 * URL (baseUrl + path) and attaches the Authorization header itself before
 * calling this, so it talks to axios directly rather than through the
 * `api` instance above — that instance's own baseURL/interceptor would be
 * redundant (and, for baseURL, wrong: `api`'s is meant to prefix relative
 * paths, but requests arrive here with an already-absolute url).
 */
export const axiosTransport = {
  async request({ method, url, query, body, headers }) {
    const { data } = await axios.request({
      method,
      url,
      params: query,
      data: body,
      headers,
    });
    return data;
  },
};
