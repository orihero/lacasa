import { describe, expect, it } from 'vitest';
import type { Lead } from '@lacasa/api-client';
import { gateFor, groupLeadsByStatus, isNoteValid, nextStatus } from '../kanbanHelpers';

function makeLead(overrides: Partial<Lead> = {}): Lead {
  return {
    id: 'lead-1',
    fullName: 'Dilnoza Yusupova',
    phone: '+998901234501',
    email: null,
    budget: 50000,
    comment: '2–3 room apartment, Chilonzor or Yunusobod',
    conversationComment: null,
    status: 'new',
    source: null,
    callbackDate: null,
    active: true,
    agentId: 'agent-1',
    coworkerId: '',
    createdAt: { seconds: 1_722_600_000 },
    updatedAt: { seconds: 1_722_600_000 },
    ...overrides,
  };
}

describe('groupLeadsByStatus', () => {
  it('buckets leads into the five real LeadStatusKey columns, in LEAD_STATUS_ORDER', () => {
    const leads = [
      makeLead({ id: 'l1', status: 'new' }),
      makeLead({ id: 'l2', status: 'accepted' }),
      makeLead({ id: 'l3', status: 'new' }),
      makeLead({ id: 'l4', status: 'need_to_call_back' }),
    ];
    const columns = groupLeadsByStatus(leads);

    expect(Object.keys(columns)).toEqual([
      'new',
      'could_not_connect',
      'need_to_call_back',
      'rejected',
      'accepted',
    ]);
    expect(columns.new.map((l) => l.id)).toEqual(['l1', 'l3']);
    expect(columns.accepted.map((l) => l.id)).toEqual(['l2']);
    expect(columns.need_to_call_back.map((l) => l.id)).toEqual(['l4']);
    expect(columns.could_not_connect).toEqual([]);
    expect(columns.rejected).toEqual([]);
  });

  it('drops a lead whose status is outside the five real members, rather than guessing a column', () => {
    const leads = [makeLead({ id: 'l1', status: 'success' }), makeLead({ id: 'l2', status: 'new' })];
    const columns = groupLeadsByStatus(leads);

    const allIds = Object.values(columns).flatMap((col) => col.map((l) => l.id));
    expect(allIds).toEqual(['l2']);
  });

  it('returns every column even when there are no leads at all', () => {
    const columns = groupLeadsByStatus([]);
    expect(columns).toEqual({
      new: [],
      could_not_connect: [],
      need_to_call_back: [],
      rejected: [],
      accepted: [],
    });
  });
});

describe('nextStatus', () => {
  it('steps forward one column at a time along the fixed order', () => {
    expect(nextStatus('new')).toBe('could_not_connect');
    expect(nextStatus('could_not_connect')).toBe('need_to_call_back');
    expect(nextStatus('need_to_call_back')).toBe('rejected');
    expect(nextStatus('rejected')).toBe('accepted');
  });

  it('returns null once already in Accepted — nothing further to advance to', () => {
    expect(nextStatus('accepted')).toBeNull();
  });
});

describe('gateFor', () => {
  it('requires a callback gate only for Need to call back', () => {
    expect(gateFor('need_to_call_back')).toBe('callback');
  });

  it('requires a note gate for Rejected and Accepted', () => {
    expect(gateFor('rejected')).toBe('note');
    expect(gateFor('accepted')).toBe('note');
  });

  it('requires no gate for New or Could not connect', () => {
    expect(gateFor('new')).toBeNull();
    expect(gateFor('could_not_connect')).toBeNull();
  });
});

describe('isNoteValid', () => {
  it('rejects a note under 10 trimmed characters', () => {
    expect(isNoteValid('too short')).toBe(false);
    expect(isNoteValid('         ')).toBe(false);
    expect(isNoteValid('')).toBe(false);
  });

  it('accepts a note of 10 or more trimmed characters', () => {
    expect(isNoteValid('Budget mismatch, will not proceed')).toBe(true);
    expect(isNoteValid('  exactly ten chars padded  ')).toBe(true);
  });
});
