/**
 * AuditRow — one activity event, plus the detail row it expands into.
 *
 * FIVE COLUMNS, AND NO SEVERITY COLUMN. The mockup draws OK / WARN / INFO /
 * ERR pills in a dedicated "Level" column; `ActivityEvent` has no such field
 * and never has. What this row does instead is colour the event-type tag by
 * lib/labels' AUDIT_TYPE_TONE, which is this app deriving an OUTCOME from the
 * type name (a completed crosspost is settled, an aborted one is the row
 * worth finding) — a rendering decision, stated as such in AuditScopeNote,
 * not a level an admin can cite as something the server recorded.
 *
 * WHO ACTED vs WHOSE DATA. Every event carries an agent (`agentId` is a
 * required column) and optionally the coworker who performed it. The name on
 * the row is therefore the coworker when there is one — they are the person
 * who did the thing — with the owning agent on the sub-line, because "which
 * agent's book of business moved" is the other half of the question and
 * losing it would make coworker rows unattributable.
 *
 * The meta panel is a raw `<tr>`/`<td colSpan>` rather than ui/Table's TR/TD:
 * those primitives model a ledger row of fixed cells and expose no colSpan,
 * which is exactly right for them and exactly wrong for a full-width drawer.
 * It borrows the same hairline and spacing so the drawer still reads as part
 * of the table.
 */
import { Fragment } from "react";
import type { AdminAuditRow } from "@lacasa/api-client";
import { useTranslation } from "react-i18next";
import { Avatar } from "@/ui/Avatar";
import { Tag } from "@/ui/Tag";
import { CellMain, RowAction, RowActions, TD, TR } from "@/ui/Table";
import { Eye, Filter } from "@/ui/icons";
import { EM_DASH, formatDate, formatTimeOfDay, shortId } from "@/lib/format";
import { auditTypeLabel, auditTypeTone } from "@/lib/labels";
import "./audit.scss";

/** Column count, so the drawer's colSpan cannot drift away from the header. */
export const AUDIT_COLUMN_COUNT = 5;

/**
 * `null` means the column is genuinely empty, which is a different fact from
 * `"{}"` (an event that recorded meta and recorded nothing in it). Both are
 * rendered, differently — collapsing them would hide a writer bug.
 *
 * `unknown` in, string out: `meta` is a free-form Json column and the
 * contract types it honestly as unknown. Stringifying is the only thing this
 * screen can truthfully do with a value whose shape depends on the event
 * type; the fallbacks below cover a payload that somehow will not serialise
 * (a circular structure, a BigInt) rather than letting one bad row throw the
 * whole table off the screen. There is deliberately NO per-type renderer —
 * the JSON is the presentation.
 */
function formatMeta(meta: unknown): string | null {
  if (meta === null || meta === undefined) return null;
  try {
    return JSON.stringify(meta, null, 2) ?? String(meta);
  } catch {
    return String(meta);
  }
}

/**
 * The record the event touched. An event can point at an ad, a lead, or —
 * once that ad or lead is deleted, since both references are ON DELETE SET
 * NULL — at neither. The third case renders as an em dash with the reason
 * spelled out in its `title`, never as a blank cell: "nothing here" and "the
 * thing this event was about no longer exists" are answers to different
 * questions.
 */
function SubjectCell({ row }: { row: AdminAuditRow }) {
  const { t } = useTranslation();

  if (row.ad) {
    return (
      <CellMain title={row.ad.title} sub={t("auditSubjectAd", { id: shortId(row.ad.id) })} />
    );
  }
  if (row.lead) {
    return (
      <CellMain
        title={row.lead.fullName}
        sub={t("auditSubjectLead", { id: shortId(row.lead.id) })}
      />
    );
  }
  return (
    <span className="audit-faint" title={t("subjectDeletedTitle")}>
      {EM_DASH}
    </span>
  );
}

function ActorCell({ row }: { row: AdminAuditRow }) {
  const { t } = useTranslation();
  const actor = row.coworker ?? row.agent;

  if (!actor) {
    // Not reachable through the current schema (agentId is required), but the
    // contract types `agent` as nullable and a row that arrives without one
    // must still render as a readable record rather than crash the table.
    return <span className="audit-faint">{t("unattributed")}</span>;
  }

  const sub = row.coworker
    ? t("auditActorCoworker", { name: row.agent?.fullName ?? EM_DASH })
    : t("auditActorAgent", { id: shortId(actor.id) });

  return (
    <CellMain thumb={<Avatar name={actor.fullName} round />} title={actor.fullName} sub={sub} />
  );
}

function MetaPanel({ row }: { row: AdminAuditRow }) {
  const { t } = useTranslation();
  const meta = formatMeta(row.meta);

  return (
    <tr className="audit-drawer">
      <td colSpan={AUDIT_COLUMN_COUNT} className="audit-drawer__cell">
        {/* Full UUIDs, not the table's truncated prefixes: the reason to open
            this drawer is to carry an id somewhere else (a database query, a
            support thread), and a copied "a3f21e08…" is worse than useless. */}
        <dl className="audit-drawer__ids">
          <dt>{t("metaLabelEvent")}</dt>
          <dd>{row.id}</dd>
          <dt>{t("metaLabelAgent")}</dt>
          <dd>{row.agent?.id ?? EM_DASH}</dd>
          {row.coworker ? (
            <>
              <dt>{t("metaLabelCoworker")}</dt>
              <dd>{row.coworker.id}</dd>
            </>
          ) : null}
          {row.ad ? (
            <>
              <dt>{t("metaLabelAd")}</dt>
              <dd>{row.ad.id}</dd>
            </>
          ) : null}
          {row.lead ? (
            <>
              <dt>{t("metaLabelLead")}</dt>
              <dd>{row.lead.id}</dd>
            </>
          ) : null}
        </dl>

        <div className="audit-drawer__meta">
          <div className="audit-drawer__meta-label">{t("metaLabelMeta")}</div>
          {meta === null ? (
            <p className="audit-drawer__meta-empty">{t("metaEmpty")}</p>
          ) : (
            // Capped height with its own scroll, so a huge payload cannot
            // push the rest of the table off the screen being scanned.
            <pre className="audit-drawer__meta-body">{meta}</pre>
          )}
        </div>
      </td>
    </tr>
  );
}

export function AuditRow({
  row,
  expanded,
  onToggleMeta,
  onFilterAgent,
  agentFilterActive,
}: {
  row: AdminAuditRow;
  expanded: boolean;
  onToggleMeta: () => void;
  onFilterAgent: (agent: { id: string; fullName: string }) => void;
  /** True when the log is already narrowed to this row's agent. */
  agentFilterActive: boolean;
}) {
  const { t } = useTranslation();
  const agent = row.agent;

  return (
    <Fragment>
      <TR selected={expanded}>
        {/* Time over date, not one "03.08.2026 | 12:41" string: events arrive
            in bursts and the order of three inside the same minute is often
            the whole question, so the seconds get the prominent line. */}
        <TD mono>
          <span className="audit-time">{formatTimeOfDay(row.createdAt)}</span>
          <span className="audit-time__date">{formatDate(row.createdAt)}</span>
        </TD>
        <TD>
          <Tag tone={auditTypeTone(row.type)} dot>
            {auditTypeLabel(t, row.type)}
          </Tag>
        </TD>
        <TD>
          <ActorCell row={row} />
        </TD>
        <TD>
          <SubjectCell row={row} />
        </TD>
        <TD align="right">
          <RowActions>
            <RowAction
              icon={Filter}
              label={
                agent
                  ? t("filterLogTo", { name: agent.fullName })
                  : t("noAgentRecorded")
              }
              disabled={!agent || agentFilterActive}
              onClick={agent ? () => onFilterAgent(agent) : undefined}
            />
            {/* RowAction takes no aria-expanded (it is a ui/ primitive this
                screen does not own), so the toggle state is carried by the
                accessible name instead — which is what a screen reader
                announces on the press either way. */}
            <RowAction
              icon={Eye}
              label={expanded ? t("hideEventDetails") : t("inspectEventDetails")}
              onClick={onToggleMeta}
            />
          </RowActions>
        </TD>
      </TR>
      {expanded ? <MetaPanel row={row} /> : null}
    </Fragment>
  );
}
