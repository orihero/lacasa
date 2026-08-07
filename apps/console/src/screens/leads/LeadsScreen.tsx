/**
 * src/screens/leads/LeadsScreen — PLAN.md §3.5 (`a-leads`) / f-console.src.html
 * `#a-leads`. Renders whatever `useLeads()` actually returns — the
 * prototype's 6 rows are illustrative seed data and the rail's `Leads 27`
 * badge is a live aggregate that intentionally differs from it (PLAN.md §4);
 * this screen has no separate seed of its own to keep in sync with either.
 *
 * Two data-honesty calls specific to this screen, beyond the shared Flag
 * below the toolbar:
 *  - Budget renders as a plain `formatMoney(lead.budget)`, never with a
 *    "/month" suffix. The prototype's seed shows "/month" on a couple of
 *    rows (Malika Tosheva's office rental, Nodira Ergasheva's studio), but
 *    that's copy written by hand against the free-text `comment` field —
 *    `Lead` has no `category`/`priceType` the way `Ad` does, so there is no
 *    real signal to derive rent-vs-sale from. Guessing from keywords in
 *    `comment` ("rental", "office") would be exactly the kind of fabricated
 *    inference PLAN.md §4 rules out.
 *  - "Agent" (the prototype's 6th column, an `avchip` per row) is not
 *    rendered here at all: it isn't in this screen's column spec, and seed
 *    aside, every lead in `useLeads()` is already scoped to the signed-in
 *    agent's own context server-side (leadService.js's `listLeads`) — there
 *    is no second agent identity on a `Lead` to show per row.
 */
import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import type { Lead } from '@lacasa/api-client';
import type { LeadStatusKey } from '@lacasa/domain';
import { formatDateTime, formatMoney } from '@/lib/format';
import { LEAD_STATUS_LABEL, LEAD_STATUS_ORDER, LEAD_STATUS_TONE } from '@/lib/labels';
import { PageHead } from '@/shell/PageHead';
import { Toolbar } from '@/shell/Toolbar';
import { Avatar } from '@/ui/Avatar';
import { Button } from '@/ui/Button';
import { FilterChip } from '@/ui/FilterChip';
import { Flag } from '@/ui/Flag';
import { Panel } from '@/ui/Panel';
import { Seg, type SegOption } from '@/ui/Seg';
import { CellMain, Table, TBody, TD, TH, THead, TR } from '@/ui/Table';
import { Tag } from '@/ui/Tag';
import { EmptyState, ErrorState, TableSkeleton } from '@/ui/States';
import { ClockIcon, FunnelIcon, PlusIcon, UserIcon, UsersThreeIcon } from '@/ui/icons';
import { useLeads, useUpdateLead } from '@/data/useLeads';
import { CreateLeadModal } from './CreateLeadModal';
import { StageSelect } from './StageSelect';
import { asLeadStatusKey, isCallbackDueOrOverdue } from './leadHelpers';

const COLUMN_COUNT = 6;

type ViewMode = 'table' | 'kanban';

const VIEW_OPTIONS: ReadonlyArray<SegOption<ViewMode>> = [
  { value: 'table', label: 'Table' },
  { value: 'kanban', label: 'Kanban' },
];

export function LeadsScreen() {
  const { data: leads, isLoading, isError, error, refetch } = useLeads();
  const updateLead = useUpdateLead();
  const navigate = useNavigate();
  const [createOpen, setCreateOpen] = useState(false);

  return (
    <>
      <PageHead crumb="Console · Pipeline" title="Leads" />

      <Toolbar>
        <Seg
          options={VIEW_OPTIONS}
          value="table"
          onChange={(next) => {
            if (next === 'kanban') navigate('/leads/kanban');
          }}
        />
        {/* Inert per FilterChip's own convention (no onClick, no fake
            affordance) — matches the prototype's "All stages"/"All agents"
            chips, which are wired to nothing there either. */}
        <FilterChip icon={FunnelIcon}>All stages</FilterChip>
        <FilterChip icon={UserIcon}>All agents</FilterChip>
        <div className="flex-1" />
        {/* The screen's one accent element (PLAN.md §1's accent-discipline
            table), paired with the "New" stage's row tint below — the same
            CTA-plus-row-tint pairing My ads uses for ad1001. */}
        <Button variant="primary" icon={PlusIcon} onClick={() => setCreateOpen(true)}>
          Create lead
        </Button>
      </Toolbar>

      <Flag>
        The Kanban board&apos;s planned sixth stage — Success (&quot;Closed&quot;, a completed deal) — needs a{' '}
        <span className="font-mono">LeadStatus.SUCCESS</span> member that hasn&apos;t landed in the Prisma schema yet.
        This table and its stage picker only offer the five statuses that exist today:{' '}
        {LEAD_STATUS_ORDER.map((key) => LEAD_STATUS_LABEL[key]).join(', ')}.
      </Flag>

      <Panel>
        <Table>
          <THead>
            <tr>
              <TH>Lead</TH>
              <TH>Interest</TH>
              <TH align="right">Budget</TH>
              <TH>Stage</TH>
              <TH>Callback</TH>
              <TH>Created</TH>
            </tr>
          </THead>
          {isLoading ? <TableSkeleton rows={6} cols={COLUMN_COUNT} /> : null}
          {!isLoading && !isError && leads && leads.length > 0 ? (
            <TBody>
              {leads.map((lead) => (
                <LeadRow
                  key={lead.id}
                  lead={lead}
                  onStageChange={(status) => updateLead.mutate({ id: lead.id, input: { status } })}
                  pending={updateLead.isPending && updateLead.variables?.id === lead.id}
                  failed={updateLead.isError && updateLead.variables?.id === lead.id}
                />
              ))}
            </TBody>
          ) : null}
        </Table>

        {isError ? <ErrorState error={error} onRetry={() => void refetch()} /> : null}
        {!isLoading && !isError && leads && leads.length === 0 ? (
          <EmptyState
            icon={UsersThreeIcon}
            title="No leads yet"
            sub="New leads you create or receive will show up here."
          />
        ) : null}
      </Panel>

      {createOpen ? <CreateLeadModal onClose={() => setCreateOpen(false)} /> : null}
    </>
  );
}

function LeadRow({
  lead,
  onStageChange,
  pending,
  failed,
}: {
  lead: Lead;
  onStageChange: (status: LeadStatusKey) => void;
  pending: boolean;
  failed: boolean;
}) {
  const statusKey = asLeadStatusKey(lead.status);
  const tone = statusKey ? LEAD_STATUS_TONE[statusKey] : 'mute';
  const dueOrOverdue = isCallbackDueOrOverdue(lead.callbackDate);

  return (
    <TR selected={statusKey === 'new'}>
      <TD>
        <CellMain
          thumb={<Avatar name={lead.fullName} tone={tone} />}
          title={lead.fullName}
          sub={<span className="font-mono">{lead.phone}</span>}
        />
      </TD>
      <TD>{lead.comment ?? <span className="text-ink-2">—</span>}</TD>
      <TD align="right" className="tabular-nums">
        {formatMoney(lead.budget)}
      </TD>
      <TD>
        {statusKey ? (
          <StageSelect
            value={statusKey}
            tone={tone}
            label={`Stage for ${lead.fullName}`}
            disabled={pending}
            onChange={onStageChange}
          />
        ) : (
          // A status string outside the five known LeadStatus members —
          // shouldn't happen (the enum is DB-enforced), but a `<select>`
          // whose options don't include the current value would silently
          // "change" it the moment it renders. Read-only fallback instead.
          <Tag tone="mute">{lead.status}</Tag>
        )}
        {failed ? <p className="mt-1 text-tiny text-err">Couldn&apos;t update — try again.</p> : null}
      </TD>
      <TD>
        {lead.callbackDate ? (
          dueOrOverdue ? (
            <Tag tone="warn" icon={ClockIcon}>
              {formatDateTime(lead.callbackDate)}
            </Tag>
          ) : (
            <span className="text-ink-2">{formatDateTime(lead.callbackDate)}</span>
          )
        ) : (
          <span className="text-ink-2">—</span>
        )}
      </TD>
      <TD>
        <span className="text-ink-2">{formatDateTime(lead.createdAt)}</span>
      </TD>
    </TR>
  );
}
