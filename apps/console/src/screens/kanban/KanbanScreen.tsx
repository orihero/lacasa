/**
 * src/screens/kanban/KanbanScreen — PLAN.md §3.6 (`a-kanban`) / f-console
 * `#a-kanban`. Same `useLeads()` list the Leads table renders (there is no
 * per-status endpoint — see useLeads.ts's own file header), grouped
 * client-side by `kanbanHelpers.groupLeadsByStatus` into the five real
 * `LeadStatusKey` columns. There is no sixth "Success" column: `LeadStatus`
 * has no `SUCCESS` member in Prisma yet (kanbanHelpers.ts, PLAN.md §4,
 * Decision 6.4) — the prototype's 6-column board with Bekzod's "Sold"
 * card is aspirational, flagged below rather than faked.
 *
 * Two ways to move a card, both landing on the same `useUpdateLead()`
 * mutation LeadsScreen's own StageSelect already uses:
 *  - HTML5 drag-and-drop between columns (Decision 6.5's "real DnD ships in
 *    v1" — no library, native `draggable`/`onDragOver`/`onDrop`);
 *  - each card's own "Move to…" select (KanbanCard), which is fully
 *    keyboard- and click-operable on its own — drag alone has no keyboard
 *    path, so this isn't a redundant nicety, it's the accessible route.
 * Both go through `resolveCardMoveAction` (@lacasa/domain/leads/transitions)
 * for the gate decision, since either can jump to any column. The notch
 * button (KanbanCard's "advance") is the one exception: it only ever steps
 * one place along the fixed order, so it uses kanbanHelpers' own
 * `nextStatus`/`gateFor` restatement of the same rule instead.
 *
 * Moves apply optimistically: the moved card's column updates the instant a
 * move is confirmed, before the PATCH resolves, via a local
 * `id -> LeadStatusKey` override merged over the query's own data (not a
 * shared-hook change — `useUpdateLead` stays exactly what LeadsScreen and
 * Coworkers already depend on). A failed PATCH clears the override
 * immediately (the card snaps back to its last known-good column) and
 * leaves a small "Couldn't move — try again" note on the card. A successful
 * PATCH does *not* clear the override right away: `useUpdateLead`'s own
 * `onSuccess` only *fires* `void queryClient.invalidateQueries(...)` — it
 * doesn't await the resulting refetch — so the query's cached `data` is
 * still the pre-move page for a beat after this mutation resolves. Clearing
 * the override there would flash the card back to its old column for that
 * beat before the refetch lands and moves it forward again. Instead, a
 * `useEffect` below drops an override the moment the query's own `data`
 * independently agrees with it, so the merged view never regresses.
 */
import { useEffect, useMemo, useState, type DragEvent } from 'react';
import { useNavigate } from 'react-router-dom';
import type { Lead } from '@lacasa/api-client';
import type { LeadInput, LeadStatusKey } from '@lacasa/domain';
import { resolveCardMoveAction } from '@lacasa/domain';
import { LEAD_STATUS_LABEL, LEAD_STATUS_ORDER, LEAD_STATUS_TONE } from '@/lib/labels';
import { PageHead } from '@/shell/PageHead';
import { Toolbar } from '@/shell/Toolbar';
import { Button } from '@/ui/Button';
import { FilterChip } from '@/ui/FilterChip';
import { Flag } from '@/ui/Flag';
import { Seg, type SegOption } from '@/ui/Seg';
import { EmptyState, ErrorState, LoadingState } from '@/ui/States';
import { PlusIcon, UserIcon, UsersThreeIcon } from '@/ui/icons';
import { useLeads, useUpdateLead } from '@/data/useLeads';
import { CreateLeadModal } from '../leads/CreateLeadModal';
import { asLeadStatusKey } from '@/lib/leadHelpers';
import { KanbanColumn } from './KanbanColumn';
import { StageGateModal, type GateConfirmPayload } from './StageGateModal';
import { gateFor, groupLeadsByStatus, nextStatus, type StageGateKind } from './kanbanHelpers';

type ViewMode = 'table' | 'kanban';

const VIEW_OPTIONS: ReadonlyArray<SegOption<ViewMode>> = [
  { value: 'table', label: 'Table' },
  { value: 'kanban', label: 'Kanban' },
];

interface DraggingState {
  leadId: string;
  source: LeadStatusKey;
}

interface GateState {
  lead: Lead;
  destColumn: LeadStatusKey;
  kind: StageGateKind;
}

export function KanbanScreen() {
  const { data, isLoading, isError, error, refetch } = useLeads();
  const updateLead = useUpdateLead();
  const navigate = useNavigate();

  const [createOpen, setCreateOpen] = useState(false);
  const [optimisticStatus, setOptimisticStatus] = useState<Record<string, LeadStatusKey>>({});
  const [moveErrorLeadId, setMoveErrorLeadId] = useState<string | null>(null);
  const [dragging, setDragging] = useState<DraggingState | null>(null);
  const [gate, setGate] = useState<GateState | null>(null);

  const leads = useMemo(() => data ?? [], [data]);
  const displayLeads = useMemo(
    () =>
      leads.map((lead) => {
        const override = optimisticStatus[lead.id];
        return override && override !== lead.status ? { ...lead, status: override } : lead;
      }),
    [leads, optimisticStatus],
  );
  const columns = useMemo(() => groupLeadsByStatus(displayLeads), [displayLeads]);
  const leadsById = useMemo(() => new Map(displayLeads.map((lead) => [lead.id, lead])), [displayLeads]);

  // Self-heals the optimistic map against the query's own `data` once a
  // background refetch (kicked off by useUpdateLead's onSuccess) actually
  // lands — see the file header on why a successful mutation can't just
  // clear its override synchronously without a visible regression flicker.
  useEffect(() => {
    setOptimisticStatus((prev) => {
      if (Object.keys(prev).length === 0) return prev;
      let changed = false;
      const next = { ...prev };
      for (const lead of leads) {
        if (next[lead.id] === lead.status) {
          delete next[lead.id];
          changed = true;
        }
      }
      return changed ? next : prev;
    });
  }, [leads]);

  function commitMove(lead: Lead, destColumn: LeadStatusKey, extra: Partial<LeadInput> = {}) {
    setOptimisticStatus((prev) => ({ ...prev, [lead.id]: destColumn }));
    setMoveErrorLeadId((prev) => (prev === lead.id ? null : prev));
    updateLead.mutate(
      { id: lead.id, input: { status: destColumn, ...extra } },
      {
        onError: () => {
          setOptimisticStatus((prev) => {
            const next = { ...prev };
            delete next[lead.id];
            return next;
          });
          setMoveErrorLeadId(lead.id);
        },
        // No onSuccess override-clear here — see the file header. The
        // useEffect above clears it once `leads` itself catches up.
      },
    );
  }

  function attemptMove(lead: Lead, source: LeadStatusKey, dest: LeadStatusKey) {
    if (source === dest) return;
    const action = resolveCardMoveAction(source, dest, lead);
    if (action.type === 'move') {
      commitMove(lead, dest);
    } else {
      setGate({ lead, destColumn: dest, kind: action.type === 'confirm-callback' ? 'callback' : 'note' });
    }
  }

  function handleAdvance(lead: Lead) {
    const current = asLeadStatusKey(lead.status);
    if (!current) return;
    const next = nextStatus(current);
    if (!next) return;
    const kind = gateFor(next);
    if (!kind) {
      commitMove(lead, next);
      return;
    }
    setGate({ lead, destColumn: next, kind });
  }

  function handleMoveTo(lead: Lead, dest: LeadStatusKey) {
    const current = asLeadStatusKey(lead.status);
    if (!current) return;
    attemptMove(lead, current, dest);
  }

  function handleDrop(destColumn: LeadStatusKey) {
    if (!dragging) return;
    const lead = leadsById.get(dragging.leadId);
    const source = dragging.source;
    setDragging(null);
    if (!lead) return;
    attemptMove(lead, source, destColumn);
  }

  function handleGateConfirm(payload: GateConfirmPayload) {
    if (!gate) return;
    commitMove(gate.lead, gate.destColumn, payload);
    setGate(null);
  }

  return (
    <>
      <PageHead crumb="Console · Pipeline" title="Kanban" />

      <Toolbar>
        <Seg
          options={VIEW_OPTIONS}
          value="kanban"
          onChange={(next) => {
            if (next === 'table') navigate('/leads');
          }}
        />
        <FilterChip icon={UserIcon}>All agents</FilterChip>
        <div className="flex-1" />
        {/* Same CTA/mutation as Leads' own "Create lead", but `dark`, not
            `primary`: PLAN.md §1's accent-discipline table gives Kanban
            *zero* accent things ("none — the 5-color dot system already
            carries the semantics"), unlike Leads' own row, which names
            "Create lead" as its one lime CTA. Reusing `primary` here would
            put a second lime element on a screen the table says gets none —
            the same reasoning MyAdsScreen's own "Add new post" CTA docs for
            why it stays `dark` next to the topbar's global lime button. */}
        <Button variant="dark" icon={PlusIcon} onClick={() => setCreateOpen(true)}>
          Create lead
        </Button>
      </Toolbar>

      <Flag>
        The board&apos;s planned sixth stage — Success (&quot;Closed&quot;, a completed deal) — needs a{' '}
        <span className="font-mono">LeadStatus.SUCCESS</span> member that hasn&apos;t landed in the Prisma schema
        yet. Only the five statuses that exist today are shown:{' '}
        {LEAD_STATUS_ORDER.map((key) => LEAD_STATUS_LABEL[key]).join(', ')}. Drag a card between columns, or use its
        &quot;Move to…&quot; menu — moving to Need to call back asks for a callback time, and moving to Rejected or
        Accepted asks for a note.
      </Flag>

      {isLoading ? <LoadingState label="Loading leads…" /> : null}
      {isError ? <ErrorState error={error} onRetry={() => void refetch()} /> : null}
      {!isLoading && !isError && leads.length === 0 ? (
        <EmptyState
          icon={UsersThreeIcon}
          title="No leads yet"
          sub="New leads you create or receive will show up here, grouped by stage."
        />
      ) : null}

      {!isLoading && !isError && leads.length > 0 ? (
        <div className="grid grid-cols-1 gap-3.5 sm:grid-cols-2 lg:grid-cols-5">
          {LEAD_STATUS_ORDER.map((statusKey) => (
            <KanbanColumn
              key={statusKey}
              statusKey={statusKey}
              tone={LEAD_STATUS_TONE[statusKey]}
              leads={columns[statusKey]}
              draggingLeadId={dragging?.leadId ?? null}
              pendingLeadId={updateLead.isPending ? (updateLead.variables?.id ?? null) : null}
              failedLeadId={moveErrorLeadId}
              onAdvance={handleAdvance}
              onMoveTo={handleMoveTo}
              onCardDragStart={(lead) => (event: DragEvent<HTMLDivElement>) => {
                event.dataTransfer.effectAllowed = 'move';
                event.dataTransfer.setData('text/plain', lead.id);
                setDragging({ leadId: lead.id, source: statusKey });
              }}
              onCardDragEnd={() => setDragging(null)}
              onDrop={handleDrop}
            />
          ))}
        </div>
      ) : null}

      {gate ? (
        <StageGateModal
          leadName={gate.lead.fullName}
          destColumn={gate.destColumn}
          kind={gate.kind}
          pending={updateLead.isPending && updateLead.variables?.id === gate.lead.id}
          onCancel={() => setGate(null)}
          onConfirm={handleGateConfirm}
        />
      ) : null}

      {createOpen ? <CreateLeadModal onClose={() => setCreateOpen(false)} /> : null}
    </>
  );
}
