import { describe, expect, it } from 'vitest';
import type { Ad, CoworkerStatisticEvent } from '@lacasa/api-client';
import { deriveCoworkerMetrics } from '../useCoworkers';

function ad(coworkerId: string | null): Ad {
  return {
    id: `ad-${Math.random()}`,
    agentId: 'agent-1',
    coworkerId,
    photos: [],
    media: [],
    lat: null,
    lng: null,
    tour3dLink: null,
  };
}

function event(coworkerId: string, seconds: number): CoworkerStatisticEvent {
  return {
    id: `evt-${seconds}`,
    agentId: 'agent-1',
    coworkerId,
    adId: 'ad-1',
    leadId: 'lead-1',
    stage: 'LEAD_CREATED',
    createdAt: { seconds },
  };
}

describe('deriveCoworkerMetrics', () => {
  it('counts only ads whose coworkerId matches', () => {
    const ads = [ad('sardor'), ad('sardor'), ad('kamola'), ad(null)];
    const { listingsCount } = deriveCoworkerMetrics('sardor', ads, []);
    expect(listingsCount).toBe(2);
  });

  it('returns 0 listings and a null last-active when nothing matches', () => {
    const metrics = deriveCoworkerMetrics('nobody', [ad('sardor')], [event('sardor', 1_700_000_000)]);
    expect(metrics).toEqual({ listingsCount: 0, lastActiveAt: null });
  });

  it('picks the most recent event for that coworker, ignoring others', () => {
    const events = [event('sardor', 1_700_000_000), event('kamola', 1_800_000_000), event('sardor', 1_750_000_000)];
    const { lastActiveAt } = deriveCoworkerMetrics('sardor', [], events);
    expect(lastActiveAt?.getTime()).toBe(1_750_000_000 * 1000);
  });

  it('ignores events with an unparseable createdAt rather than throwing', () => {
    const events: CoworkerStatisticEvent[] = [
      { ...event('sardor', 1_700_000_000), createdAt: { seconds: Number.NaN } },
    ];
    const { lastActiveAt } = deriveCoworkerMetrics('sardor', [], events);
    expect(lastActiveAt).toBeNull();
  });
});
