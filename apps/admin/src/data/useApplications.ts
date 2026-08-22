/**
 * src/data/useApplications — the realtor application queue's data layer: one
 * paged read and one decision mutation, both against the typed `admin`
 * resource of @lacasa/api-client.
 *
 * WHY useInfiniteQuery AND NOT useQuery: /api/admin/applications is keyset-paged
 * on `(createdAt desc, id desc)` and hands back an opaque `nextCursor`. There is
 * no total and no page number, so the only shape the endpoint supports is "give
 * me the next slice after this one" — which is exactly `pageParam`. That is also
 * why `queryKeys.applications.list()` deliberately excludes the cursor: folding
 * it into the key would give every page its own cache entry and the accumulated
 * list would reset on every fetch.
 *
 * ONE MUTATION FOR BOTH DECISIONS, mirroring the server: approve and reject
 * differ only in which endpoint they hit, and adminService.js already collapsed
 * them into one `decideApplication` for the same reason — two copies of the
 * invalidation-and-409 handling is precisely the kind of thing that drifts.
 *
 * The options factories are split out of the hooks on purpose. The React 18/19
 * hoisting conflict that ORIGINALLY forced that split is gone (this app pins
 * React 18 like apps/web, and there is one React in the tree), but the seam is
 * kept because it is still the cheapest way to assert the request contract —
 * path, status, page size, cursor threading, and which cache branches a
 * decision invalidates — without mounting React at all. A missed invalidation
 * key shows up as a stale count on a screen somebody else owns, never as a
 * failure on this one.
 */
import {
  useInfiniteQuery,
  useMutation,
  useQueryClient,
  type InfiniteData,
  type QueryClient,
  type UseInfiniteQueryResult,
  type UseMutationOptions,
  type UseMutationResult,
} from "@tanstack/react-query";
import type {
  AdminApplicationDecisionResponse,
  AdminApplicationRow,
  AdminPage,
} from "@lacasa/api-client";
import { ApiError } from "@lacasa/domain";
import { apiClient } from "@/lib/apiClient";
import { queryKeys, type ApplicationsStatusFilter } from "@/lib/queryKeys";

/**
 * Matches the server's own default (`resolveTake`, capped at 100). Stated
 * explicitly rather than left to the server, so the count the LoadMore footer
 * reports is a number this app decided rather than one it inferred from
 * whatever came back — and so raising it is a one-line change here.
 */
export const APPLICATIONS_PAGE_SIZE = 25;

export type ApplicationsPage = AdminPage<AdminApplicationRow>;

export function applicationsQueryOptions(status: ApplicationsStatusFilter) {
  return {
    queryKey: queryKeys.applications.list({ status }),
    queryFn: ({ pageParam }: { pageParam: string | null }) =>
      apiClient.admin.listApplications({
        // ApplicationsStatusFilter (lib/queryKeys.ts) and AdminApplicationStatus
        // (@lacasa/api-client) are two names for the same three-member
        // vocabulary; both exclude `none`, which is the state of never having
        // applied rather than a fourth bucket.
        status,
        limit: APPLICATIONS_PAGE_SIZE,
        // The first page must send NO cursor at all: `?cursor=` would mean "the
        // empty cursor" rather than "from the beginning", so the null initial
        // pageParam is converted back to undefined for the resource, and
        // lib/apiClient's buildUrl drops undefined query keys entirely.
        cursor: pageParam ?? undefined,
      }),
    initialPageParam: null as string | null,
    // `nextCursor: null` is the server saying that page was the last one, and
    // react-query v5 reads a null here as "no next page" — so this passes the
    // contract's own sentinel straight through rather than re-deriving "is
    // there more?" from the row count, which would be wrong on a final page
    // that happens to be exactly APPLICATIONS_PAGE_SIZE long.
    getNextPageParam: (lastPage: ApplicationsPage) => lastPage.nextCursor,
  };
}

/** The exact key type `applicationsQueryOptions` produces, for the hook's generics. */
type ApplicationsQueryKey = ReturnType<typeof queryKeys.applications.list>;

/**
 * The generics are spelled out rather than inferred for one reason: react-query
 * cannot infer an error type from a queryFn (a Promise carries no rejection
 * type), so it would default TError to `Error` and the screen would lose the
 * `status`/`code` fields it reads off an ApiError.
 */
export function useApplications(
  status: ApplicationsStatusFilter,
): UseInfiniteQueryResult<InfiniteData<ApplicationsPage>, ApiError> {
  return useInfiniteQuery<
    ApplicationsPage,
    ApiError,
    InfiniteData<ApplicationsPage>,
    ApplicationsQueryKey,
    string | null
  >(applicationsQueryOptions(status));
}

/**
 * Every page's rows, in server order, as one list. A helper rather than an
 * inline flatMap in the screen so the "no pages yet" case (first load, and an
 * error before any page arrived) resolves to an empty array in exactly one
 * place — the screen branches on `rows.length === 0` to choose between the
 * empty state and the table.
 */
export function flattenApplicationPages(
  data: InfiniteData<ApplicationsPage> | undefined,
): AdminApplicationRow[] {
  return data?.pages.flatMap((page) => page.items) ?? [];
}

export type ApplicationDecision = "approve" | "reject";

export interface DecideApplicationVariables {
  userId: string;
  decision: ApplicationDecision;
}

/** The `error.code` the API sends when the application is no longer PENDING. */
export const ALREADY_DECIDED_CODE = "not_pending";

/**
 * True for the one failure that is not really a failure: a 409 `not_pending`
 * means another admin decided this application between the queue being rendered
 * and the button being pressed. Nothing is broken and nothing needs retrying —
 * the local view is simply out of date.
 *
 * The code is compared through `string` on purpose. @lacasa/domain's
 * ERROR_CODES was collected from the API's call sites before /api/admin existed
 * and does not list `not_pending`, while lib/apiClient.ts casts whatever code
 * the body carried into that union — so `error.code` is typed more narrowly
 * than it actually is, and comparing against the union directly would be a
 * compile error about a value the server genuinely sends.
 *
 * All three conditions are load-bearing: a 409 with another code (`last_admin`)
 * is not this, `not_pending` at another status is not this, and a plain Error
 * or an `undefined` is not this either.
 */
export function isApplicationAlreadyDecided(error: unknown): boolean {
  return (
    ApiError.isApiError(error) &&
    error.status === 409 &&
    (error.code as string) === ALREADY_DECIDED_CODE
  );
}

/**
 * The mutation's options, taking the cache it invalidates as an argument rather
 * than reaching for `useQueryClient()` itself, so a test can hand it a stub
 * client and assert the invalidated keys directly.
 */
export function decideApplicationMutationOptions(
  queryClient: Pick<QueryClient, "invalidateQueries">,
): UseMutationOptions<AdminApplicationDecisionResponse, ApiError, DecideApplicationVariables> {
  return {
    mutationFn: ({ userId, decision }: DecideApplicationVariables) =>
      decision === "approve"
        ? apiClient.admin.approveApplication(userId)
        : apiClient.admin.rejectApplication(userId),

    onSuccess: () => {
      // THREE KEYS, not one. `applications.all` covers the queue the row just
      // left AND the approved/rejected list it landed in — the screen only has
      // one of them mounted, so invalidating the branch rather than the exact
      // filter is what stops the other two tabs showing a stale row the moment
      // they are opened. `overview.all` because the pending/approved/rejected
      // counts (and, on an approval, the buyers/agents split) just moved, and
      // the rail's badge reads that same cache entry. `users.all` because an
      // approval promotes USER -> AGENT, which changes a row the users
      // directory is showing.
      void queryClient.invalidateQueries({ queryKey: queryKeys.applications.all });
      void queryClient.invalidateQueries({ queryKey: queryKeys.overview.all });
      void queryClient.invalidateQueries({ queryKey: queryKeys.users.all });
    },

    onError: (error) => {
      // A 409 means someone else already decided this one, so the queue on
      // screen is provably wrong and refetching it is the fix — but NOT
      // users.all: nobody was promoted, so that directory is still accurate.
      // Every other error leaves the cache alone: the decision did not land,
      // the list is still correct, and silently refetching would hide that
      // fact behind a spinner.
      if (!isApplicationAlreadyDecided(error)) return;
      void queryClient.invalidateQueries({ queryKey: queryKeys.applications.all });
      void queryClient.invalidateQueries({ queryKey: queryKeys.overview.all });
    },
  };
}

export function useDecideApplication(): UseMutationResult<
  AdminApplicationDecisionResponse,
  ApiError,
  DecideApplicationVariables
> {
  const queryClient = useQueryClient();
  return useMutation(decideApplicationMutationOptions(queryClient));
}
