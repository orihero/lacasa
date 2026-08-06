import { describe, expect, it } from 'vitest';
import { asLeadStatusKey, isCallbackDueOrOverdue } from '../leadHelpers';

describe('isCallbackDueOrOverdue', () => {
  // Local-time Date objects throughout (never a 'Z'-suffixed ISO literal
  // compared against a fixed instant) so this test's notion of "today" can
  // never disagree with the host machine's own timezone the way a
  // UTC-anchored fixture would.
  const now = new Date(2026, 7, 5, 10, 0, 0); // Wed 05 Aug 2026, 10:00 local

  it('is false when there is no callback date at all', () => {
    expect(isCallbackDueOrOverdue(null, now)).toBe(false);
    expect(isCallbackDueOrOverdue(undefined, now)).toBe(false);
  });

  it('is true for a callback later today, even before that hour arrives', () => {
    expect(isCallbackDueOrOverdue(new Date(2026, 7, 5, 23, 0, 0), now)).toBe(true);
  });

  it('is true for a callback earlier today', () => {
    expect(isCallbackDueOrOverdue(new Date(2026, 7, 5, 0, 30, 0), now)).toBe(true);
  });

  it('is true for a callback on a past day (overdue)', () => {
    expect(isCallbackDueOrOverdue(new Date(2026, 7, 1, 0, 0, 0), now)).toBe(true);
  });

  it('is false for a callback on a future day', () => {
    expect(isCallbackDueOrOverdue(new Date(2026, 7, 6, 0, 0, 0), now)).toBe(false);
  });

  it('is false for an unparseable date instead of throwing', () => {
    expect(isCallbackDueOrOverdue('not-a-date', now)).toBe(false);
  });
});

describe('asLeadStatusKey', () => {
  it('accepts every real LeadStatus wire value', () => {
    expect(asLeadStatusKey('new')).toBe('new');
    expect(asLeadStatusKey('could_not_connect')).toBe('could_not_connect');
    expect(asLeadStatusKey('need_to_call_back')).toBe('need_to_call_back');
    expect(asLeadStatusKey('rejected')).toBe('rejected');
    expect(asLeadStatusKey('accepted')).toBe('accepted');
  });

  it('returns undefined for anything outside the five real members, including the not-yet-real "success"', () => {
    expect(asLeadStatusKey('success')).toBeUndefined();
    expect(asLeadStatusKey('SUCCESS')).toBeUndefined();
    expect(asLeadStatusKey('')).toBeUndefined();
  });
});
