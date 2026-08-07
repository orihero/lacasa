import { describe, expect, it } from 'vitest';
import { convertDisplayPrice } from './currency';

describe('convertDisplayPrice', () => {
  it('previews the USD equivalent of a so\'m price, floored', () => {
    expect(convertDisplayPrice(125000, 'uzs', 12500)).toBe('10 $');
    // Floors rather than rounds.
    expect(convertDisplayPrice(129999, 'uzs', 12500)).toBe('10 $');
  });

  it('defaults the rate to 1 when previewing a so\'m price with no rate loaded', () => {
    expect(convertDisplayPrice(50, 'uzs', undefined)).toBe('50 $');
  });

  it('previews the so\'m equivalent of a USD price', () => {
    expect(convertDisplayPrice(10, 'usd', 12500)).toBe('125000 so\'m');
  });

  it('defaults the rate to 0 when previewing a USD price with no rate loaded', () => {
    expect(convertDisplayPrice(10, 'usd', undefined)).toBe('0 so\'m');
  });

  it('coerces a string priceValue the same way an uncontrolled number input would', () => {
    expect(convertDisplayPrice('125000', 'uzs', 12500)).toBe('10 $');
  });
});
