import { describe, expect, it } from 'vitest';
import type { LeadStatusKey } from '../enums/leads';
import { LEAD_STATUS } from '../enums/leads';
import {
  needsCallbackConfirmation,
  needsCommentConfirmation,
  resolveCardMoveAction,
} from './transitions';

const COLUMNS = Object.keys(LEAD_STATUS) as LeadStatusKey[];

describe('needsCallbackConfirmation', () => {
  it('is true only for need_to_call_back', () => {
    for (const column of COLUMNS) {
      expect(needsCallbackConfirmation(column)).toBe(column === 'need_to_call_back');
    }
  });
});

describe('needsCommentConfirmation', () => {
  it('is true only for rejected and accepted', () => {
    for (const column of COLUMNS) {
      expect(needsCommentConfirmation(column)).toBe(
        column === 'rejected' || column === 'accepted',
      );
    }
  });
});

describe('resolveCardMoveAction', () => {
  const card = { id: 'lead-1' };

  // Every (source, dest) pair — the source column never affects the
  // decision, but the contract is that only the destination does, so this
  // proves that for the full cross product.
  for (const source of COLUMNS) {
    for (const dest of COLUMNS) {
      it(`${source} -> ${dest}`, () => {
        const action = resolveCardMoveAction(source, dest, card);
        if (dest === 'need_to_call_back') {
          expect(action).toEqual({ type: 'confirm-callback', card });
        } else if (dest === 'rejected' || dest === 'accepted') {
          expect(action).toEqual({ type: 'confirm-comment', card });
        } else {
          expect(action).toEqual({ type: 'move' });
        }
      });
    }
  }
});
