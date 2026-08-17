/**
 * src/data/useOverview — `GET /api/admin/overview`, the single request the
 * control room's landing screen makes.
 *
 * ONE QUERY, TWO CONSUMERS. The rail's Applications/Users badges subscribe to
 * this exact cache entry with `enabled: false` (see shell/Rail.tsx's header),
 * so this hook is what actually fills them in. That is why the key comes from
 * data/queryKeys.ts rather than being spelled out here: the rail and this
 * screen agreeing on `["overview","summary"]` is the whole contract between
 * two files that never import each other, and a hand-typed array in either
 * place would silently give the rail an entry nobody ever writes to.
 *
 * NO MUTATIONS LIVE HERE. Nothing on the overview writes — it is a read-only
 * dashboard, and the counts it shows go stale because *other* screens act
 * (approve an application, change a role). Those screens own the
 * `invalidateQueries({ queryKey: queryKeys.overview.all })` call that
 * refreshes this, which is exactly why queryKeys.ts declares all four
 * features up front.
 *
 * There is no `staleTime` override: lib/queryClient.ts sets 0 globally and the
 * reasoning there (two admins working the same queue) applies with full force
 * to a screen whose headline number is "3 applications are waiting on you".
 */
import { useQuery, type UseQueryResult } from "@tanstack/react-query";
import type { AdminOverview } from "@lacasa/api-client";
import type { ApiError } from "@lacasa/domain";
import { apiClient } from "@/lib/apiClient";
import { queryKeys } from "./queryKeys";

export function useOverview(): UseQueryResult<AdminOverview, ApiError> {
  return useQuery<AdminOverview, ApiError>({
    queryKey: queryKeys.overview.summary(),
    queryFn: () => apiClient.admin.overview(),
  });
}
