import { createLaCasaApiClient } from "@lacasa/api-client";
import { axiosTransport, localStorageTokenStorage, resolveBaseUrl } from "./httpTransport";

// The typed, resource-grouped @lacasa/api-client client for apps/web:
// apiClient.ads.getAds(...), apiClient.leads.list(), etc. Shares the same
// baseURL fallback and localStorage-backed token as the legacy `api` axios
// instance (./httpTransport.js) so both can be in flight during the
// store-by-store migration off raw api.get/post calls.
export const apiClient = createLaCasaApiClient({
  transport: axiosTransport,
  tokenStorage: localStorageTokenStorage,
  baseUrl: resolveBaseUrl(import.meta.env.VITE_API_URL),
});
