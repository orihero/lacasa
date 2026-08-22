/**
 * screens/users/roleChangeCopy — the words the role-change confirmation says,
 * kept out of the dialog component so each branch is a plain function this
 * screen's test can pin down one sentence at a time.
 *
 * This is the only mutation the user directory can perform and it is the one
 * with real blast radius, so every branch below states a CONSEQUENCE in terms
 * of this specific account (its name, its ad and lead counts), never a generic
 * "are you sure?". Two rules the copy follows:
 *
 *  1. Nothing is cascaded by a role change — the server deletes no ads, no
 *     leads and no coworker links (see adminService.setUserRole). Copy that
 *     implied otherwise would scare an admin out of a safe change; copy that
 *     omitted it would let them make a change believing the listings go with
 *     it. The counts are quoted from the row itself, which is why they are
 *     real numbers rather than "any listings they own".
 *  2. Promoting to admin gets the strongest wording on the screen. Every other
 *     transition on this list is undone by making the opposite one; granting
 *     admin hands the recipient the power to make that reversal impossible.
 *
 * Every function takes `t` first, matching every resolver in @/lib/labels: the
 * sentences are user-facing copy and this app ships in en/ru/uz, so the
 * branches choose an i18n KEY rather than an English string.
 */
import type { TFunction } from "i18next";
import type { AdminUserRow } from "@lacasa/api-client";
import type { UserRoleKey } from "@lacasa/domain";
import { formatCount } from "@/lib/format";
import { userRoleLabel } from "@/lib/labels";

export function isAdminGrant(currentRole: UserRoleKey, nextRole: UserRoleKey): boolean {
  return nextRole === "admin" && currentRole !== "admin";
}

export function isAdminRevoke(currentRole: UserRoleKey, nextRole: UserRoleKey): boolean {
  return currentRole === "admin" && nextRole !== "admin";
}

/**
 * "24 ads and 12 leads" — the clause every demotion sentence ends with, so the
 * fact that nothing is deleted is attached to a number the admin can check
 * against the row they clicked. Returns null when the account owns neither,
 * because "0 ads and 0 leads stay put" is noise in a sentence that exists only
 * to reassure someone about data they can see.
 *
 * Singular/plural is per-number and independent (`1 ad and 12 leads`), and the
 * nouns are their own keys rather than i18next plural forms: the numbers are
 * already formatted by `formatCount` ("1,284"), so nothing here can be handed
 * to i18next's `count` selector.
 */
function ownedClause(t: TFunction, counts: AdminUserRow["counts"] | undefined): string | null {
  const ads = counts?.ads ?? 0;
  const leads = counts?.leads ?? 0;
  if (!ads && !leads) return null;
  return t("ownedClause", {
    ads: formatCount(ads),
    adsNoun: ads === 1 ? t("nounAd") : t("nounAds"),
    leads: formatCount(leads),
    leadsNoun: leads === 1 ? t("nounLead") : t("nounLeads"),
  });
}

/**
 * The one sentence (occasionally two) ConfirmDialog puts above its buttons.
 * `user.role` is the role the row was loaded with, which is exactly what the
 * admin is deciding against — if it has since changed under them the server's
 * own re-read inside the transaction is what settles it.
 *
 * The branch order is load-bearing: the no-op check comes first, then the two
 * admin transitions, so `admin -> coworker` is an admin REVOKE rather than a
 * coworker promotion.
 */
export function roleChangeConsequence(
  t: TFunction,
  user: AdminUserRow,
  nextRole: UserRoleKey,
): string {
  const name = user.fullName;

  if (nextRole === user.role) {
    return t("roleConsequenceUnchanged", { name, role: userRoleLabel(t, user.role) });
  }

  if (isAdminGrant(user.role, nextRole)) {
    return t("roleConsequenceAdminGrant", { name });
  }

  if (isAdminRevoke(user.role, nextRole)) {
    return t("roleConsequenceAdminRevoke", { name });
  }

  if (nextRole === "coworker") {
    return t("roleConsequenceCoworker", { name });
  }

  if (nextRole === "agent") {
    return t("roleConsequenceAgent", { name });
  }

  // nextRole === "user": the buyer role, which is the only demotion that can
  // strand data behind it.
  const owned = ownedClause(t, user.counts);
  return owned
    ? t("roleConsequenceBuyerOwned", { name, owned })
    : t("roleConsequenceBuyer", { name });
}

/**
 * The confirm button's own words. "Change to {Role}" everywhere except the
 * admin transitions, where the label names the power being handed over or
 * taken away — the last thing read before the click should not be a verb that
 * fits any of the four options equally.
 */
export function roleChangeConfirmLabel(
  t: TFunction,
  currentRole: UserRoleKey,
  nextRole: UserRoleKey,
): string {
  if (isAdminGrant(currentRole, nextRole)) return t("confirmGrantAdmin");
  if (isAdminRevoke(currentRole, nextRole)) return t("confirmRemoveAdmin");
  return t("confirmChangeToRole", { role: userRoleLabel(t, nextRole) });
}

/**
 * The API's `{ error: { code } }`, read as a plain string.
 *
 * NOT compared against @lacasa/domain's `ErrorCode` union, which does not
 * contain any of the three guard-rail codes below — ERROR_CODES was collected
 * before the admin router existed, so `ApiError.code` is *typed* as that union
 * while carrying, at runtime, whatever the server sent. Narrowing to `string`
 * here is the honest read; comparing against the union type would be a
 * compile error against codes that genuinely arrive.
 */
function errorCode(error: unknown): string | null {
  if (
    typeof error === "object" &&
    error !== null &&
    "code" in error &&
    typeof (error as { code: unknown }).code === "string"
  ) {
    return (error as { code: string }).code;
  }
  return null;
}

/**
 * Each server guard rail becomes its own sentence, in the second person, that
 * says what to do next. A generic "Failed to change role" would leave an admin
 * re-clicking a button the server will refuse every time for a reason it
 * already told us — and two of these three are refusals the admin can resolve
 * themselves (promote a second admin; have an agent invite the account).
 *
 * Anything unrecognised falls through to the API's own message rather than to
 * a house phrase: this is an internal tool, and "connect ECONNREFUSED" is more
 * actionable to the person reading it than "something went wrong".
 */
export function roleChangeErrorMessage(t: TFunction, error: unknown): string {
  switch (errorCode(error)) {
    case "self_demotion":
      return t("errorSelfDemotion");
    case "last_admin":
      return t("errorLastAdmin");
    case "coworker_needs_agent":
      return t("errorCoworkerNeedsAgent");
    case "not_found":
      return t("errorNotFound");
    default:
      break;
  }
  if (error instanceof Error && error.message) return error.message;
  return t("errorRoleChangeFailed");
}
