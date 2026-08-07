/**
 * src/screens/kanban/kanbanHelpers — pure logic behind the kanban board's
 * two real rules: which column a lead belongs in, and which drag/advance
 * moves require a gate before they're allowed to happen (Decision 6.5,
 * mockups/f/PLAN.md §3.6).
 *
 * Column order is LEAD_STATUS_ORDER (labels.ts), the same five real
 * LeadStatusKey members Leads' own stage picker offers — there is no sixth
 * "Success" column here (PLAN.md §4, Decision 6.4: `LeadStatus.SUCCESS`
 * doesn't exist in Prisma yet). "Advance stage" (the cut-corner notch
 * button) and a drag both move a card exactly one step along this same
 * fixed order; there is no reordering and no jumping columns.
 */
import type { Lead } from '@lacasa/api-client';
import type { LeadStatusKey } from '@lacasa/domain';
import { LEAD_STATUS_ORDER } from '@/lib/labels';
import { asLeadStatusKey } from '../leads/leadHelpers';

export type KanbanColumns = Record<LeadStatusKey, Lead[]>;

/** Leads whose `status` isn't one of the five known LeadStatusKey values
 * (shouldn't happen — the enum is DB-enforced) are dropped rather than
 * guessed into a column; see asLeadStatusKey's own doc comment. */
export function groupLeadsByStatus(leads: readonly Lead[]): KanbanColumns {
  const columns = Object.fromEntries(LEAD_STATUS_ORDER.map((key) => [key, [] as Lead[]])) as KanbanColumns;
  for (const lead of leads) {
    const key = asLeadStatusKey(lead.status);
    if (key) columns[key].push(lead);
  }
  return columns;
}

/** The next column along the fixed order, or `null` once a lead is already
 * in the last real column (Accepted) — there is nothing further to advance
 * to without the not-yet-real Success status. */
export function nextStatus(current: LeadStatusKey): LeadStatusKey | null {
  const index = LEAD_STATUS_ORDER.indexOf(current);
  const next = LEAD_STATUS_ORDER[index + 1];
  return next ?? null;
}

export type StageGateKind = 'callback' | 'note';

/**
 * Decision 6.5's required-field gate: moving to Need-to-call-back needs a
 * callback datetime, moving to Rejected/Accepted needs a note of real
 * substance. Moving to New or Could-not-connect needs neither — those two
 * are immediate. (The gate's third case, "sold-ad reference + note on move
 * to Success", doesn't apply to anything reachable here — Success isn't a
 * real column.)
 */
export function gateFor(target: LeadStatusKey): StageGateKind | null {
  if (target === 'need_to_call_back') return 'callback';
  if (target === 'rejected' || target === 'accepted') return 'note';
  return null;
}

/** Decision 6.5's "≥10-char note" — trimmed, so whitespace alone can't pass. */
export function isNoteValid(note: string): boolean {
  return note.trim().length >= 10;
}
