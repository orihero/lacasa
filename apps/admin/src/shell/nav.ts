/**
 * src/shell/nav — the single source of the control room's navigation model,
 * and the pure matching logic the rail and the topbar both read from.
 *
 * The rail (which row is lit) and the topbar (which page title shows) derive
 * their state from the SAME `isNavItemActive` / `titleForPath` against the
 * SAME `useLocation().pathname` — never a second piece of state — so the two
 * can never disagree about where the admin is. That is also why active state
 * is computed by hand here rather than delegated to react-router's <NavLink>.
 *
 * SCOPE: four screens, not the original mockup's seven. Listing moderation,
 * 3D tour review and Plans & premium are proposals with no schema behind them
 * (no report/flag model, no Tour model, no plan/billing model anywhere), so
 * they get no nav entry and no route. A rail row that leads to a screen the
 * data cannot fill is worse than no row: on this surface it reads as
 * "moderation exists and is empty", which is a claim about the platform
 * rather than about the UI.
 *
 * COPY LIVES IN THE LOCALE FILES, NOT HERE. Each item carries i18n keys
 * (`labelKey`, `titleKey`) rather than English, and the resolver below takes
 * `t` as its first argument — the same shape every resolver in @/lib/labels
 * already has. That keeps these functions pure and testable with a stub `t`.
 */
import type { Translate } from "@/lib/labels";
import { CircleUser, LayoutGrid, List, Users, type IconComponent } from "@/ui/icons";

export type NavBadge = "applications" | "users";

export interface NavItem {
  to: string;
  /** i18n key for the rail row's label. */
  labelKey: string;
  /** i18n key for the topbar's page title on this route. */
  titleKey: string;
  icon: IconComponent;
  /**
   * Which live count this row shows, if any. `applications` renders "hot"
   * because a pending application is waiting on the admin looking at the
   * rail; `users` is a plain scale readout and stays neutral.
   */
  badge?: NavBadge;
}

export interface NavGroup {
  /** i18n key for the group heading. */
  labelKey: string;
  items: NavItem[];
}

export const NAV_GROUPS: NavGroup[] = [
  {
    labelKey: "navPlatform",
    items: [
      {
        to: "/overview",
        labelKey: "navOverview",
        titleKey: "titlePlatformOverview",
        icon: LayoutGrid,
      },
      {
        to: "/applications",
        labelKey: "navApplications",
        titleKey: "titleRealtorApplications",
        icon: CircleUser,
        badge: "applications",
      },
      {
        to: "/users",
        labelKey: "navUsers",
        titleKey: "titleUsers",
        icon: Users,
        badge: "users",
      },
    ],
  },
  {
    labelKey: "navSystem",
    items: [
      {
        to: "/audit",
        labelKey: "navAuditLog",
        titleKey: "titleAuditLog",
        icon: List,
      },
    ],
  },
];

/** Flattened once for the lookups below — the grouping is a rail concern. */
const ALL_ITEMS: NavItem[] = NAV_GROUPS.flatMap((group) => group.items);

/**
 * Whether a rail row reads as active for the current pathname.
 *
 * EXACT MATCH, deliberately not a prefix match. Every screen here is a single
 * route with no sub-routes, and a prefix match would light "/users" up for a
 * future "/users/:id" detail route that may well want its own row. When such
 * a route lands, add the case here rather than loosening this into a
 * `startsWith`.
 */
export function isNavItemActive(pathname: string, item: Pick<NavItem, "to">): boolean {
  return pathname === item.to;
}

/**
 * The topbar's page title. An unmatched path — the 404 route — falls back to
 * "Control room" rather than borrowing the last screen's title, which would
 * leave an admin looking at a not-found page under a heading that says
 * "Users".
 */
export function titleForPath(t: Translate, pathname: string): string {
  const item = ALL_ITEMS.find((candidate) => isNavItemActive(pathname, candidate));
  return t(item?.titleKey ?? "controlRoom");
}

/**
 * A STALE COUNT IS WORSE THAN NO COUNT. Showing a cached or default 0 while
 * the real number is still in flight reads as "nothing is waiting on you",
 * which on the applications queue is the exact wrong thing to tell an admin.
 * While loading the rail renders no badge at all — not a spinner, not an
 * ellipsis — and an undefined count renders as no badge, never as 0.
 */
export function railBadgeCount(
  count: number | undefined,
  isLoading: boolean,
): number | undefined {
  return isLoading ? undefined : count;
}
