import { describe, expect, it } from 'vitest';
import {
  registerSchema,
  realtorApplicationSchema,
  loginSchema,
  userUpdateSchema,
  coworkerCreateSchema,
  coworkerUpdateSchema,
} from './user';

describe('registerSchema', () => {
  it('accepts a well-formed registration', () => {
    expect(
      registerSchema.parse({ fullName: 'Jane Doe', email: 'jane@example.com', password: 'secret1' }),
    ).toMatchObject({ fullName: 'Jane Doe', email: 'jane@example.com' });
  });

  it('rejects a short password', () => {
    expect(() =>
      registerSchema.parse({ fullName: 'Jane', email: 'jane@example.com', password: '123' }),
    ).toThrow();
  });

  it('rejects a malformed email', () => {
    expect(() =>
      registerSchema.parse({ fullName: 'Jane', email: 'not-an-email', password: 'secret1' }),
    ).toThrow();
  });

  const buyer = { fullName: 'Jane Doe', email: 'jane@example.com', password: 'secret1' };

  it('treats a registration with no realtor block as a buyer', () => {
    expect(registerSchema.parse(buyer).realtor).toBeUndefined();
  });

  it('accepts a solo realtor with nothing beyond the choice', () => {
    expect(registerSchema.parse({ ...buyer, realtor: { kind: 'solo' } })).toMatchObject({
      realtor: { kind: 'solo' },
    });
  });

  it('accepts an agency with its name and team size', () => {
    expect(
      registerSchema.parse({
        ...buyer,
        realtor: { kind: 'agency', agencyName: 'La Casa Realty', teamSize: 'two_to_five' },
      }),
    ).toMatchObject({ realtor: { agencyName: 'La Casa Realty', teamSize: 'two_to_five' } });
  });

  it('drops agency-only fields from a solo application', () => {
    const parsed = registerSchema.parse({
      ...buyer,
      realtor: { kind: 'solo', agencyName: 'Sneaky Realty', teamSize: 'sixteen_plus' },
    });
    expect(parsed.realtor).toEqual({ kind: 'solo' });
  });
});

describe('realtorApplicationSchema', () => {
  it('requires an agency name and team size when kind is agency', () => {
    expect(() => realtorApplicationSchema.parse({ kind: 'agency' })).toThrow();
    expect(() =>
      realtorApplicationSchema.parse({ kind: 'agency', agencyName: 'La Casa Realty' }),
    ).toThrow();
    expect(() =>
      realtorApplicationSchema.parse({ kind: 'agency', agencyName: '', teamSize: 'just_me' }),
    ).toThrow();
  });

  it('rejects an unknown team-size bucket', () => {
    expect(() =>
      realtorApplicationSchema.parse({
        kind: 'agency',
        agencyName: 'La Casa Realty',
        teamSize: '2-5',
      }),
    ).toThrow();
  });

  it('accepts an office phone only in +998 form', () => {
    const agency = { kind: 'agency', agencyName: 'La Casa Realty', teamSize: 'just_me' };
    expect(
      realtorApplicationSchema.parse({ ...agency, officePhone: '+998712001020' }),
    ).toMatchObject({ officePhone: '+998712001020' });
    expect(() => realtorApplicationSchema.parse({ ...agency, officePhone: '712001020' })).toThrow();
  });

  it('rejects an unknown kind', () => {
    expect(() => realtorApplicationSchema.parse({ kind: 'broker' })).toThrow();
  });
});

describe('loginSchema', () => {
  it('accepts email + any non-empty password', () => {
    expect(loginSchema.parse({ email: 'jane@example.com', password: 'x' })).toEqual({
      email: 'jane@example.com',
      password: 'x',
    });
  });

  it('rejects an empty password', () => {
    expect(() => loginSchema.parse({ email: 'jane@example.com', password: '' })).toThrow();
  });
});

describe('userUpdateSchema', () => {
  it('accepts an empty object (every field optional)', () => {
    expect(userUpdateSchema.parse({})).toEqual({});
  });

  it('accepts a partial update', () => {
    expect(userUpdateSchema.parse({ fullName: 'New Name' })).toEqual({ fullName: 'New Name' });
  });

  it('rejects a short password when provided', () => {
    expect(() => userUpdateSchema.parse({ password: '123' })).toThrow();
  });
});

describe('coworkerCreateSchema', () => {
  it('requires fullName, email, and password', () => {
    expect(() => coworkerCreateSchema.parse({})).toThrow();
    expect(
      coworkerCreateSchema.parse({ fullName: 'Co', email: 'co@example.com', password: 'secret1' }),
    ).toMatchObject({ fullName: 'Co' });
  });
});

describe('coworkerUpdateSchema', () => {
  it('accepts an empty object (every field optional)', () => {
    expect(coworkerUpdateSchema.parse({})).toEqual({});
  });
});
