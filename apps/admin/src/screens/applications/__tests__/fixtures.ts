/**
 * Row and page fixtures shared by this folder's two suites, shaped against
 * @lacasa/api-client's AdminApplicationRow / AdminPage rather than against a
 * hand-written local interface — a fixture that has drifted from the contract
 * is a test that passes while the screen is broken.
 *
 * The default row is an AGENCY application because that is the shape with
 * every optional field populated; the solo case (null agency name, null office
 * phone, null team size) is what each test opts into, since "the applicant
 * left this blank" is the branch worth naming explicitly at the call site.
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

export function makePage(
  items: AdminApplicationRow[],
  nextCursor: string | null = null,
): AdminPage<AdminApplicationRow> {
  return { items, nextCursor };
}
