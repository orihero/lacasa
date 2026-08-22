import { describe, expect, it } from 'vitest';
import { computePricePerSqm } from './pricePerSqm';

describe('computePricePerSqm', () => {
  it('divides price by area and rounds to a whole unit', () => {
    expect(computePricePerSqm(120000, 80)).toBe(1500);
    expect(computePricePerSqm(100000, 3)).toBe(33333);
  });

  // Both arrive as strings from the uncontrolled number inputs the ad forms use.
  it('accepts numeric strings', () => {
    expect(computePricePerSqm('120000', '80')).toBe(1500);
  });

  // Area is nullable on Ad, so "no area" is the common case, not an error.
  it('returns null when there is no area to divide by', () => {
    expect(computePricePerSqm(120000, null)).toBeNull();
    expect(computePricePerSqm(120000, undefined)).toBeNull();
    expect(computePricePerSqm(120000, '')).toBeNull();
  });

  it('returns null rather than Infinity for a zero or negative area', () => {
    expect(computePricePerSqm(120000, 0)).toBeNull();
    expect(computePricePerSqm(120000, -5)).toBeNull();
  });

  it('returns null for values that are not numbers', () => {
    expect(computePricePerSqm(120000, 'abc')).toBeNull();
    expect(computePricePerSqm('abc', 80)).toBeNull();
  });

  // Free is a real price; 0 per m² is the honest answer, not "unknown".
  it('reports zero for a zero price', () => {
    expect(computePricePerSqm(0, 80)).toBe(0);
  });
});
