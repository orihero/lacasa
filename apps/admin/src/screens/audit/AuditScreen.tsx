/**
 * AuditScreen — the control room's activity log: every ActivityEvent the
 * platform has recorded, newest first, filterable by event type and by agent
 * and paged with the same keyset LoadMore as the rest of this surface.
 *
 * READ AuditScopeNote FIRST — it states, permanently and above the table,
 * what this log covers (agent and coworker activity against ads and leads)
 * and the much longer list of what it does not (sign-ins, admin decisions,
 * system jobs, severity). Everything below is written so that note stays
 * true: no severity column, no invented actor types, no client-side
 * filtering that would let "12 events" mean "12 of the rows fetched so far".
 *
 * The agent filter has no dropdown, and that is a deliberate constraint
 * rather than a missing feature. There is no agents endpoint this screen may
 * read (`queryKeys` — which this screen does not own — defines exactly one
 * audit key and no agents key, and the users list it does define belongs to
 * the users screen's infinite query; a second hook keyed the same way would
 * fight it for the same cache entry). So the filter is set from the stream
 * itself: the funnel action on any row narrows the log to that row's agent.
 * That covers the question this screen is actually opened to answer — "show
 * me everything else this person did around that time" — without shipping a
 * picker listing agents that may have no events at all.
 */
import { useState } from "react";
import type { AdminAuditEventType } from "@lacasa/api-client";
import { PageHead } from "@/shell/PageHead";
import { Button } from "@/ui/Button";
import { FilterChip } from "@/ui/FilterChip";
import { LoadMore } from "@/ui/LoadMore";
import { Panel, PanelHead } from "@/ui/Panel";
import { EmptyState, ErrorState, TableSkeleton } from "@/ui/States";
import { TBody, TH, THead, Table } from "@/ui/Table";
import { ArrowsClockwiseIcon, ListBulletsIcon, UserIcon, XIcon } from "@/ui/icons";
import { AUDIT_PAGE_SIZE, auditRowsOf, useAuditEvents, useRefreshAudit } from "@/data/useAudit";
import { AUDIT_COLUMN_COUNT, AuditRow } from "./AuditRow";
import { AuditScopeNote } from "./AuditScopeNote";
import { AuditTypeFilter } from "./AuditTypeFilter";

/** Carried alongside the id so the active-filter chip can name the person. */
interface AgentFilter {
  id: string;
  fullName: string;
}

export function AuditScreen() {
  const [type, setType] = useState<AdminAuditEventType | undefined>(undefined);
  const [agent, setAgent] = useState<AgentFilter | null>(null);
  // One row open at a time. A log is scanned top to bottom, and several
  // drawers open at once would push the rows below them off the screen the
  // admin is scanning — the drawer is a detour, not a mode.
  const [expandedId, setExpandedId] = useState<string | null>(null);

  const query = useAuditEvents({ type, agentId: agent?.id });
  const refresh = useRefreshAudit();
  const rows = auditRowsOf(query.data);
  const isFiltered = type !== undefined || agent !== null;

  // Any filter change invalidates whichever drawer was open: the row it
  // belonged to may not be in the next result set at all, and a drawer
  // reappearing three rows down after a refetch is worse than none.
  function applyTypeFilter(next: AdminAuditEventType | undefined) {
    setExpandedId(null);
    setType(next);
  }

  function applyAgentFilter(next: AgentFilter | null) {
    setExpandedId(null);
    setAgent(next);
  }

  function clearFilters() {
    setExpandedId(null);
    setType(undefined);
    setAgent(null);
  }

  return (
    <>
      <PageHead
        note={`Newest first · ${AUDIT_PAGE_SIZE} per page`}
        actions={
          <Button
            icon={ArrowsClockwiseIcon}
            onClick={refresh}
            disabled={query.isFetching}
          >
            {query.isFetching ? "Refreshing…" : "Refresh"}
          </Button>
        }
      >
        <AuditTypeFilter value={type} onChange={applyTypeFilter} />
        {agent ? (
          <FilterChip icon={UserIcon} active onClick={() => applyAgentFilter(null)}>
            Agent: {agent.fullName}
            <XIcon size={11} className="shrink-0" />
          </FilterChip>
        ) : null}
        {isFiltered ? (
          <button
            type="button"
            onClick={clearFilters}
            className="rounded-act px-1.5 py-1 text-small font-medium text-muted underline-offset-2 transition-colors hover:text-ink hover:underline focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-acc"
          >
            Clear filters
          </button>
        ) : null}
      </PageHead>

      <AuditScopeNote />

      <Panel>
        <PanelHead
          title="Activity events"
          sub={
            agent
              ? // Spelled out because `agentId` matches the OWNING agent on
                // every event, including ones a coworker performed — reading
                // this as "only what this person did with their own hands"
                // would under-count a team.
                `Everything recorded under ${agent.fullName}, including their coworkers`
              : "Every agent on the platform"
          }
        />

        {query.isError && rows.length === 0 ? (
          <ErrorState error={query.error} onRetry={() => void query.refetch()} />
        ) : query.isPending ? (
          <Table>
            <AuditHeader />
            <TableSkeleton rows={8} cols={AUDIT_COLUMN_COUNT} />
          </Table>
        ) : rows.length === 0 ? (
          isFiltered ? (
            <EmptyState
              icon={ListBulletsIcon}
              title="No events match these filters"
              sub="The log itself may well have activity in it — nothing recorded matches the event type or agent you picked."
              action={<Button onClick={clearFilters}>Clear filters</Button>}
            />
          ) : (
            <EmptyState
              icon={ListBulletsIcon}
              title="No activity recorded"
              sub="Events appear here once an agent or coworker creates an ad, marks one sold, moves a lead, or runs a crosspost session."
            />
          )
        ) : (
          <>
            <Table>
              <AuditHeader />
              <TBody>
                {rows.map((row) => (
                  <AuditRow
                    key={row.id}
                    row={row}
                    expanded={row.id === expandedId}
                    onToggleMeta={() =>
                      setExpandedId((current) => (current === row.id ? null : row.id))
                    }
                    onFilterAgent={applyAgentFilter}
                    agentFilterActive={agent?.id === row.agent?.id}
                  />
                ))}
              </TBody>
            </Table>

            {/* A page that fails AFTER the first one must not throw away the
                rows already on screen — the admin is mid-scan, and the honest
                report is "you have these 50, the next fetch failed". */}
            {query.isError ? (
              <div role="alert" className="border-t border-line px-[15px] py-2.5 text-small text-err">
                Could not load more events: {errorText(query.error)}
              </div>
            ) : null}

            <LoadMore
              loaded={rows.length}
              hasMore={query.hasNextPage}
              isFetching={query.isFetchingNextPage}
              onLoadMore={() => void query.fetchNextPage()}
              noun="events"
            />
          </>
        )}
      </Panel>
    </>
  );
}

function AuditHeader() {
  return (
    <THead>
      <tr>
        <TH width="112px">Time</TH>
        <TH width="215px">Event</TH>
        <TH width="220px">Acted by</TH>
        <TH>Record</TH>
        {/* The row-action column. Unlabelled on purpose: "Actions" as a
            column header is a heading for the UI, not for the data. */}
        <TH width="92px" align="right" />
      </tr>
    </THead>
  );
}

/**
 * The inline strip above only has room for one line, so it takes the message
 * alone — ErrorState (which also surfaces the `{ error: { code } }`) is what
 * renders when there is nothing else on screen to compete with it.
 */
function errorText(error: unknown): string {
  if (error instanceof Error && error.message) return error.message;
  return "the request did not complete.";
}
