import { describe, expect, it } from 'vitest';
import { toValidDate, formatCreatedAt, formatCallbackDate } from './date';

describe('toValidDate', () => {
  it('accepts a Date instance', () => {
    const d = new Date('2024-03-05T10:30:00Z');
    expect(toValidDate(d)).toEqual(d);
  });

  it('accepts an ISO string', () => {
    expect(toValidDate('2024-03-05T10:30:00Z')?.toISOString()).toBe('2024-03-05T10:30:00.000Z');
  });

  it('accepts a stale Firestore-era {seconds} shape', () => {
    expect(toValidDate({ seconds: 1709634600 })?.getTime()).toBe(1709634600 * 1000);
  });

  it('accepts a raw unix-ms number', () => {
    expect(toValidDate(1709634600000)?.getTime()).toBe(1709634600000);
  });

  it('returns null for null/undefined', () => {
    expect(toValidDate(null)).toBeNull();
    expect(toValidDate(undefined)).toBeNull();
  });

  // Regression: none of these should ever produce a Date whose
  // getTime() is NaN making it through to a formatter.
  it('returns null instead of an Invalid Date for garbage input', () => {
    expect(toValidDate('not a date')).toBeNull();
    expect(toValidDate(new Date('not a date'))).toBeNull();
    expect(toValidDate({ seconds: NaN })).toBeNull();
    expect(toValidDate('')).toBeNull();
  });
});

describe('formatCreatedAt', () => {
  it('formats a {seconds} shape as "DD.MM.YYYY | HH:MM"', () => {
    // 2024-03-05T10:30:00Z
    const formatted = formatCreatedAt({ seconds: 1709634600 }, 'en-GB');
    // Exact inter-token whitespace varies by ICU version (some emit a
    // narrow no-break space around the time) — assert the token shape and
    // ordering, not byte-for-byte spacing.
    expect(formatted).toMatch(/^\d{2}\.\d{2}\.\d{4}\s\|\s+\d{2}:\d{2}$/);
  });

  it('never returns the literal string "Invalid Date"', () => {
    expect(formatCreatedAt('garbage')).not.toContain('Invalid Date');
    expect(formatCreatedAt('garbage')).toBe('');
    expect(formatCreatedAt(null)).toBe('');
    expect(formatCreatedAt(undefined)).toBe('');
  });
});

describe('formatCallbackDate', () => {
  it('formats a Date as a localized string', () => {
    const formatted = formatCallbackDate(new Date('2024-03-05T10:30:00Z'), 'en-GB');
    expect(formatted).toMatch(/\d{4}/);
  });

  it('never returns the literal string "Invalid Date"', () => {
    expect(formatCallbackDate('garbage')).not.toContain('Invalid Date');
    expect(formatCallbackDate('garbage')).toBe('');
    expect(formatCallbackDate(null)).toBe('');
  });
});
