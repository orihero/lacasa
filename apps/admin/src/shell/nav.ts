/**
 * src/shell/nav — the single source of the control room's navigation model:
 * the 224px rail's groups (mockups/build/web-admin.src.html's `.rail`) and
 * the pure matching logic Rail and Topbar both read from.
 *
 * Rail (which row is lit) and Topbar (which page title to show) derive their
 * state from the SAME `isNavItemActive` / `titleForPath` functions against
 * the SAME `useLocation().pathname` — never a second piece of state — so the
 * two can never disagree about where the admin is.
 *
 * SCOPE: four screens, not the mockup's seven. Listing moderation, 3D tour
 * review and Plans & premium are proposals with no schema behind them (no
 * report/flag model, no Tour model, no plan/billing model anywhere), so they
 * get no nav entry here. A rail row that leads to a screen the data cannot
 * fill is worse than no row: on this surface it reads as "moderation exists
 * and is empty", which is a claim about the platform, not about the UI.
 */
import {
  ListBulletsIcon,
  SquaresFourIcon,
  UserCircleIcon,
  UsersThreeIcon,
  type IconComponent,
} from "@/ui/icons";

export type NavBadge = "applications" | "users";

export interface NavItem {
  to: string;
  label: string;
  /** The topbar's page title for this route — the mockup's `data-title-for`. */
  title: string;
  icon: IconComponent;
  /**
   * Which live count this row shows, if any. `applications` renders "hot"
   * (amber) because a pending application is waiting on the admin looking at
   * the rail; `users` is a plain scale readout and stays neutral.
   */
  badge?: NavBadge;
}

export interface NavGroup {
  label: string;
  items: NavItem[];
}

export const NAV_GROUPS: NavGroup[] = [
  {
    label: "Platform",
    items: [
      {
        to: "/overview",
        label: "Overview",
        title: "Platform overview",
        icon: SquaresFourIcon,
      },
      {
        to: "/applications",
        label: "Applications",
        title: "Realtor applications",
        icon: UserCircleIcon,
        badge: "applications",
      },
      {
        to: "/users",
        label: "Users",
        title: "Users",
        icon: UsersThreeIcon,
        badge: "users",
      },
    ],
  },
  {
    label: "System",
    items: [
      {
        to: "/audit",
        label: "Audit log",
        title: "Audit log",
        icon: ListBulletsIcon,
      },
    ],
  },
];

/** Flattened once, for the lookups below — the grouping is a rail concern. */
const ALL_ITEMS: NavItem[] = NAV_GROUPS.flatMap((group) => group.items);

/**
 * Whether a rail row reads as active for the current pathname. Exact match
 * only: every screen here is a single route with no sub-routes, and a prefix
 * match would light "/users" up for a future "/users/:id" detail route that
 * may well want its own row. When such a route lands, add the case here
 * rather than loosening this into a `startsWith`.
 */
export function isNavItemActive(pathname: string, item: Pick<NavItem, "to">): boolean {
  return pathname === item.to;
}

/**
 * The topbar's page title (the mockup renders all seven as sibling `<h1>`s
 * and shows one). An unmatched path — the 404 route — falls back to "Control
 * room" rather than borrowing the last screen's title, which would leave an
 * admin looking at a not-found page under a heading that says "Users".
 */
export function titleForPath(pathname: string): string {
  return ALL_ITEMS.find((item) => isNavItemActive(pathname, item))?.title ?? "Control room";
}

/**
 * A stale count is worse than no count: showing a cached or default 0 while
 * the real number is still in flight reads as "nothing is waiting on you",
 * which on the applications queue is the exact wrong thing to tell an admin.
 * Rail renders no badge at all — not a spinner, not a "…" — while loading.
 */
export function railBadgeCount(count: number | undefined, isLoading: boolean): number | undefined {
  return isLoading ? undefined : count;
}
