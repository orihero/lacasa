/**
 * Covers zoneForPath and the pure logic behind Rail's active-state and
 * badge-while-loading behaviour (isNavItemActive, railBadgeCount).
 *
 * These are exercised as plain functions rather than through a rendered
 * <Rail>: Rail.tsx also pulls in @/lib/auth, @/data/useAds, @/data/useLeads,
 * @/data/useCoworkers and several @/ui/* primitives, all owned by sibling
 * agents building this app in parallel and not guaranteed to exist yet.
 * Testing the extracted pure logic directly means this suite is exact
 * (no DOM, no query-client scaffolding, no mocking modules that may not be
 * on disk) and doesn't block on their landing.
 */
import { describe, expect, it } from "vitest";
import { NAV_GROUPS, isNavItemActive, railBadgeCount, zoneForPath, type NavItem } from "../nav";

function findItem(to: string): NavItem {
  for (const group of NAV_GROUPS) {
    const item = group.items.find((candidate) => candidate.to === to);
    if (item) return item;
  }
  throw new Error(`fixture bug: no NAV_GROUPS item has to="${to}"`);
}

describe("zoneForPath", () => {
  it.each([
    ["/statistics", "ws"],
    ["/ads", "ws"],
    ["/ads/new", "ws"],
    ["/ads/abc123/edit", "ws"],
    ["/publish", "ws"],
    ["/leads", "pl"],
    ["/leads/kanban", "pl"],
    ["/coworkers", "tm"],
    ["/accounts", "tm"],
  ] as const)("maps %s to zone %s", (pathname, zone) => {
    expect(zoneForPath(pathname)).toBe(zone);
  });

  it("falls back to the Workspace zone for an unmatched path", () => {
    expect(zoneForPath("/this-route-does-not-exist")).toBe("ws");
  });

  it("never disagrees with itself for the two Listing editor routes", () => {
    // The one case the brief calls out explicitly: both routes render the
    // same screen and must resolve to the same zone as every other
    // Workspace item.
    expect(zoneForPath("/ads/new")).toBe(zoneForPath("/ads/999/edit"));
  });
});

describe("isNavItemActive", () => {
  it("is active only on an exact match for an ordinary item", () => {
    const myAds = findItem("/ads");
    expect(isNavItemActive("/ads", myAds)).toBe(true);
    expect(isNavItemActive("/ads/new", myAds)).toBe(false);
    expect(isNavItemActive("/ads/42/edit", myAds)).toBe(false);
    expect(isNavItemActive("/ads/", myAds)).toBe(false);
  });

  it("is active for both /ads/new and /ads/:id/edit on the Listing editor item", () => {
    const listingEditor = findItem("/ads/new");
    expect(isNavItemActive("/ads/new", listingEditor)).toBe(true);
    expect(isNavItemActive("/ads/42/edit", listingEditor)).toBe(true);
    expect(isNavItemActive("/ads/some-uuid-here/edit", listingEditor)).toBe(true);
  });

  it("does not treat an unrelated /ads/* path as the Listing editor", () => {
    const listingEditor = findItem("/ads/new");
    expect(isNavItemActive("/ads", listingEditor)).toBe(false);
    expect(isNavItemActive("/ads/42", listingEditor)).toBe(false);
    // No id segment — must not match on the regex alone.
    expect(isNavItemActive("/ads//edit", listingEditor)).toBe(false);
  });

  it("scopes every other item to its own exact route", () => {
    const kanban = findItem("/leads/kanban");
    expect(isNavItemActive("/leads", kanban)).toBe(false);
    expect(isNavItemActive("/leads/kanban", kanban)).toBe(true);
  });
});

describe("railBadgeCount", () => {
  it("hides the badge while the count is loading, even if a count is already known", () => {
    expect(railBadgeCount(27, true)).toBeUndefined();
    expect(railBadgeCount(undefined, true)).toBeUndefined();
  });

  it("shows the real count once loading is done, including zero", () => {
    expect(railBadgeCount(8, false)).toBe(8);
    expect(railBadgeCount(0, false)).toBe(0);
  });

  it("shows nothing when loading finished but no count arrived", () => {
    expect(railBadgeCount(undefined, false)).toBeUndefined();
  });
});
