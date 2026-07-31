/**
 * @lacasa/api-client/resources/auth — ports the auth-related calls out of
 * apps/web/src/lib/userStore.js, routes/register.jsx, routes/login.jsx, and
 * the Instagram-connect calls out of services/crosspost.ts (those hit
 * /api/auth/instagram/*, so they belong here rather than in publish.ts).
 *
 * Enrichment that userStore.js did client-side after GET /auth/me (mapping
 * tgChatIds through TGService.init, backfilling igAccounts from
 * GET /publish/instagram/accounts) is deliberately NOT reproduced here —
 * that's application-level orchestration across two calls, not request
 * shaping, and stays in the caller (apps/web's userStore, and whatever
 * apps/mobile's equivalent turns out to be).
 */
import type { LoginInput, RegisterInput } from '@lacasa/domain';
import type { ApiClient } from '../core/client';

export interface AuthUser {
  id: string;
  fullName: string;
  email: string;
  phoneNumber: string | null;
  role: string;
  avatar?: string | null;
  agentId?: string | null;
  tgChatIds?: string[];
  igAccounts?: Array<{ igUserId: string; username: string | null; expiresAt: string | null }>;
  [key: string]: unknown;
}

export interface AuthResponse {
  token: string;
  user: AuthUser;
}

export interface MeResponse {
  user: AuthUser;
}

export function createAuthResource(client: ApiClient) {
  return {
    register(input: RegisterInput) {
      return client.request<AuthResponse>({ method: 'POST', path: '/auth/register', body: input });
    },

    login(input: LoginInput) {
      return client.request<AuthResponse>({ method: 'POST', path: '/auth/login', body: input });
    },

    me() {
      return client.request<MeResponse>({ method: 'GET', path: '/auth/me' });
    },

    getInstagramConnectUrl() {
      return client.request<{ url: string }>({ method: 'POST', path: '/auth/instagram/connect-url' });
    },

    disconnectInstagram(igUserId: string) {
      return client.request<{ ok: boolean }>({ method: 'DELETE', path: `/auth/instagram/${igUserId}` });
    },
  };
}

export type AuthResource = ReturnType<typeof createAuthResource>;
