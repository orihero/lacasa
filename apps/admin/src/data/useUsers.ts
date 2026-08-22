/**
 * src/data/useUsers — the user directory's reads and its one write.
 *
 * Modelled on apps/console/src/data/useLeads.ts (typed resource in, query key
 * from @/lib/queryKeys, mutation invalidates by key), with the one structural
 * difference the admin API forces: `GET /api/admin/users` is keyset-paged, so
 * the list is a `useInfiniteQuery` rather than a `useQuery`. There is no
 * "fetch them all" call to fall back on — the endpoint caps `limit` at 100 —
 * and inventing a client-side loop over cursors here would just hide the
 * paging from the screen while making the first paint wait for every page.
 *
 * `cursor` never enters the query key (see @/lib/queryKeys' own comment): it is
 * `pageParam`, owned by react-query, and folding it in would give every page
 * its own cache entry and defeat the pagination entirely.
 *
 * NO `placeholderData: keepPreviousData` (PRECEDENCE.md). Changing a filter
 * must drop the table to its skeleton rather than hold the previous filter's
 * rows under the new filter's controls — that is how an admin acts on the
 * wrong row.
 */
import {
  useInfiniteQuery,
  useMutation,
  useQueryClient,
  type InfiniteData,
  type UseInfiniteQueryResult,
  type UseMutationResult,
} from "@tanstack/react-query";
import type { AdminPage, AdminUserResponse, AdminUserRow } from "@lacasa/api-client";
import type { ApiError, RealtorStatusKey, UserRoleKey } from "@lacasa/domain";
import { apiClient } from "@/lib/apiClient";
import { queryKeys } from "@/lib/queryKeys";

/**
 * 50, not the server's default of 25. The directory is a dense scanning
 * surface, so 25 rows is barely a screenful on the monitors this app is used
 * on and an admin would be clicking "Load more" before they had read anything.
 * Still well under the endpoint's cap of 100, which is where the
 * row-count-times-two-aggregate-queries cost per page starts to show.
 */
export const USERS_PAGE_SIZE = 50;

export interface UsersQueryFilters {
  /** Case-insensitive contains, matched against fullName OR email server-side. */
  q?: string;
  role?: UserRoleKey;
  realtorStatus?: RealtorStatusKey;
}

/**
 * Trimmed here as well as inside `queryKeys.users.list`, so the key and the
 * request it caches can never disagree about what was searched for: a
 * trailing space would otherwise hit the same cache entry as the trimmed
 * term while asking Postgres a different question.
 *
 * Empty-after-trim folds to `undefined` rather than `""` — an empty `q` is
 * "no filter", and sending `?q=` would ask the server to match everything
 * against the empty string.
 */
function normalizeFilters(filters: UsersQueryFilters): UsersQueryFilters {
  return {
    q: filters.q?.trim() || undefined,
    role: filters.role,
    realtorStatus: filters.realtorStatus,
  };
}

export function useUsers(
  filters: UsersQueryFilters = {},
): UseInfiniteQueryResult<InfiniteData<AdminPage<AdminUserRow>>, ApiError> {
  const params = normalizeFilters(filters);

  return useInfiniteQuery({
    queryKey: queryKeys.users.list(params),
    queryFn: ({ pageParam }) =>
      apiClient.admin.listUsers({ ...params, limit: USERS_PAGE_SIZE, cursor: pageParam }),
    // `undefined` is the first page: the resource passes an absent cursor
    // straight through and every Transport drops undefined query keys.
    initialPageParam: undefined as string | undefined,
    // `?? undefined` rather than passing `null` on: react-query treats a
    // null/undefined next page param as "there is no next page", but only
    // `undefined` also stops it from calling queryFn with a literal null.
    getNextPageParam: (lastPage: AdminPage<AdminUserRow>) => lastPage.nextCursor ?? undefined,
  });
}

export interface SetUserRoleVariables {
  id: string;
  role: UserRoleKey;
}

/**
 * PATCH /api/admin/users/:id/role.
 *
 * Deliberately does NOT write the response into the cache by hand. The server
 * enforces guard rails this client cannot see the inputs to (`last_admin`
 * counts the whole ADMIN population), so the only trustworthy post-change
 * state is a refetch — and on a surface where two admins work the same list at
 * once, a hand-patched row would also paper over whatever else changed
 * underneath it since the page loaded.
 *
 * Both invalidations are deliberate and neither is redundant:
 *   · `users.all` is the prefix of every users key, so it catches the list
 *     under whatever filters are active AND `users.detail(id)`.
 *   · `overview.all` because the overview's `users` block counts accounts by
 *     role, and this call just moved one between buckets.
 * The applications list is NOT invalidated: a role change never touches
 * `realtorStatus`, and AdminApplicationRow carries no role to go stale.
 */
export function useSetUserRole(): UseMutationResult<
  AdminUserResponse,
  ApiError,
  SetUserRoleVariables
> {
  const queryClient = useQueryClient();

  return useMutation({
    mutationFn: ({ id, role }: SetUserRoleVariables) => apiClient.admin.setUserRole(id, role),
    onSuccess: () => {
      void queryClient.invalidateQueries({ queryKey: queryKeys.users.all });
      void queryClient.invalidateQueries({ queryKey: queryKeys.overview.all });
    },
  });
}
