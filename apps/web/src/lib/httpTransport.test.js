import { beforeEach, describe, expect, it } from "vitest";
import {
  api,
  attachAuthHeader,
  getAuthToken,
  localStorageTokenStorage,
  resolveBaseUrl,
  setAuthToken,
} from "./httpTransport";

describe("httpTransport", () => {
  beforeEach(() => {
    localStorage.clear();
  });

  it("resolveBaseUrl falls back to http://localhost:4200/api when VITE_API_URL is unset", () => {
    expect(resolveBaseUrl(undefined)).toBe("http://localhost:4200/api");
  });

  it("resolveBaseUrl uses VITE_API_URL when it's set", () => {
    expect(resolveBaseUrl("https://api.example.com")).toBe("https://api.example.com");
  });

  it("the exported `api` axios instance is built from resolveBaseUrl", () => {
    // Documents that `api`'s baseURL isn't hand-duplicated logic — it's
    // whatever resolveBaseUrl(import.meta.env.VITE_API_URL) returns, which
    // the two tests above already pin down for both branches.
    expect(api.defaults.baseURL).toBe(resolveBaseUrl(import.meta.env.VITE_API_URL));
  });

  it("attachAuthHeader attaches the stored bearer token to the Authorization header", () => {
    setAuthToken("tok-123");

    const config = attachAuthHeader({ headers: {} });

    expect(config.headers.Authorization).toBe("Bearer tok-123");
  });

  it("attachAuthHeader leaves the Authorization header untouched when there is no token", () => {
    setAuthToken(null);

    const config = attachAuthHeader({ headers: {} });

    expect(config.headers.Authorization).toBeUndefined();
  });

  it("api's request interceptor is attachAuthHeader, so real requests get the same token", () => {
    setAuthToken("tok-456");

    const config = api.interceptors.request.handlers[0].fulfilled({ headers: {} });

    expect(config.headers.Authorization).toBe("Bearer tok-456");
  });

  it("getAuthToken/setAuthToken round-trip through localStorage", () => {
    expect(getAuthToken()).toBeNull();

    setAuthToken("round-trip-token");
    expect(getAuthToken()).toBe("round-trip-token");

    setAuthToken(null);
    expect(getAuthToken()).toBeNull();
  });

  it("localStorageTokenStorage wraps the same localStorage-backed token in @lacasa/api-client's async TokenStorage contract", async () => {
    await localStorageTokenStorage.setToken("async-token");

    await expect(localStorageTokenStorage.getToken()).resolves.toBe("async-token");
    // Same underlying storage as the sync helpers, not a separate copy.
    expect(getAuthToken()).toBe("async-token");

    await localStorageTokenStorage.setToken(null);
    await expect(localStorageTokenStorage.getToken()).resolves.toBeNull();
  });
});
