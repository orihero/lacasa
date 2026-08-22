import { describe, expect, it } from 'vitest';
import { contactSchema } from './contact';

describe('contactSchema', () => {
  it('accepts a well-formed contact request', () => {
    expect(
      contactSchema.parse({ name: 'Aziz', phone: '+998901234567', message: 'Call me back' }),
    ).toEqual({ name: 'Aziz', phone: '+998901234567', message: 'Call me back' });
  });

  it('defaults message to an empty string when omitted', () => {
    expect(contactSchema.parse({ name: 'Aziz', phone: '+998901234567' }).message).toBe('');
  });

  it('rejects an empty name', () => {
    expect(() => contactSchema.parse({ name: '', phone: '+998901234567' })).toThrow();
  });

  it('rejects a phone number outside the +998XXXXXXXXX shape', () => {
    expect(() => contactSchema.parse({ name: 'Aziz', phone: '901234567' })).toThrow();
    expect(() => contactSchema.parse({ name: 'Aziz', phone: '+1234567890' })).toThrow();
  });

  it('rejects a message over the 500-char bound', () => {
    expect(() =>
      contactSchema.parse({ name: 'Aziz', phone: '+998901234567', message: 'x'.repeat(501) }),
    ).toThrow();
  });
});
