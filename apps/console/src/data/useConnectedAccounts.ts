/**
 * src/data/useConnectedAccounts — the Connected accounts screen's one
 * genuinely real, per-account data source: `GET /publish/instagram/accounts`
 * (apps/api/src/routes/instagramAuth.js's OAuth-connected `AgentIgToken`
 * rows), plus the connect/disconnect mutations that manage them.
 *
 * There is no equivalent for Telegram/YouTube/OLX — PLAN.md §4's "No
 * ConnectedAccount model / endpoint" gap. Telegram's connection state reads
 * off `AuthUser.tgChatIds` instead (populated by GET /auth/me's
 * resolveAgentContext, count-only per PLAN.md §4 — "tgChatIds has no
 * per-channel name field; never fabricate channel names"), sourced from
 * `useAuth()` directly by the screen rather than a hook here. YouTube/OLX
 * have no backing data at all; the screen renders them un-derived, not
 * routed through this file.
 *
 * `useConnectInstagram` deliberately does not attempt a same-tab redirect
 * back into this console: apps/api/src/routes/instagramAuth.js's callback
 * hard-codes its post-OAuth redirect to `${APP_URL}/profile/:agentId/setting`
 * — apps/web's settings route, not this app's — so the only honest thing to
 * do with the connect URL is open it (a new tab), not pretend the flow
 * round-trips back here.
 */
import { useMutation, useQuery, useQueryClient, type UseMutationResult, type UseQueryResult } from '@tanstack/react-query';
import type { ApiError } from '@lacasa/domain';
import type { InstagramAccount } from '@lacasa/api-client';
import { apiClient } from '@/lib/apiClient';
import { queryKeys } from './queryKeys';

export function useInstagramAccounts(): UseQueryResult<InstagramAccount[]> {
  return useQuery({
    queryKey: queryKeys.publish.instagramAccounts(),
    queryFn: async () => (await apiClient.publish.getInstagramAccounts()).accounts,
  });
}

export function useConnectInstagram(): UseMutationResult<string, ApiError, void> {
  return useMutation({
    mutationFn: async () => (await apiClient.auth.getInstagramConnectUrl()).url,
  });
}

export function useDisconnectInstagram(): UseMutationResult<void, ApiError, string> {
  const queryClient = useQueryClient();
  return useMutation({
    mutationFn: async (igUserId: string) => {
      await apiClient.auth.disconnectInstagram(igUserId);
    },
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.publish.instagramAccounts() });
    },
  });
}
