import { describe, expect, it } from 'vitest';
import { UZ_PHONE_REGEX, isValidUzPhone, phoneValidationRule } from './phone';

describe('isValidUzPhone', () => {
  it('accepts a well-formed Uzbekistan number', () => {
    expect(isValidUzPhone('+998901234567')).toBe(true);
  });

  it.each([
    ['missing country code', '901234567'],
    ['wrong country code', '+7901234567'],
    ['too few digits', '+99890123456'],
    ['too many digits', '+9989012345678'],
    ['non-digit characters', '+998abc123456'],
    ['empty string', ''],
  ])('rejects %s (%s)', (_label, value) => {
    expect(isValidUzPhone(value)).toBe(false);
  });

  it('is backed by the exported regex', () => {
    expect(UZ_PHONE_REGEX.test('+998901234567')).toBe(true);
  });
});

describe('phoneValidationRule', () => {
  it('builds a react-hook-form-shaped rule from caller-supplied messages', () => {
    const rule = phoneValidationRule('Phone number is required', 'Invalid Uzbekistan phone number');
    expect(rule).toEqual({
      required: 'Phone number is required',
      pattern: {
        value: UZ_PHONE_REGEX,
        message: 'Invalid Uzbekistan phone number',
      },
    });
  });

  it('the pattern.value validates the same way isValidUzPhone does', () => {
    const rule = phoneValidationRule('required', 'invalid');
    expect(rule.pattern.value.test('+998901234567')).toBe(isValidUzPhone('+998901234567'));
    expect(rule.pattern.value.test('bad')).toBe(isValidUzPhone('bad'));
  });
});
