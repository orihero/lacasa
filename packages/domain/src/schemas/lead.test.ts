import { describe, expect, it } from 'vitest';
import { leadInputSchema } from './lead';

describe('leadInputSchema', () => {
  it('accepts a full, well-formed lead payload', () => {
    const parsed = leadInputSchema.parse({
      fullName: 'Jane Doe',
      phone: '+998901234567',
      email: 'jane@example.com',
      budget: '50000',
      comment: 'Wants a 2-room flat',
      conversationComment: 'Called back, interested',
      status: 'new',
      source: 'instagram',
      callbackDate: '2024-03-05T10:30:00Z',
      active: true,
    });
    expect(parsed.budget).toBe(50000);
    expect(parsed.status).toBe('new');
    expect(parsed.callbackDate).toBeInstanceOf(Date);
  });

  it('accepts an empty object (every field optional, for PATCH)', () => {
    expect(leadInputSchema.parse({})).toEqual({});
  });

  it('rejects a malformed phone number', () => {
    expect(() => leadInputSchema.parse({ phone: '901234567' })).toThrow();
  });

  it('rejects a status outside LEAD_STATUS keys', () => {
    expect(() => leadInputSchema.parse({ status: 'NEW' })).toThrow();
  });

  it('turns an empty string on a nullable field into null', () => {
    expect(leadInputSchema.parse({ comment: '' }).comment).toBeNull();
    expect(leadInputSchema.parse({ budget: '' }).budget).toBeNull();
    expect(leadInputSchema.parse({ callbackDate: '' }).callbackDate).toBeNull();
  });

  it('rejects a malformed email', () => {
    expect(() => leadInputSchema.parse({ email: 'not-an-email' })).toThrow();
  });
});
