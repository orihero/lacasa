/**
 * KanbanCard — F's cut-corner notch card (`.kbc`, f-components.css), ported
 * as one real lead. Two move affordances live on every card, deliberately
 * redundant with each other so the board is usable without a mouse:
 *  - the notch button in the corner (`.notch-btn`) advances exactly one
 *    step along the fixed column order (kanbanHelpers.nextStatus/gateFor) —
 *    matches the prototype pixel-for-pixel;
 *  - a native `<select>` ("Move to…") lets keyboard/click users jump to any
 *    of the five columns directly, the same escape hatch StageSelect gives
 *    the Leads table. Native drag alone (HTML5 dnd) has no keyboard path at
 *    all, so this is required, not decorative — see the screen brief.
 *
 * There is no per-lead "assigned agent" footer chip (the prototype's
 * `ag-javlon`/`ag-shahnoza` avatars): `Lead` carries no agent-identity field
 * of its own (every lead is already scoped to the signed-in agent server
 * side — see leadHelpers.ts's file header on LeadsScreen's own Agent
 * column), so rendering one here would be exactly the fabricated per-row
 * identity PLAN.md §4 rules out. The footer instead shows whichever *real*
 * signal the lead actually carries: a due/overdue callback tag (mirrors
 * LeadsScreen's own isCallbackDueOrOverdue treatment) or the note left when
 * the lead was moved into a gated stage (`conversationComment`) — never
 * both, and omitted entirely when neither exists.
 */
import type { DragEvent } from 'react';
import clsx from 'clsx';
import type { Lead } from '@lacasa/api-client';
import type { LeadStatusKey } from '@lacasa/domain';
import { formatDateTime, formatMoney } from '@/lib/format';
import { LEAD_STATUS_LABEL, LEAD_STATUS_ORDER } from '@/lib/labels';
import { Avatar } from '@/ui/Avatar';
import { IconButton } from '@/ui/IconButton';
import { Tag } from '@/ui/Tag';
import { ArrowRightIcon, ClockIcon } from '@/ui/icons';
import { isCallbackDueOrOverdue } from '@/lib/leadHelpers';
import type { Tone } from '@/ui/Tag';

export function KanbanCard({
  lead,
  statusKey,
  tone,
  canAdvance,
  pending,
  failed,
  dragging,
  onAdvance,
  onMoveTo,
  onDragStart,
  onDragEnd,
}: {
  lead: Lead;
  statusKey: LeadStatusKey;
  tone: Tone;
  canAdvance: boolean;
  pending: boolean;
  failed: boolean;
  dragging: boolean;
  onAdvance: () => void;
  onMoveTo: (next: LeadStatusKey) => void;
  onDragStart: (event: DragEvent<HTMLDivElement>) => void;
  onDragEnd: () => void;
}) {
  const dueOrOverdue = isCallbackDueOrOverdue(lead.callbackDate);
  const reasonNote = lead.conversationComment?.trim();

  return (
    <div
      data-testid={`kanban-card-${lead.id}`}
      draggable
      onDragStart={onDragStart}
      onDragEnd={onDragEnd}
      className={clsx(
        'relative mb-3 cursor-grab rounded-kanban border border-black/[.03] bg-surface p-3.5 active:cursor-grabbing',
        statusKey === 'need_to_call_back' && dueOrOverdue && 'border-l-[3px] border-l-warn',
        dragging && 'opacity-45',
      )}
    >
      {canAdvance ? (
        <IconButton
          icon={ArrowRightIcon}
          label={`Advance ${lead.fullName} to the next stage`}
          size="sm"
          disabled={pending}
          onClick={onAdvance}
          className="absolute right-2 top-2"
        />
      ) : null}

      <div className={clsx('mb-2.5 flex items-center gap-2.5', canAdvance && 'pr-9')}>
        <Avatar name={lead.fullName} tone={tone} />
        <b className="text-label font-semibold leading-tight text-ink">{lead.fullName}</b>
      </div>

      <div className="mb-2.5 rounded-chip bg-pill px-2.5 py-2">
        <span className="mb-[3px] block font-mono text-tiny text-ink-2">
          {lead.phone} · {formatMoney(lead.budget)}
        </span>
        {lead.comment ? <p className="text-caption leading-[1.45] text-ink">{lead.comment}</p> : null}
      </div>

      <div className="mb-2.5 flex min-h-[22px] items-center gap-[7px] text-caption text-ink-2">
        {lead.callbackDate ? (
          dueOrOverdue ? (
            <Tag tone="warn" icon={ClockIcon}>
              {formatDateTime(lead.callbackDate)}
            </Tag>
          ) : (
            <span>{formatDateTime(lead.callbackDate)}</span>
          )
        ) : reasonNote ? (
          <span className="truncate italic">{reasonNote}</span>
        ) : null}
      </div>

      <label className="block">
        <span className="sr-only">Move {lead.fullName} to a different stage</span>
        <select
          aria-label={`Move ${lead.fullName} to a different stage`}
          value={statusKey}
          disabled={pending}
          onChange={(event) => {
            const next = event.target.value as LeadStatusKey;
            if (next !== statusKey) onMoveTo(next);
          }}
          className="w-full cursor-pointer rounded-chip border border-hairline bg-pill px-2.5 py-[5px] text-tiny text-ink-2 focus:outline-none focus-visible:ring-2 focus-visible:ring-dark disabled:cursor-wait disabled:opacity-60"
        >
          {LEAD_STATUS_ORDER.map((key) => (
            <option key={key} value={key}>
              {key === statusKey ? `${LEAD_STATUS_LABEL[key]} (current)` : `Move to ${LEAD_STATUS_LABEL[key]}`}
            </option>
          ))}
        </select>
      </label>

      {failed ? <p className="mt-1.5 text-tiny text-err">Couldn&apos;t move — try again.</p> : null}
    </div>
  );
}
