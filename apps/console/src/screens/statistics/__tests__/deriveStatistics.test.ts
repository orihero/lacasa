import { describe, expect, it } from 'vitest';
import type { CoworkerStatisticEvent, Lead } from '@lacasa/api-client';
import { countCallbacksDueToday, countCoworkersActiveThisWeek } from '../deriveStatistics';

const NOW = new Date('2026-08-05T12:00:00.000Z');

function makeLead(overrides: Partial<Lead> = {}): Lead {
  return {
    id: 'l1',
    fullName: 'Dilnoza Yusupova',
    phone: '+998901234501',
    email: null,
    budget: 50000,
    comment: null,
    conversationComment: null,
    status: 'new',
    source: null,
    callbackDate: null,
    active: true,
    agentId: 'agent1',
    coworkerId: '',
    createdAt: { seconds: Math.floor(NOW.getTime() / 1000) },
    updatedAt: { seconds: Math.floor(NOW.getTime() / 1000) },
    ...overrides,
  };
}

function makeEvent(overrides: Partial<CoworkerStatisticEvent> = {}): CoworkerStatisticEvent {
  return {
    id: 'ev1',
    agentId: 'agent1',
    coworkerId: 'cw1',
    adId: '',
    leadId: '',
    stage: 'NEW',
    createdAt: { seconds: Math.floor(NOW.getTime() / 1000) },
    ...overrides,
  };
}

describe('countCallbacksDueToday', () => {
  it('counts leads whose callback is today or earlier', () => {
    const leads = [
      makeLead({ id: 'l1', callbackDate: '2026-08-05T15:00:00.000Z' }), // today
      makeLead({ id: 'l2', callbackDate: '2026-08-01T15:00:00.000Z' }), // overdue
      makeLead({ id: 'l3', callbackDate: '2026-08-10T15:00:00.000Z' }), // future
      makeLead({ id: 'l4', callbackDate: null }), // none
    ];
    expect(countCallbacksDueToday(leads, NOW)).toBe(2);
  });

  it('is zero for an empty list, never a fabricated count', () => {
    expect(countCallbacksDueToday([], NOW)).toBe(0);
  });
});

describe('countCoworkersActiveThisWeek', () => {
  it('counts each coworker once even with multiple events in range', () => {
    const events = [
      makeEvent({ coworkerId: 'cw1', createdAt: { seconds: Math.floor(NOW.getTime() / 1000) } }),
      makeEvent({ coworkerId: 'cw1', createdAt: { seconds: Math.floor(NOW.getTime() / 1000) - 3600 } }),
      makeEvent({ coworkerId: 'cw2', createdAt: { seconds: Math.floor(NOW.getTime() / 1000) - 86400 } }),
    ];
    expect(countCoworkersActiveThisWeek(events, NOW)).toBe(2);
  });

  it('excludes events older than 7 days', () => {
    const eightDaysAgoSeconds = Math.floor((NOW.getTime() - 8 * 24 * 60 * 60 * 1000) / 1000);
    const events = [makeEvent({ coworkerId: 'cw1', createdAt: { seconds: eightDaysAgoSeconds } })];
    expect(countCoworkersActiveThisWeek(events, NOW)).toBe(0);
  });

  it('is zero for an empty list', () => {
    expect(countCoworkersActiveThisWeek([], NOW)).toBe(0);
  });
});
