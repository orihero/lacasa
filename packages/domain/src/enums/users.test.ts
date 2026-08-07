import { describe, expect, it } from 'vitest';
import {
  REALTOR_KIND,
  REALTOR_KIND_REV,
  REALTOR_STATUS,
  REALTOR_STATUS_REV,
  TEAM_SIZE,
  TEAM_SIZE_REV,
} from './users';

describe.each([
  ['REALTOR_KIND', REALTOR_KIND, REALTOR_KIND_REV],
  ['REALTOR_STATUS', REALTOR_STATUS, REALTOR_STATUS_REV],
  ['TEAM_SIZE', TEAM_SIZE, TEAM_SIZE_REV],
] as const)('%s enum', (_name, map, rev) => {
  it('is invertible in both directions', () => {
    for (const [key, value] of Object.entries(map)) {
      expect((rev as Record<string, string>)[value]).toBe(key);
    }
    expect(Object.keys(rev)).toHaveLength(Object.keys(map).length);
  });

  it('uses SCREAMING_SNAKE values, matching the Postgres enums', () => {
    for (const value of Object.values(map)) {
      expect(value).toMatch(/^[A-Z][A-Z_]*$/);
    }
  });
});

describe('REALTOR_STATUS', () => {
  it('starts at none so a buyer account carries no application', () => {
    expect(Object.keys(REALTOR_STATUS)[0]).toBe('none');
  });
});

describe('TEAM_SIZE', () => {
  it('is ordered smallest bucket first, as the register form renders it', () => {
    expect(Object.keys(TEAM_SIZE)).toEqual([
      'just_me',
      'two_to_five',
      'six_to_fifteen',
      'sixteen_plus',
    ]);
  });
});
