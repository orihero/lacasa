import { createLaCasaApiClient } from '@lacasa/api-client';
import { fetchTransport, resolveBaseUrl, secureStoreTokenStorage } from './httpTransport';

// The typed, resource-grouped @lacasa/api-client client for apps/mobile —
// same shape as apps/web's src/lib/apiClient.js, wired to this platform's
// fetch + expo-secure-store adapters instead of web's axios + localStorage.
export const apiClient = createLaCasaApiClient({
  transport: fetchTransport,
  tokenStorage: secureStoreTokenStorage,
  baseUrl: resolveBaseUrl(process.env.EXPO_PUBLIC_API_URL),
});
