import { describe, expect, it } from 'vitest';
import { EVENT_STAGE, EVENT_STAGE_REV } from './events';

describe('EVENT_STAGE enum', () => {
  it('is invertible in both directions', () => {
    for (const [key, value] of Object.entries(EVENT_STAGE)) {
      expect(EVENT_STAGE_REV[value]).toBe(key);
    }
    expect(Object.keys(EVENT_STAGE_REV)).toHaveLength(
      Object.keys(EVENT_STAGE).length,
    );
  });

  it('preserves the legacy Firestore numeric codes', () => {
    expect(EVENT_STAGE.AD_CREATED).toBe(1);
    expect(EVENT_STAGE.LEAD_STATUS_CHANGED).toBe(5);
    expect(EVENT_STAGE_REV[1]).toBe('AD_CREATED');
  });
});
