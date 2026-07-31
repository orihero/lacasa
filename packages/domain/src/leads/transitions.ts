// Ported from the inline branching in LeadKanbanList.tsx's `handleCardMove`
// drag handler (apps/web/src/components/leadList/LeadKanbanList.tsx):
// dropping a card on "need_to_call_back" opens a callback-time modal,
// dropping on "rejected" or "accepted" opens a comment modal, and every
// other column moves the card immediately.
import type { LeadStatusKey } from '../enums/leads';

/** Dropping on this column requires collecting a callback time first. */
export function needsCallbackConfirmation(destColumn: LeadStatusKey): boolean {
  return destColumn === 'need_to_call_back';
}

/** Dropping on either of these terminal columns requires a comment first. */
export function needsCommentConfirmation(destColumn: LeadStatusKey): boolean {
  return destColumn === 'rejected' || destColumn === 'accepted';
}

export type CardMoveAction<TCard> =
  | { type: 'move' }
  | { type: 'confirm-callback'; card: TCard }
  | { type: 'confirm-comment'; card: TCard };

/**
 * Pure decision function for a Kanban drag-and-drop: given the column a
 * lead card was dragged from and to, decides whether the move can happen
 * immediately or must first be confirmed through a modal (and if so,
 * which one). The caller stays responsible for actually moving the card
 * and persisting the status change.
 */
// eslint-disable-next-line @typescript-eslint/no-unused-vars -- sourceColumn
// isn't part of the decision today, but is kept in the signature for parity
// with the call site (which always has it) and for future rules that may.
export function resolveCardMoveAction<TCard>(
  sourceColumn: LeadStatusKey,
  destColumn: LeadStatusKey,
  card: TCard,
): CardMoveAction<TCard> {
  if (needsCallbackConfirmation(destColumn)) {
    return { type: 'confirm-callback', card };
  }
  if (needsCommentConfirmation(destColumn)) {
    return { type: 'confirm-comment', card };
  }
  return { type: 'move' };
}
