/**
 * src/lib/queryClient — the one QueryClient instance for the app (wired in
 * App.tsx's QueryClientProvider). retry is disabled for 401/403: those mean
 * "you are not (or no longer) allowed", and react-query's default
 * exponential-backoff retry would just hammer the API three more times
 * before AuthProvider gets the chance to drop the session — see
 * lib/auth.tsx's `me()` 401 handling.
 *
 * That mount-time check only runs once, though — a token that goes bad
 * *during* the session (revoked, expired) would otherwise surface as an
 * ordinary ErrorState on whatever screen was mid-request, with a "Try
 * again" button that just 401s a second time forever. The QueryCache/
 * MutationCache `onError` below is the same recovery path, wired to fire
 * from any query or mutation failure, not only the first one: on a real 401
 * it emits through sessionExpired.ts, which AuthProvider listens for and
 * reacts to exactly like its own mount-time 401 branch (drop the token, go
 * anonymous, let RequireAuth redirect). Scoped to 401 specifically, not the
 * wider 401-or-403 the retry policy below suppresses — a 403 means "not
 * allowed to do *this*", which doesn't imply the whole session is bad, and
 * force-logging an agent out over a permission-scoped 403 would be a worse
 * failure mode than the stuck-ErrorState this is fixing.
 */
import { QueryCache, QueryClient, MutationCache } from '@tanstack/react-query';
import { ApiError } from '@lacasa/domain';
import { emitSessionExpired } from './sessionExpired';

function isAuthError(error: unknown): boolean {
  return ApiError.isApiError(error) && (error.status === 401 || error.status === 403);
}

// Exported so its one real branch (401 -> emit, everything else -> silent)
// is directly unit-testable without instantiating a QueryClient or mounting
// any React — QueryCache/MutationCache's `onError` just needs *a* function
// with this signature, not this exact one wired up to observe.
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
      staleTime: 30_000,
      retry: (failureCount, error) => {
        if (isAuthError(error)) return false;
        return failureCount < 2;
      },
    },
    // Mutations don't get react-query's automatic retry at all — a retried
    // POST/PATCH/DELETE after a real failure risks a double-submit; the
    // caller decides whether to let the agent retry by hand.
    mutations: {
      retry: false,
    },
  },
});
