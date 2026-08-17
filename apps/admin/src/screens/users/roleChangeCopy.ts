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
 */
import type { AdminUserRow } from "@lacasa/api-client";
import type { UserRoleKey } from "@lacasa/domain";
import { formatCount } from "@/lib/format";
import { USER_ROLE_LABEL } from "@/lib/labels";

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
 */
function ownedClause(counts: AdminUserRow["counts"] | undefined): string | null {
  const ads = counts?.ads ?? 0;
  const leads = counts?.leads ?? 0;
  if (!ads && !leads) return null;
  return `${formatCount(ads)} ${ads === 1 ? "ad" : "ads"} and ${formatCount(leads)} ${
    leads === 1 ? "lead" : "leads"
  }`;
}

/**
 * The one sentence (occasionally two) ConfirmDialog puts above its buttons.
 * `user.role` is the role the row was loaded with, which is exactly what the
 * admin is deciding against — if it has since changed under them the server's
 * own re-read inside the transaction is what settles it.
 */
export function roleChangeConsequence(user: AdminUserRow, nextRole: UserRoleKey): string {
  const name = user.fullName;

  if (nextRole === user.role) {
    return `${name} already holds the ${USER_ROLE_LABEL[user.role]} role. Choose a different role to make a change.`;
  }

  if (isAdminGrant(user.role, nextRole)) {
    return (
      `Admin is the widest role on the platform. ${name} will be able to change anyone's role — including yours — approve or reject any realtor application, and read every account, ad and lead in the control room. ` +
      `Nothing here can take that back except another role change made from an admin session, and the server refuses even that once they are the only admin left. Grant this only to someone who already has that authority off-screen.`
    );
  }

  if (isAdminRevoke(user.role, nextRole)) {
    return (
      `${name} loses control-room access on their next request: no applications, no users, no audit log. ` +
      `The server refuses this if they are the last admin account, and refuses it outright if ${name} is you.`
    );
  }

  const owned = ownedClause(user.counts);

  if (nextRole === "coworker") {
    return (
      `${name} will act inside their owning agent's data instead of their own — the same leads and listings that agent sees. ` +
      `The server refuses this unless an agent has already invited the account, because a coworker with no agent behind it can reach the Work tab and see nothing.`
    );
  }

  if (nextRole === "agent") {
    return (
      `${name} will be able to post listings and work leads under their own name. ` +
      `Their realtor application is left exactly as it stands — approving an application is the separate action on the Applications screen, and this does not stand in for it.`
    );
  }

  // nextRole === "user": the buyer role, which is the only demotion that can
  // strand data behind it.
  return owned
    ? `${name} loses the Work tab. Nothing is deleted: the ${owned} on this account stay exactly where they are, owned by someone who can no longer manage them.`
    : `${name} loses the Work tab and keeps only the buyer side of the app.`;
}

/**
 * The confirm button's own words. "Change role" everywhere except the admin
 * transitions, where the label names the power being handed over or taken
 * away — the last thing read before the click should not be a verb that fits
 * any of the four options equally.
 */
export function roleChangeConfirmLabel(currentRole: UserRoleKey, nextRole: UserRoleKey): string {
  if (isAdminGrant(currentRole, nextRole)) return "Grant admin access";
  if (isAdminRevoke(currentRole, nextRole)) return "Remove admin access";
  return `Change to ${USER_ROLE_LABEL[nextRole]}`;
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
export function roleChangeErrorMessage(error: unknown): string {
  switch (errorCode(error)) {
    case "self_demotion":
      return "You cannot remove your own admin access. Ask another admin to do it for you.";
    case "last_admin":
      return "This is the only admin account left. Promote someone else to admin first, then come back and demote this one.";
    case "coworker_needs_agent":
      return "A coworker must belong to an agent. Nobody has invited this account to an agency yet, and there is no way to assign one from here — the agent adds them from their own Coworkers screen.";
    case "not_found":
      return "This account no longer exists. Close this and reload the directory.";
    default:
      break;
  }
  if (error instanceof Error && error.message) return error.message;
  return "The role change did not go through.";
}
