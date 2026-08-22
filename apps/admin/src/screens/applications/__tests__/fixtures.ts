/**
 * Row and page fixtures shared by this folder's two suites, shaped against
 * @lacasa/api-client's AdminApplicationRow / AdminPage rather than against a
 * hand-written local interface — a fixture that has drifted from the contract is
 * a test that passes while the screen is broken.
 *
 * The default row is an AGENCY application because that is the shape with every
 * optional field populated; the solo case (null agency name, null office phone,
 * null team size) is what each test opts into, since "the applicant left this
 * blank" is the branch worth naming explicitly at the call site.
 *
 * `createdAt` (2026-03-14) and `realtor.appliedAt` (2026-08-01) are MONTHS APART
 * on purpose: the Applied column must read the application's timestamp and never
 * the account's signup, and only a fixture where the two differ can prove it.
 */
import type { AdminApplicationRow, AdminPage } from "@lacasa/api-client";

export function makeApplication(
  overrides: Partial<AdminApplicationRow> = {},
): AdminApplicationRow {
  return {
    id: "user-1",
    fullName: "Otabek Yusupov",
    email: "otabek@lacasa.uz",
    phoneNumber: "+998901112233",
    createdAt: "2026-03-14T09:00:00.000Z",
    ...overrides,
    realtor: {
      kind: "agency",
      status: "pending",
      agencyName: "Yusupov Realty",
      officePhone: "+998712001122",
      teamSize: "six_to_fifteen",
      appliedAt: "2026-08-01T14:22:00.000Z",
      decidedAt: null,
      ...overrides.realtor,
    },
  };
}

/** A solo applicant: every optional field genuinely absent, not empty-stringed. */
export function makeSoloApplication(
  overrides: Partial<AdminApplicationRow> = {},
): AdminApplicationRow {
  return makeApplication({
    id: "user-2",
    fullName: "Kamola Rashidova",
    email: "kamola@lacasa.uz",
    ...overrides,
    realtor: {
      kind: "solo",
      status: "pending",
      agencyName: null,
      officePhone: null,
      teamSize: null,
      appliedAt: "2026-08-02T09:05:00.000Z",
      decidedAt: null,
      ...overrides.realtor,
    },
  });
}

/**
 * The row the API really sends for an account with a realtor STATUS but no
 * realtor KIND — two independent nullable columns, and the shape that once took
 * the whole control room blank on a tab that is only being READ. Not
 * hypothetical: `prisma/seed.js` creates agent@lacasa.dev with no kind and
 * `seed-olx.js` then upserts its status to APPROVED, so a seeded database serves
 * exactly this row on the Approved tab.
 *
 * No cast is needed to express this: @lacasa/api-client types
 * `AdminApplicationRow.realtor` as `RealtorProfile | null` in both its source and
 * the `dist` this workspace resolves. It was once narrowed to a non-null
 * `RealtorProfile`, and the narrowing is what turned a rendering decision into an
 * unguarded dereference — so this stays a NAMED builder rather than an inline
 * `realtor: null`: the screen's runtime guard is what actually keeps the tab up,
 * and it needs a case that exercises it whatever the types happen to say today.
 */
export function makeApplicationWithoutProfile(
  overrides: Partial<AdminApplicationRow> = {},
): AdminApplicationRow {
  return { ...makeApplication(overrides), realtor: null };
}

export function makePage(
  items: AdminApplicationRow[],
  nextCursor: string | null = null,
): AdminPage<AdminApplicationRow> {
  return { items, nextCursor };
}
