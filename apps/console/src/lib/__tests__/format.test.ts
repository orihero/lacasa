import { describe, expect, it } from 'vitest';
import { formatAdPrice, formatDateTime, formatMoney, formatRelativeTime, initials } from '../format';

describe('formatMoney', () => {
  it('formats USD with thousands separators and no decimals', () => {
    expect(formatMoney(1200)).toBe('$1,200');
  });

  it('formats a different currency when given one', () => {
    expect(formatMoney(1200, 'UZS')).toMatch(/1,200/);
  });

  it('renders an em dash instead of a fabricated $0 for missing amounts', () => {
    expect(formatMoney(null)).toBe('—');
    expect(formatMoney(undefined)).toBe('—');
    expect(formatMoney(Number.NaN)).toBe('—');
  });
});

describe('formatAdPrice', () => {
  it('appends "/month" for rent, spelled out — never the old "/mo"', () => {
    expect(formatAdPrice({ price: 1000, priceType: 'usd', category: 'rent' })).toBe('$1,000/month');
  });

  it('renders a bare price for sale, no suffix', () => {
    expect(formatAdPrice({ price: 78000, priceType: 'usd', category: 'sale' })).toBe('$78,000');
  });

  it('uses UZS when priceType is uzs', () => {
    expect(formatAdPrice({ price: 500000, priceType: 'uzs', category: 'sale' })).toMatch(/500,000/);
  });

  it('renders an em dash rather than a fabricated price when price is unusable', () => {
    expect(formatAdPrice({ price: null, priceType: 'usd', category: 'sale' })).toBe('—');
    expect(formatAdPrice({ price: undefined, priceType: 'usd', category: 'sale' })).toBe('—');
    expect(formatAdPrice({ price: 'not-a-number', priceType: 'usd', category: 'sale' })).toBe('—');
  });
});

describe('formatRelativeTime', () => {
  const now = new Date('2026-08-05T12:00:00Z');

  it('buckets under a minute as "just now"', () => {
    expect(formatRelativeTime(new Date('2026-08-05T11:59:45Z'), now)).toBe('just now');
  });

  it('buckets minutes as "N min ago"', () => {
    expect(formatRelativeTime(new Date('2026-08-05T11:58:00Z'), now)).toBe('2 min ago');
  });

  it('buckets hours as "N h ago"', () => {
    expect(formatRelativeTime(new Date('2026-08-05T09:00:00Z'), now)).toBe('3 h ago');
  });

  it('buckets 24-48h as "Yesterday"', () => {
    expect(formatRelativeTime(new Date('2026-08-04T06:00:00Z'), now)).toBe('Yesterday');
  });

  it('buckets 48h+ as "N days ago"', () => {
    expect(formatRelativeTime(new Date('2026-08-03T12:00:00Z'), now)).toBe('2 days ago');
  });

  it('collapses a future/skewed timestamp to "just now" rather than a negative duration', () => {
    expect(formatRelativeTime(new Date('2026-08-05T12:05:00Z'), now)).toBe('just now');
  });

  it('returns an empty string for input that does not parse', () => {
    expect(formatRelativeTime('garbage', now)).toBe('');
    expect(formatRelativeTime(null, now)).toBe('');
  });
});

describe('formatDateTime', () => {
  it('matches the prototype\'s "DD.MM.YYYY | HH:MM" token shape', () => {
    expect(formatDateTime({ seconds: 1709634600 })).toMatch(/^\d{2}\.\d{2}\.\d{4}\s\|\s+\d{2}:\d{2}$/);
  });

  it('returns an empty string instead of "Invalid Date"', () => {
    expect(formatDateTime('garbage')).toBe('');
    expect(formatDateTime(null)).toBe('');
  });
});

describe('initials', () => {
  it('takes the first letter of the first two words', () => {
    expect(initials('Sardor Abdullayev')).toBe('SA');
  });

  it('handles a single name by taking its first two letters', () => {
    expect(initials('Cher')).toBe('CH');
  });

  it('collapses extra internal and surrounding whitespace', () => {
    expect(initials('  Dilnoza    Yusupova  ')).toBe('DY');
  });

  it('uses only the first two words when given three or more', () => {
    expect(initials('Javlon Odil Rustamov')).toBe('JO');
  });

  it('returns an empty string for empty input', () => {
    expect(initials('')).toBe('');
    expect(initials('   ')).toBe('');
  });

  it('handles non-Latin scripts by code point, not UTF-16 code unit', () => {
    expect(initials('Алишер Навои')).toBe('АН');
    expect(initials('Élodie')).toBe('ÉL');
  });
});
