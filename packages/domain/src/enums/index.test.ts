import { describe, expect, it } from 'vitest';
import {
  AD_TYPE,
  AD_TYPE_REV,
  LEAD_STATUS,
  LEAD_STATUS_REV,
  EVENT_STAGE,
  EVENT_STAGE_REV,
  ALL_CHANNELS,
  CONFIRM_EVENTS,
  ACTION_KINDS,
} from './index';

describe('@lacasa/domain/enums subpath entry point', () => {
  it('re-exports the ad enums and their derived reverses', () => {
    expect(AD_TYPE.residential).toBe('RESIDENTIAL');
    expect(AD_TYPE_REV.RESIDENTIAL).toBe('residential');
  });

  it('re-exports the lead enums and their derived reverses', () => {
    expect(LEAD_STATUS.new).toBe('NEW');
    expect(LEAD_STATUS_REV.NEW).toBe('new');
  });

  it('re-exports the event stage enum and its derived reverse', () => {
    expect(EVENT_STAGE.AD_CREATED).toBe(1);
    expect(EVENT_STAGE_REV[1]).toBe('AD_CREATED');
  });

  it('re-exports the unified publish vocabulary', () => {
    expect(ALL_CHANNELS).toContain('INSTAGRAM');
    expect(CONFIRM_EVENTS).toContain('published');
    expect(ACTION_KINDS).toContain('set-value');
  });
});
