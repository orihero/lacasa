import { invert } from './invert';

/**
 * What an account is allowed to do. `serializeUser.js` puts the lowercase key
 * on the wire; the value is the Postgres `UserRole` enum in
 * apps/api/prisma/schema.prisma.
 *
 * Two of these carry agent scope and two do not: an `agent` acts on their own
 * id and a `coworker` acts on their agent's, while `user` (a buyer) and
 * `admin` have no agency behind them at all. `admin` is control-room staff —
 * it is a *wider* role than agent, not a superset of it, so it must never be
 * given agent scope; see effectiveAgentId() in apps/api/src/middleware/roles.js.
 */
export const USER_ROLE = {
  user: 'USER',
  agent: 'AGENT',
  coworker: 'COWORKER',
  admin: 'ADMIN',
} as const;

export type UserRoleKey = keyof typeof USER_ROLE;

export const USER_ROLE_REV = invert(USER_ROLE);

// The realtor-type vocabulary introduced with the Buyer/Realtor step on
// `register` (mockups/SCREENS.md §13). Same shape as the other maps here:
// lowercase wire/frontend key -> Postgres enum value in
// apps/api/prisma/schema.prisma.

/** Whether a realtor account is one person or an agency with a team under it. */
export const REALTOR_KIND = {
  solo: 'SOLO',
  agency: 'AGENCY',
} as const;

export type RealtorKindKey = keyof typeof REALTOR_KIND;

export const REALTOR_KIND_REV = invert(REALTOR_KIND);

/**
 * Where a realtor application stands. Buyers carry `none`; signing up as a
 * realtor lands on `pending`, and only `approved` promotes the account to
 * `role: "agent"` — the Work tab is gated on the role, not on this.
 */
export const REALTOR_STATUS = {
  none: 'NONE',
  pending: 'PENDING',
  approved: 'APPROVED',
  rejected: 'REJECTED',
} as const;

export type RealtorStatusKey = keyof typeof REALTOR_STATUS;

export const REALTOR_STATUS_REV = invert(REALTOR_STATUS);

/**
 * Self-reported head count on an agency application. Buckets rather than a
 * number: it steers onboarding, and nobody has an exact count on signup day.
 */
export const TEAM_SIZE = {
  just_me: 'JUST_ME',
  two_to_five: 'TWO_TO_FIVE',
  six_to_fifteen: 'SIX_TO_FIFTEEN',
  sixteen_plus: 'SIXTEEN_PLUS',
} as const;

export type TeamSizeKey = keyof typeof TEAM_SIZE;

export const TEAM_SIZE_REV = invert(TEAM_SIZE);
