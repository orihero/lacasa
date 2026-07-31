import { describe, expect, it } from 'vitest';
import { LEAD_STATUS, LEAD_STATUS_REV } from './leads';

describe('LEAD_STATUS enum', () => {
  it('is invertible in both directions', () => {
    for (const [key, value] of Object.entries(LEAD_STATUS)) {
      expect(LEAD_STATUS_REV[value]).toBe(key);
    }
    expect(Object.keys(LEAD_STATUS_REV)).toHaveLength(
      Object.keys(LEAD_STATUS).length,
    );
  });

  it('covers every Kanban column key', () => {
    expect(Object.keys(LEAD_STATUS)).toEqual([
      'new',
      'could_not_connect',
      'need_to_call_back',
      'rejected',
      'accepted',
    ]);
  });
});
