/**
 * The nav model's pure functions. They are the reason the rail and the topbar
 * cannot disagree about where the admin is: both derive from these, against
 * the same pathname, with no second piece of state anywhere.
 */
import { beforeAll, describe, expect, it } from "vitest";
import i18n from "@/i18n";
import en from "@/locales/en.json";
import ru from "@/locales/ru.json";
import uz from "@/locales/uz.json";
import { NAV_GROUPS, isNavItemActive, railBadgeCount, titleForPath } from "../nav";

const t = (key: string): string => i18n.t(key);

const ALL_ITEMS = NAV_GROUPS.flatMap((group) => group.items);

// The titles asserted below are the English ones; i18next's detector reads the
// environment, so pin it rather than trusting jsdom's navigator.
beforeAll(async () => {
  await i18n.changeLanguage("en");
});

describe("NAV_GROUPS", () => {
  it("lists exactly the four screens that have data behind them", () => {
    expect(ALL_ITEMS.map((item) => item.to)).toEqual([
      "/overview",
      "/applications",
      "/users",
      "/audit",
    ]);
  });

  it("carries no entry for a surface with no schema behind it", () => {
    // Listing moderation, 3D tour review and Plans & premium are proposals
    // with no report/flag, Tour or billing model. A rail row leading to a
    // screen the data cannot fill reads as "moderation exists and is empty",
    // which is a claim about the platform rather than about the UI.
    const paths = ALL_ITEMS.map((item) => item.to);
    expect(paths).not.toContain("/x-mod");
    expect(paths).not.toContain("/tours");
    expect(paths).not.toContain("/plans");
  });

  it("badges only the two counts the overview payload already returns", () => {
    expect(ALL_ITEMS.filter((item) => item.badge).map((item) => item.badge)).toEqual([
      "applications",
      "users",
    ]);
  });

  it("resolves every label and title key in all three locales", () => {
    const keys = [
      ...NAV_GROUPS.map((group) => group.labelKey),
      ...ALL_ITEMS.flatMap((item) => [item.labelKey, item.titleKey]),
      "controlRoom",
    ];

    for (const key of keys) {
      for (const [name, bundle] of [
        ["en", en],
        ["ru", ru],
        ["uz", uz],
      ] as const) {
        expect(
          Object.prototype.hasOwnProperty.call(bundle, key),
          `${key} is missing from ${name}.json`,
        ).toBe(true);
      }
    }
  });
});

describe("isNavItemActive", () => {
  it("matches exactly, so a row lights only on its own route", () => {
    expect(isNavItemActive("/users", { to: "/users" })).toBe(true);
    expect(isNavItemActive("/audit", { to: "/users" })).toBe(false);
  });

  it("does not light a row for a sub-route of it", () => {
    // Deliberately not a prefix match: a future "/users/:id" detail route may
    // well want its own row, and when it lands the case gets added here rather
    // than this being loosened into a startsWith.
    expect(isNavItemActive("/users/9c6e41af", { to: "/users" })).toBe(false);
  });
});

describe("titleForPath", () => {
  it("gives each route the topbar heading the nav model declares", () => {
    expect(titleForPath(t, "/overview")).toBe("Platform overview");
    expect(titleForPath(t, "/applications")).toBe("Realtor applications");
    expect(titleForPath(t, "/users")).toBe("Users");
    expect(titleForPath(t, "/audit")).toBe("Audit log");
  });

  it("falls back to 'Control room' on an unmatched path", () => {
    // Never the last screen's title: a not-found page under a heading that
    // says "Users" is worse than no heading at all.
    expect(titleForPath(t, "/users/9c6e41af")).toBe("Control room");
    expect(titleForPath(t, "/x-mod")).toBe("Control room");
  });
});

describe("railBadgeCount", () => {
  it("renders no badge while the count is still in flight", () => {
    // A stale or defaulted 0 reads as "nothing is waiting on you", which on
    // the applications queue is the exact wrong thing to tell an admin.
    expect(railBadgeCount(3, true)).toBeUndefined();
    expect(railBadgeCount(0, true)).toBeUndefined();
  });

  it("passes a settled count through, including a real zero", () => {
    expect(railBadgeCount(3, false)).toBe(3);
    expect(railBadgeCount(0, false)).toBe(0);
  });

  it("stays undefined when nothing has loaded the overview yet", () => {
    expect(railBadgeCount(undefined, false)).toBeUndefined();
  });
});
