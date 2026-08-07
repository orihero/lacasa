/**
 * @lacasa/api-client/resources/publish — ports the server-side Instagram
 * publish calls out of apps/web/src/services/crosspost.ts. The
 * postMessage handshake with the browser extension (pingExtension,
 * requestCrosspost) is intentionally NOT ported here: it never touches the
 * network through this client — it's a same-window postMessage exchange
 * with a content script, which doesn't exist as a concept on mobile. That
 * stays app-level in apps/web.
 */
import type { ConfirmInput, IgPublishInput, MapFieldsInput, ReassignInput } from '@lacasa/domain';
import type { AssistedChannel } from '@lacasa/domain/enums';
import type { ApiClient } from '../core/client';

export interface IgPublishResult {
  igUserId: string;
  igUsername: string | null;
  ok: boolean;
  mediaId?: string;
  error?: string;
}

export interface Publication {
  id: string;
  adId: string;
  channel: string;
  status: string;
  externalId: string | null;
  externalUrl: string | null;
  attempts: number;
  lastAttemptAt: string | null;
  publishedAt: string | null;
  errorMessage: string | null;
}

export interface InstagramAccount {
  igUserId: string;
  username: string | null;
  expiresAt: string | null;
  id?: string;
  profile_picture_url?: string;
  followers_count?: number;
  follows_count?: number;
  media_count?: number;
}

export interface PublishStatusChannel {
  channel: string;
  status: string;
  externalUrl: string | null;
  externalId: string | null;
  lastAttemptAt: string | null;
  errorMessage: string | null;
}

export function createPublishResource(client: ApiClient) {
  return {
    publishInstagram(input: IgPublishInput) {
      return client.request<{ publication: Publication; results: IgPublishResult[] }>({
        method: 'POST',
        path: '/publish/instagram',
        body: input,
      });
    },

    getInstagramAccounts() {
      return client.request<{ accounts: InstagramAccount[] }>({
        method: 'GET',
        path: '/publish/instagram/accounts',
      });
    },

    grantInstagramAssistConsent() {
      return client.request<{ ok: boolean; igAssistConsentAt: string }>({
        method: 'POST',
        path: '/publish/instagram/consent',
      });
    },

    // Extension-assisted publishing (OLX + Instagram fallback).
    mapFields(channel: AssistedChannel, input: MapFieldsInput) {
      return client.request<Record<string, unknown>>({
        method: 'POST',
        path: `/publish/${channel}/map-fields`,
        body: input,
      });
    },

    confirm(channel: AssistedChannel, input: ConfirmInput) {
      return client.request<{ publication: Publication }>({
        method: 'POST',
        path: `/publish/${channel}/confirm`,
        body: input,
      });
    },

    reassign(input: ReassignInput) {
      return client.request<{ moved: number }>({ method: 'POST', path: '/publish/reassign', body: input });
    },

    getStatusForAd(adId: string) {
      return client.request<{ adId: string; channels: PublishStatusChannel[] }>({
        method: 'GET',
        path: `/publish/ads/${adId}/status`,
      });
    },

    getStatusForAds(adIds: string[]) {
      return client.request<Record<string, Array<{ channel: string; status: string }>>>({
        method: 'GET',
        path: '/publish/status',
        query: { adIds: adIds.join(',') },
      });
    },
  };
}

export type PublishResource = ReturnType<typeof createPublishResource>;
