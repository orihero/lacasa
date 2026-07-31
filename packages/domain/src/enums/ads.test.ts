import { describe, expect, it } from 'vitest';
import {
  AD_TYPE,
  AD_TYPE_REV,
  AD_CATEGORY,
  AD_CATEGORY_REV,
  REPAIRMENT,
  REPAIRMENT_REV,
  FURNITURE,
  FURNITURE_REV,
  AD_STAGE,
  AD_STAGE_REV,
  CURRENCY_CODE,
  CURRENCY_CODE_REV,
} from './ads';

// Each forward map must be invertible: every value maps back to the key it
// came from, and the two maps have the same number of entries (no value
// collisions silently dropping a key).
function expectInvertible<K extends string, V extends PropertyKey>(
  forward: Record<K, V>,
  reverse: Record<V, K>,
) {
  const forwardEntries = Object.entries(forward) as [K, V][];
  expect(Object.keys(reverse)).toHaveLength(forwardEntries.length);
  for (const [key, value] of forwardEntries) {
    expect(reverse[value]).toBe(key);
  }
}

describe('ad enums', () => {
  it('AD_TYPE <-> AD_TYPE_REV is invertible', () => {
    expectInvertible(AD_TYPE, AD_TYPE_REV);
    expect(AD_TYPE_REV.RESIDENTIAL).toBe('residential');
  });

  it('AD_CATEGORY <-> AD_CATEGORY_REV is invertible', () => {
    expectInvertible(AD_CATEGORY, AD_CATEGORY_REV);
    expect(AD_CATEGORY_REV.RENT).toBe('rent');
  });

  it('REPAIRMENT <-> REPAIRMENT_REV is invertible', () => {
    expectInvertible(REPAIRMENT, REPAIRMENT_REV);
    expect(REPAIRMENT_REV.EXCELLENT).toBe('excellent');
  });

  it('FURNITURE <-> FURNITURE_REV is invertible', () => {
    expectInvertible(FURNITURE, FURNITURE_REV);
    expect(FURNITURE_REV.WITH).toBe('withFurniture');
  });

  it('AD_STAGE <-> AD_STAGE_REV is invertible', () => {
    expectInvertible(AD_STAGE, AD_STAGE_REV);
    expect(AD_STAGE_REV.ACTIVE).toBe('1');
    expect(AD_STAGE_REV.SOLD).toBe('2');
    expect(AD_STAGE_REV.DRAFT).toBe('3');
  });

  it('CURRENCY_CODE <-> CURRENCY_CODE_REV is invertible', () => {
    expectInvertible(CURRENCY_CODE, CURRENCY_CODE_REV);
    expect(CURRENCY_CODE_REV.UZS).toBe('uzs');
  });
});
