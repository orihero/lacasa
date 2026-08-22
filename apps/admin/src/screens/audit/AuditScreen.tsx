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
 * read (`lib/queryKeys` — which this screen does not own — defines exactly one
 * audit key and no agents key, and the users list it does define belongs to
 * the users screen's infinite query; a second hook keyed the same way would
 * fight it for the same cache entry). So the filter is set from the stream
 * itself: the funnel action on any row narrows the log to that row's agent.
 * That covers the question this screen is actually opened to answer — "show
 * me everything else this person did around that time" — without shipping a
 * picker listing agents that may have no events at all.
 *
 * NO MUTATIONS, and therefore no confirmation dialog, no optimistic update
 * and no per-row error copy: ActivityEvent is append-only and nothing under
 * /api/admin writes, edits, annotates or deletes an event. The only in-flight
 * states here are read states.
 */
import { useState } from "react";
import type { AdminAuditEventType } from "@lacasa/api-client";
import MuiButton from "@mui/material/Button";
import { useTranslation } from "react-i18next";
import { PageHead } from "@/shell/PageHead";
import { Button } from "@/ui/Button";
import { FilterChip } from "@/ui/FilterChip";
import { LoadMore } from "@/ui/LoadMore";
import { Panel, PanelHead } from "@/ui/Panel";
import { EmptyState, ErrorState, TableSkeleton } from "@/ui/States";
import { TBody, TH, THead, Table } from "@/ui/Table";
import { List, RefreshCw, User, X } from "@/ui/icons";
import { AUDIT_PAGE_SIZE, auditRowsOf, useAuditEvents, useRefreshAudit } from "@/data/useAudit";
import { AUDIT_COLUMN_COUNT, AuditRow } from "./AuditRow";
import { AuditScopeNote } from "./AuditScopeNote";
import { AuditTypeFilter } from "./AuditTypeFilter";
import "./audit.scss";

/** Carried alongside the id so the active-filter chip can name the person. */
interface AgentFilter {
  id: string;
  fullName: string;
}

export function AuditScreen() {
  const { t } = useTranslation();
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
        note={t("auditPageNote", { size: AUDIT_PAGE_SIZE })}
        actions={
          <Button icon={RefreshCw} onClick={refresh} disabled={query.isFetching}>
            {query.isFetching ? t("refreshing") : t("refresh")}
          </Button>
        }
      >
        <AuditTypeFilter value={type} onChange={applyTypeFilter} />
        {agent ? (
          <FilterChip icon={User} active onClick={() => applyAgentFilter(null)}>
            {t("agentFilterChip", { name: agent.fullName })}
            <X size={11} aria-hidden="true" />
          </FilterChip>
        ) : null}
        {isFiltered ? (
          // A quiet text button, not a second boxed control: it undoes the
          // filters beside it rather than being an action of its own. The
          // empty state renders a full button with the SAME label, and both
          // have to work — this one is the way out while rows are on screen.
          <MuiButton
            type="button"
            variant="text"
            onClick={clearFilters}
            className="audit-clear"
            sx={{
              padding: "6px 8px",
              minWidth: 0,
              fontSize: "13px",
              color: "#8d99ae",
              "&:hover": { backgroundColor: "transparent", color: "#2b2d42", textDecoration: "underline" },
            }}
          >
            {t("clearFilters")}
          </MuiButton>
        ) : null}
      </PageHead>

      <AuditScopeNote />

      <Panel>
        <PanelHead
          title={t("activityEventsTitle")}
          sub={
            agent
              ? // Spelled out because `agentId` matches the OWNING agent on
                // every event, including ones a coworker performed — reading
                // this as "only what this person did with their own hands"
                // would under-count a team.
                t("activityEventsSubAgent", { name: agent.fullName })
              : t("activityEventsSubAll")
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
              icon={List}
              title={t("emptyAuditFilteredTitle")}
              sub={t("emptyAuditFilteredSub")}
              action={<Button onClick={clearFilters}>{t("clearFilters")}</Button>}
            />
          ) : (
            <EmptyState
              icon={List}
              title={t("emptyAuditTitle")}
              sub={t("emptyAuditSub")}
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
              <div role="alert" className="audit-page-error">
                {t("couldNotLoadMoreEvents", { message: errorText(query.error, t) })}
              </div>
            ) : null}

            <LoadMore
              loaded={rows.length}
              hasMore={query.hasNextPage}
              isFetching={query.isFetchingNextPage}
              onLoadMore={() => void query.fetchNextPage()}
              noun={t("nounEvents")}
            />
          </>
        )}
      </Panel>
    </>
  );
}

function AuditHeader() {
  const { t } = useTranslation();
  return (
    <THead>
      <tr>
        <TH width="112px">{t("columnTime")}</TH>
        <TH width="215px">{t("columnEvent")}</TH>
        <TH width="220px">{t("columnActedBy")}</TH>
        <TH>{t("columnRecord")}</TH>
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
 *
 * The fallback is lowercase and ends in a full stop because it completes the
 * sentence after the colon: "Could not load more events: the request did not
 * complete."
 */
function errorText(error: unknown, t: (key: string) => string): string {
  if (error instanceof Error && error.message) return error.message;
  return t("requestDidNotCompletePeriod");
}
