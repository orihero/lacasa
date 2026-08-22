/**
 * KanbanColumn — one of the five fixed, non-reorderable stages (F's `.kb__c`
 * — see kanbanHelpers.ts's file header on why there are five, not the
 * prototype's six). Owns only the drag-over visual state and event
 * plumbing; the actual move decision (immediate vs. gated) lives in
 * KanbanScreen, which is the one place that knows about every lead by id.
 */
import { useState, type DragEvent } from 'react';
import clsx from 'clsx';
import type { Lead } from '@lacasa/api-client';
import type { LeadStatusKey } from '@lacasa/domain';
import { LEAD_STATUS_LABEL } from '@/lib/labels';
import type { Tone } from '@/ui/Tag';
import { KanbanCard } from './KanbanCard';

export function KanbanColumn({
  statusKey,
  tone,
  leads,
  draggingLeadId,
  pendingLeadId,
  failedLeadId,
  onAdvance,
  onMoveTo,
  onCardDragStart,
  onCardDragEnd,
  onDrop,
}: {
  statusKey: LeadStatusKey;
  tone: Tone;
  leads: readonly Lead[];
  draggingLeadId: string | null;
  pendingLeadId: string | null;
  failedLeadId: string | null;
  onAdvance: (lead: Lead) => void;
  onMoveTo: (lead: Lead, next: LeadStatusKey) => void;
  onCardDragStart: (lead: Lead) => (event: DragEvent<HTMLDivElement>) => void;
  onCardDragEnd: () => void;
  onDrop: (statusKey: LeadStatusKey) => void;
}) {
  const [isOver, setIsOver] = useState(false);
  const label = LEAD_STATUS_LABEL[statusKey];

  return (
    <div
      data-testid={`kanban-column-${statusKey}`}
      onDragOver={(event) => {
        event.preventDefault();
        if (!isOver) setIsOver(true);
      }}
      onDragLeave={() => setIsOver(false)}
      onDrop={(event) => {
        event.preventDefault();
        setIsOver(false);
        onDrop(statusKey);
      }}
      className={clsx(
        'rounded-kanban p-1',
        isOver && 'bg-accent-tint/40 outline outline-2 outline-dashed outline-offset-2 outline-accent-text/35',
      )}
    >
      <div className={clsx('mb-1 flex items-center gap-[7px] whitespace-nowrap px-2 pb-3 pt-2 text-tiny font-semibold', TONE_TEXT_CLASS[tone])}>
        <span aria-hidden="true" className="h-2 w-2 shrink-0 rounded-full bg-current" />
        <span className="text-ink">{label}</span>
        <em className="ml-auto rounded-full bg-surface-inner px-2 py-[1px] text-mini font-semibold not-italic text-ink">
          {leads.length}
        </em>
      </div>

      {leads.map((lead) => (
        <KanbanCard
          key={lead.id}
          lead={lead}
          statusKey={statusKey}
          tone={tone}
          canAdvance={CAN_ADVANCE[statusKey]}
          pending={pendingLeadId === lead.id}
          failed={failedLeadId === lead.id}
          dragging={draggingLeadId === lead.id}
          onAdvance={() => onAdvance(lead)}
          onMoveTo={(next) => onMoveTo(lead, next)}
          onDragStart={onCardDragStart(lead)}
          onDragEnd={onCardDragEnd}
        />
      ))}

      {leads.length === 0 ? (
        <div className="rounded-kanban border-1.5 border-dashed border-black/[.14] px-2.5 py-[22px] text-center text-caption text-ink-2">
          No leads in {label.toLowerCase()}
        </div>
      ) : null}
    </div>
  );
}

const TONE_TEXT_CLASS: Record<Tone, string> = {
  ok: 'text-ok',
  warn: 'text-warn',
  err: 'text-err',
  info: 'text-info',
  mute: 'text-mute',
  accent: 'text-accent-text',
};

// Accepted is the last real column (no LeadStatus.SUCCESS to advance into
// yet, see kanbanHelpers.ts) — its cards have no "advance" affordance, only
// the "Move to…" select for a deliberate reassignment.
const CAN_ADVANCE: Record<LeadStatusKey, boolean> = {
  new: true,
  could_not_connect: true,
  need_to_call_back: true,
  rejected: true,
  accepted: false,
};
