/**
 * src/lib/queryClient — the one QueryClient instance for the app (wired into
 * App.tsx's QueryClientProvider).
 *
 * `staleTime: 0` — the opposite of apps/console's 30s. Two admins can be
 * working the same approvals queue at the same time, and a 30-second-stale
 * "Pending 3" is how the same application gets approved twice and the second
 * attempt comes back 409 `not_pending` with no explanation an admin can act
 * on. Every read on this surface is a read of someone else's live state.
 *
 * retry is disabled for 401/403: those mean "you are not (or no longer)
 * allowed", and react-query's default exponential-backoff retry would just
 * hammer the API three more times before AuthProvider gets the chance to drop
 * the session. A 403 in particular is expected here — it is exactly what the
 * server returns when a signed-in non-admin's browser reaches an /api/admin
 * route — and retrying it three times would delay the refusal screen for no
 * gain.
 *
 * The QueryCache/MutationCache `onError` below emits on 401 only, not on the
 * wider 401-or-403 the retry policy suppresses: a 403 means "not allowed to
 * do *this*", which does not imply the whole session is bad. Force-logging an
 * admin out over a scoped 403 would be a worse failure mode than the refusal
 * screen it replaces — and on this surface it would also throw away whatever
 * half-finished decision they were making.
 *
 * NOTE what is deliberately absent: no `placeholderData: keepPreviousData`.
 * Changing a filter or a tab must show the skeleton rather than keep the
 * previous rows on screen under new filter chips, because on an approvals
 * queue "these 4 rows" and "these 4 rows, for the filter you just left" are
 * opposite facts. Every filter combination is its own cache entry and loading
 * is keyed on `isPending`.
 */
import { QueryCache, QueryClient, MutationCache } from "@tanstack/react-query";
import { ApiError } from "@lacasa/domain";
import { emitSessionExpired } from "./sessionExpired";

function isAuthError(error: unknown): boolean {
  return ApiError.isApiError(error) && (error.status === 401 || error.status === 403);
}

/**
 * Exported so its one real branch (401 -> emit, everything else -> silent) is
 * directly unit-testable without instantiating a QueryClient or mounting any
 * React — QueryCache/MutationCache's `onError` just needs *a* function with
 * this signature, not this exact one wired up to observe.
 */
export function notifyIfSessionExpired(error: unknown): void {
  if (ApiError.isApiError(error) && error.status === 401) {
    emitSessionExpired();
  }
}

export const queryClient = new QueryClient({
  queryCache: new QueryCache({ onError: notifyIfSessionExpired }),
  mutationCache: new MutationCache({ onError: notifyIfSessionExpired }),
  defaultOptions: {
    queries: {
      staleTime: 0,
      retry: (failureCount, error) => {
        if (isAuthError(error)) return false;
        return failureCount < 2;
      },
    },
    // Mutations get no automatic retry at all. Every mutation on this surface
    // changes someone else's account — a retried approve/reject/role-change
    // after an ambiguous failure risks applying a decision twice.
    mutations: {
      retry: false,
    },
  },
});
