/**
 * Runtime backstop for the exhaustiveness the `Record<SomeKey, X>` types in
 * labels.ts already enforce at compile time — a mismatched key set fails
 * `tsc` before it ever fails a test, but this pins the actual key sets down
 * so a refactor that widens a map's declared type (e.g. to
 * `Partial<Record<...>>`) without meaning to can't quietly reopen the gap.
 */
import { describe, expect, it } from 'vitest';
import { AD_CATEGORY, AD_STAGE, ALL_CHANNELS, FURNITURE, LEAD_STATUS, REPAIRMENT } from '@lacasa/domain';
import {
  AD_CATEGORY_LABEL,
  AD_STAGE_LABEL,
  AD_STAGE_TONE,
  FURNITURE_LABEL,
  LEAD_STATUS_LABEL,
  LEAD_STATUS_ORDER,
  LEAD_STATUS_TONE,
  PUBLISH_CHANNEL_LABEL,
  PUBLISH_STATUS_KEYS,
  PUBLISH_STATUS_LABEL,
  PUBLISH_STATUS_TONE,
  REPAIRMENT_LABEL,
} from '../labels';

function keysOf(obj: object): string[] {
  return Object.keys(obj).sort();
}

describe('label/tone map exhaustiveness', () => {
  it('AD_STAGE_LABEL covers exactly the AD_STAGE keys', () => {
    expect(keysOf(AD_STAGE_LABEL)).toEqual(keysOf(AD_STAGE));
  });

  it('AD_STAGE_TONE covers exactly the AD_STAGE keys', () => {
    expect(keysOf(AD_STAGE_TONE)).toEqual(keysOf(AD_STAGE));
  });

  it('AD_STAGE_TONE follows the contract mapping (1->ok, 2->info, 3->warn)', () => {
    expect(AD_STAGE_TONE).toEqual({ '1': 'ok', '2': 'info', '3': 'warn' });
  });

  it('AD_CATEGORY_LABEL covers exactly the AD_CATEGORY keys', () => {
    expect(keysOf(AD_CATEGORY_LABEL)).toEqual(keysOf(AD_CATEGORY));
  });

  it('REPAIRMENT_LABEL covers exactly the REPAIRMENT keys', () => {
    expect(keysOf(REPAIRMENT_LABEL)).toEqual(keysOf(REPAIRMENT));
  });

  it('FURNITURE_LABEL covers exactly the FURNITURE keys', () => {
    expect(keysOf(FURNITURE_LABEL)).toEqual(keysOf(FURNITURE));
  });

  it('LEAD_STATUS_LABEL covers exactly the LEAD_STATUS keys (no invented SUCCESS)', () => {
    expect(keysOf(LEAD_STATUS_LABEL)).toEqual(keysOf(LEAD_STATUS));
    expect(LEAD_STATUS_LABEL).not.toHaveProperty('success');
  });

  it('LEAD_STATUS_TONE covers exactly the LEAD_STATUS keys', () => {
    expect(keysOf(LEAD_STATUS_TONE)).toEqual(keysOf(LEAD_STATUS));
  });

  it('LEAD_STATUS_ORDER is a permutation of the LEAD_STATUS keys, New first', () => {
    expect([...LEAD_STATUS_ORDER].sort()).toEqual(keysOf(LEAD_STATUS));
    expect(LEAD_STATUS_ORDER[0]).toBe('new');
  });

  it('PUBLISH_CHANNEL_LABEL covers exactly ALL_CHANNELS', () => {
    expect(keysOf(PUBLISH_CHANNEL_LABEL)).toEqual([...ALL_CHANNELS].sort());
  });

  it('PUBLISH_STATUS_LABEL and PUBLISH_STATUS_TONE cover exactly PUBLISH_STATUS_KEYS', () => {
    expect(keysOf(PUBLISH_STATUS_LABEL)).toEqual([...PUBLISH_STATUS_KEYS].sort());
    expect(keysOf(PUBLISH_STATUS_TONE)).toEqual([...PUBLISH_STATUS_KEYS].sort());
  });
});
