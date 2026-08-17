/**
 * src/data/queryKeys — every react-query key factory in one place, so a cache
 * invalidation (`queryClient.invalidateQueries`) and the `useQuery` call it is
 * meant to catch can never drift onto two hand-typed key arrays that only look
 * the same.
 *
 * ALL FOUR FEATURES ARE DECLARED HERE UP FRONT, including the three whose data
 * hooks are written by other agents. That is the point: after an admin
 * approves an application, the applications list, the users list AND the
 * overview's counts are all stale, and the mutation has to be able to
 * invalidate all three by key without importing anything from the screens that
 * own them. Screen agents import from this file and must not edit it.
 *
 * Filter objects go into the key rather than being flattened into strings so
 * two calls with the same filters share a cache entry and two with different
 * ones do not. `?? null` on every optional: `undefined` and "the default" have
 * to fold to the same key or the rail's badge query and the screen's own query
 * would fetch the same page twice.
 */

/** `GET /api/admin/applications?status=` — the three states of an application. */
export type ApplicationsStatusFilter = "pending" | "approved" | "rejected";

/**
 * The subset of each endpoint's query string that varies per view. `limit` and
 * `cursor` are deliberately NOT here: cursor is page state owned by
 * `useInfiniteQuery`'s `pageParam` (folding it into the key would give every
 * page its own cache entry and defeat the pagination), and limit is a constant
 * per screen.
 */
export interface ApplicationsFilters {
  status?: ApplicationsStatusFilter;
}

export interface UsersFilters {
  /** Matches fullName OR email, case-insensitive, contains. */
  q?: string;
  role?: string;
  realtorStatus?: string;
}

export interface AuditFilters {
  type?: string;
  agentId?: string;
}

export const queryKeys = {
  overview: {
    all: ["overview"] as const,
    // No parameters today, and still a function rather than a bare array:
    // every other key here is called, and a lone non-callable would be the
    // one that gets `queryKeys.overview.summary` (the function, as a key)
    // passed by mistake.
    summary: () => ["overview", "summary"] as const,
  },
  applications: {
    all: ["applications"] as const,
    // `status` folds to its server-side default rather than to null: the
    // contract says an omitted status means pending, so a call with no
    // filters and a call with `{ status: "pending" }` are the same request
    // and must be the same cache entry.
    list: (filters?: ApplicationsFilters) =>
      ["applications", "list", filters?.status ?? "pending"] as const,
  },
  users: {
    all: ["users"] as const,
    list: (filters?: UsersFilters) =>
      [
        "users",
        "list",
        {
          q: filters?.q?.trim() || null,
          role: filters?.role ?? null,
          realtorStatus: filters?.realtorStatus ?? null,
        },
      ] as const,
    detail: (id: string) => ["users", "detail", id] as const,
  },
  audit: {
    all: ["audit"] as const,
    list: (filters?: AuditFilters) =>
      [
        "audit",
        "list",
        { type: filters?.type ?? null, agentId: filters?.agentId ?? null },
      ] as const,
  },
} as const;
