/**
 * src/data/useAudit — the activity log's reads. One endpoint
 * (GET /api/admin/audit), one hook, plus an explicit refresh.
 *
 * WHY useInfiniteQuery AND NOT useQuery: the endpoint is keyset-paged on an
 * opaque `nextCursor` (see the api-client resource's file header). There is
 * no page count and no way to jump, so the only shape that fits is "append
 * the next slice to what is already on screen" — which is also the shape the
 * LoadMore primitive was built for. The cursor is deliberately absent from
 * `queryKeys.audit.list()`; react-query holds it as `pageParam` instead, so
 * every page of one filter combination shares a single cache entry rather
 * than fragmenting into one entry per cursor.
 *
 * WHY THE OPTIONS ARE A SEPARATE, REACT-FREE FUNCTION: `auditQueryOptions()`
 * is where every claim this screen makes about the wire actually lives — the
 * page size, that both filters are sent to the server rather than applied to
 * an arrived page, that the cursor is passed back verbatim. Building it
 * outside the hook lets that be asserted directly against a fake transport,
 * with no React mounted and no query client to stand up, which keeps the wire
 * contract testable independently of anything the screen renders.
 *
 * NO `placeholderData: keepPreviousData`, here or in the global defaults
 * (lib/queryClient.ts says so too). Changing a filter must show the SKELETON
 * rather than the previous filter's rows: on a log, rows that are still on
 * screen after the question changed read as the answer to the new question.
 *
 * There are no mutations here, and that is a fact about the data rather than
 * an omission: ActivityEvent is append-only and nothing under /api/admin
 * writes to it (adminRepository.findAuditEvents' comment spells this out).
 * An admin cannot edit, annotate or delete an event from this surface.
 */
import {
  useInfiniteQuery,
  useQueryClient,
  type InfiniteData,
  type UseInfiniteQueryResult,
} from "@tanstack/react-query";
import type { AdminAuditEventType, AdminAuditRow, AdminPage } from "@lacasa/api-client";
import { apiClient } from "@/lib/apiClient";
import { queryKeys } from "@/lib/queryKeys";

/**
 * 50, against the server's default of 25 and its cap of 100. A log is read by
 * scanning for the one line that explains an incident, and the scroll that
 * finds it should not be interrupted by a Load more click every 25 rows.
 * Deliberately short of the cap: a 100-row first paint on a filtered-to-
 * nothing query is 100 rows of latency spent to show an empty result.
 *
 * The toolbar note interpolates this constant rather than restating "50", so
 * the page size and the sentence describing it cannot drift apart.
 */
export const AUDIT_PAGE_SIZE = 50;

/**
 * The server-side filters, narrowed past `queryKeys`' own `AuditFilters`
 * (whose `type` is a bare `string`, since that module cannot import the
 * api-client's enum without pulling the whole contract into a key factory).
 * Structurally assignable to it, so the key factory still takes this verbatim.
 *
 * BOTH FILTERS ARE APPLIED BY THE SERVER, and nothing here filters a loaded
 * page client-side. On a cursor-paginated stream that distinction is not
 * pedantry: hiding rows after the fact would make "3 events" mean "3 of the
 * 50 rows fetched so far", which is a different claim from "3 events exist".
 */
export interface AuditFilters {
  type?: AdminAuditEventType;
  agentId?: string;
}

export type AuditPage = AdminPage<AdminAuditRow>;
/** Keyset cursors are opaque strings; `undefined` is "the first page". */
export type AuditCursor = string | undefined;

export type AuditQueryResult = UseInfiniteQueryResult<
  InfiniteData<AuditPage, AuditCursor>,
  Error
>;

export function auditQueryOptions(filters: AuditFilters = {}) {
  return {
    queryKey: queryKeys.audit.list(filters),
    queryFn: ({ pageParam }: { pageParam: AuditCursor }): Promise<AuditPage> =>
      apiClient.admin.listAudit({
        type: filters.type,
        agentId: filters.agentId,
        limit: AUDIT_PAGE_SIZE,
        cursor: pageParam,
      }),
    // `undefined` (not null, not "") — the resource passes it straight into
    // `query.cursor`, and every Transport in the monorepo drops undefined
    // keys rather than serialising them as `?cursor=` or `?cursor=null`.
    initialPageParam: undefined as AuditCursor,
    // `?? undefined` collapses the contract's "this was the last page"
    // (`nextCursor: null`) onto the value react-query reads as "no next
    // page"; returning the null through would leave hasNextPage true forever.
    getNextPageParam: (lastPage: AuditPage): AuditCursor => lastPage.nextCursor ?? undefined,
  };
}

export function useAuditEvents(filters: AuditFilters = {}): AuditQueryResult {
  return useInfiniteQuery(auditQueryOptions(filters));
}

/** Every loaded page, flattened into the single newest-first stream the table renders. */
export function auditRowsOf(
  data: InfiniteData<AuditPage, AuditCursor> | undefined,
): AdminAuditRow[] {
  return data?.pages.flatMap((page) => page.items) ?? [];
}

/**
 * Re-reads the log from the top. Invalidation (rather than a bare `refetch`)
 * so it also catches the OTHER filter combinations sitting in the cache —
 * switching the type filter back to one visited a minute ago must not show a
 * minute-old stream on a surface whose whole job is "what just happened".
 *
 * react-query refetches every already-loaded page of an invalidated infinite
 * query, walking the cursors again from the first page. That is correct for a
 * keyset stream: pages 2..n are re-derived from the refreshed page 1's
 * cursors rather than being stitched onto a stale offset.
 */
export function useRefreshAudit(): () => void {
  const queryClient = useQueryClient();
  return () => {
    void queryClient.invalidateQueries({ queryKey: queryKeys.audit.all });
  };
}
