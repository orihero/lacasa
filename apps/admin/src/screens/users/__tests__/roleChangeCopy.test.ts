/**
 * roleChangeCopy — every from→to pair, one sentence at a time.
 *
 * The screen suite drives the four transitions an admin is most likely to
 * make; this one exists because the branches are the product decision. Which
 * sentence a pair gets, in which ORDER the branches are evaluated (an
 * `admin → coworker` is an admin REVOKE, not a coworker promotion), and
 * whether the demotion clause quotes the row's real counts are the things that
 * would go quietly wrong in a refactor and be read by an admin as fact.
 */
import { beforeAll, describe, expect, it } from "vitest";
import type { TFunction } from "i18next";
import type { AdminUserRow } from "@lacasa/api-client";
import type { UserRoleKey } from "@lacasa/domain";
import i18n from "@/i18n";
import {
  isAdminGrant,
  isAdminRevoke,
  roleChangeConfirmLabel,
  roleChangeConsequence,
  roleChangeErrorMessage,
} from "../roleChangeCopy";

let t: TFunction;

function user(
  role: UserRoleKey,
  counts: { ads: number; leads: number } = { ads: 0, leads: 0 },
): AdminUserRow {
  return {
    id: "a3f21e08-1c44-4b0e-9f21-3d6b0e5a71c2",
    fullName: "Javlon Rustamov",
    email: "javlon@lacasa.uz",
    phoneNumber: null,
    role,
    avatar: null,
    agentId: null,
    realtor: null,
    createdAt: "2026-03-14T09:00:00.000Z",
    counts,
  };
}

beforeAll(async () => {
  await i18n.changeLanguage("en");
  t = i18n.getFixedT("en");
});

describe("isAdminGrant / isAdminRevoke", () => {
  it("treats admin→admin as neither", () => {
    expect(isAdminGrant("admin", "admin")).toBe(false);
    expect(isAdminRevoke("admin", "admin")).toBe(false);
  });

  it("classifies the two admin transitions", () => {
    expect(isAdminGrant("user", "admin")).toBe(true);
    expect(isAdminGrant("coworker", "admin")).toBe(true);
    expect(isAdminRevoke("admin", "coworker")).toBe(true);
    expect(isAdminRevoke("admin", "user")).toBe(true);
  });
});

describe("roleChangeConsequence", () => {
  it("names the role the account already holds on a no-op", () => {
    expect(roleChangeConsequence(t, user("agent"), "agent")).toBe(
      "Javlon Rustamov already holds the Agent role. Choose a different role to make a change.",
    );
  });

  it("gives an admin grant the strongest wording on the screen", () => {
    const text = roleChangeConsequence(t, user("user"), "admin");
    expect(text).toMatch(/^Admin is the widest role on the platform\./);
    expect(text).toMatch(/change anyone's role — including yours —/);
    expect(text).toMatch(/the server refuses even that once they are the only admin left/);
  });

  it("states what an admin loses, twice naming who cannot do it to themselves", () => {
    const text = roleChangeConsequence(t, user("admin"), "user");
    expect(text).toBe(
      "Javlon Rustamov loses control-room access on their next request: no applications, no users, no audit log. " +
        "The server refuses this if they are the last admin account, and refuses it outright if Javlon Rustamov is you.",
    );
  });

  it("reads admin→coworker as a revoke, not as a coworker promotion", () => {
    // Branch order is load-bearing: the admin checks come before the
    // per-target-role ones.
    expect(roleChangeConsequence(t, user("admin"), "coworker")).toMatch(
      /loses control-room access/,
    );
  });

  it("warns that a coworker needs an inviting agent", () => {
    expect(roleChangeConsequence(t, user("user"), "coworker")).toBe(
      "Javlon Rustamov will act inside their owning agent's data instead of their own — the same leads and listings that agent sees. " +
        "The server refuses this unless an agent has already invited the account, because a coworker with no agent behind it can reach the Work tab and see nothing.",
    );
  });

  it("keeps the realtor application out of a promotion to agent", () => {
    expect(roleChangeConsequence(t, user("user"), "agent")).toMatch(
      /Their realtor application is left exactly as it stands/,
    );
  });

  it("quotes the row's own counts when a demotion strands data", () => {
    expect(roleChangeConsequence(t, user("agent", { ads: 24, leads: 12 }), "user")).toBe(
      "Javlon Rustamov loses the Work tab. Nothing is deleted: the 24 ads and 12 leads on this account " +
        "stay exactly where they are, owned by someone who can no longer manage them.",
    );
  });

  it("pluralises each number independently and groups large ones", () => {
    expect(roleChangeConsequence(t, user("agent", { ads: 1, leads: 12 }), "user")).toMatch(
      /the 1 ad and 12 leads on this account/,
    );
    expect(roleChangeConsequence(t, user("agent", { ads: 24, leads: 1 }), "user")).toMatch(
      /the 24 ads and 1 lead on this account/,
    );
    expect(roleChangeConsequence(t, user("agent", { ads: 24, leads: 0 }), "user")).toMatch(
      /the 24 ads and 0 leads on this account/,
    );
    expect(roleChangeConsequence(t, user("agent", { ads: 1284, leads: 3 }), "user")).toMatch(
      /the 1,284 ads and 3 leads on this account/,
    );
  });

  it("drops the clause entirely when the account owns nothing", () => {
    // "0 ads and 0 leads stay put" is noise in a sentence that exists only to
    // reassure someone about data they can see.
    expect(roleChangeConsequence(t, user("agent", { ads: 0, leads: 0 }), "user")).toBe(
      "Javlon Rustamov loses the Work tab and keeps only the buyer side of the app.",
    );
  });
});

describe("roleChangeConfirmLabel", () => {
  it("names the power on the two admin transitions and the role on the rest", () => {
    expect(roleChangeConfirmLabel(t, "user", "admin")).toBe("Grant admin access");
    expect(roleChangeConfirmLabel(t, "admin", "user")).toBe("Remove admin access");
    expect(roleChangeConfirmLabel(t, "agent", "user")).toBe("Change to Buyer");
    expect(roleChangeConfirmLabel(t, "user", "agent")).toBe("Change to Agent");
    expect(roleChangeConfirmLabel(t, "user", "coworker")).toBe("Change to Coworker");
    // Only reachable as the no-op case, since any other current role would be
    // a grant.
    expect(roleChangeConfirmLabel(t, "admin", "admin")).toBe("Change to Admin");
  });
});

describe("roleChangeErrorMessage", () => {
  it("turns each guard rail into a second-person sentence that says what to do", () => {
    expect(roleChangeErrorMessage(t, { code: "self_demotion" })).toMatch(
      /Ask another admin to do it for you\./,
    );
    expect(roleChangeErrorMessage(t, { code: "last_admin" })).toMatch(
      /Promote someone else to admin first/,
    );
    expect(roleChangeErrorMessage(t, { code: "coworker_needs_agent" })).toMatch(
      /the agent adds them from their own Coworkers screen\./,
    );
    expect(roleChangeErrorMessage(t, { code: "not_found" })).toMatch(
      /Close this and reload the directory\./,
    );
  });

  it("falls through to the API's own message rather than a house phrase", () => {
    // This is an internal tool: "connect ECONNREFUSED" is more actionable to
    // the person reading it than "something went wrong".
    expect(roleChangeErrorMessage(t, new Error("connect ECONNREFUSED"))).toBe(
      "connect ECONNREFUSED",
    );
  });

  it("has a last resort when the thrown value carries nothing readable", () => {
    expect(roleChangeErrorMessage(t, {})).toBe("The role change did not go through.");
    expect(roleChangeErrorMessage(t, new Error(""))).toBe("The role change did not go through.");
  });
});
