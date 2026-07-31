import { describe, expect, it } from 'vitest';
import {
  registerSchema,
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
