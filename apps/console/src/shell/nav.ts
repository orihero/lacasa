/**
 * src/shell/nav — the single source of the console's navigation model: the
 * 236px labeled rail's three groups (mockups/f/PLAN.md §2) and the pure
 * matching logic Topbar's zone pills and Rail's item rows both read from.
 *
 * Topbar and Rail derive their "what's active right now" state from the
 * SAME `zoneForPath` / `isNavItemActive` functions against the SAME
 * `useLocation().pathname` — never a second piece of state — so the two can
 * never disagree with each other about which zone or which row is current.
 */
import {
  BroadcastIcon,
  BuildingsIcon,
  KanbanIcon,
  LinkSimpleIcon,
  NotePencilIcon,
  SquaresFourIcon,
  UserIcon,
  UsersThreeIcon,
  type IconComponent,
} from "@/ui/icons";

export type Zone = "ws" | "pl" | "tm";

export interface NavItem {
  to: string;
  label: string;
  icon: IconComponent;
  badge?: "ads" | "leads" | "coworkers";
}

export interface NavGroup {
  zone: Zone;
  label: string;
  items: NavItem[];
}

export const NAV_GROUPS: NavGroup[] = [
  {
    zone: "ws",
    label: "Workspace",
    items: [
      { to: "/statistics", label: "Statistics", icon: SquaresFourIcon },
      { to: "/ads", label: "My ads", icon: BuildingsIcon, badge: "ads" },
      { to: "/ads/new", label: "Listing editor", icon: NotePencilIcon },
      { to: "/publish", label: "Publish status", icon: BroadcastIcon },
    ],
  },
  {
    zone: "pl",
    label: "Pipeline",
    items: [
      // mockups/f/PLAN.md §4: the prototype's badge (27, a live aggregate)
      // intentionally differs from its 6-row illustrative seed table. Here
      // there is no separate seed — the badge is just useLeads().length, the
      // same query the Leads screen renders rows from — so the two will
      // always agree in this app. That agreement is correct, not a
      // regression of the prototype's intentional mismatch; do not "fix" it
      // back apart.
      { to: "/leads", label: "Leads", icon: UsersThreeIcon, badge: "leads" },
      { to: "/leads/kanban", label: "Kanban", icon: KanbanIcon },
    ],
  },
  {
    zone: "tm",
    label: "Team",
    items: [
      { to: "/coworkers", label: "Coworkers", icon: UserIcon, badge: "coworkers" },
      { to: "/accounts", label: "Connected accounts", icon: LinkSimpleIcon },
    ],
  },
];

/**
 * The topbar's 3-pill zone indicator uses its own fixed glyph per zone
 * (mockups/f/f-console.src.html lines 13-17: Workspace=squares-four-fill,
 * Pipeline=kanban-fill, Team=users-three-fill) — NOT simply
 * `group.items[0].icon` (Team's first item, Coworkers, uses a plain
 * `user-fill`, not `users-three-fill`). Kept as its own map rather than a
 * field on NavGroup so the FOUNDATION CONTRACT's NavGroup shape stays
 * exactly `{ zone; label; items }`.
 */
export const ZONE_ICON: Record<Zone, IconComponent> = {
  ws: SquaresFourIcon,
  pl: KanbanIcon,
  tm: UsersThreeIcon,
};

const LISTING_EDITOR_PATH = "/ads/new";
const LISTING_EDITOR_EDIT_RE = /^\/ads\/[^/]+\/edit$/;

/**
 * Whether a rail/topbar item reads as active for the current pathname.
 * Every item is an exact match EXCEPT Listing editor, which also owns
 * `/ads/:id/edit` — both routes render ListingEditorScreen (routes.tsx) and
 * the rail row has to light up for either. A naive `pathname.startsWith(to)`
 * prefix match would fix that case but break another: "/ads/new" would then
 * also light up My ads' `/ads` row. So everything else stays exact.
 */
export function isNavItemActive(pathname: string, item: Pick<NavItem, "to">): boolean {
  if (item.to === LISTING_EDITOR_PATH) {
    return pathname === LISTING_EDITOR_PATH || LISTING_EDITOR_EDIT_RE.test(pathname);
  }
  return pathname === item.to;
}

/**
 * Derives the active zone (topbar pill + rail group) from the current
 * location. Unmatched paths (a stray 404) fall back to "ws" — a page still
 * has to render inside SOME zone's visual context, and Workspace is the
 * app's default landing zone (routes.tsx redirects "/" to "/statistics").
 */
export function zoneForPath(pathname: string): Zone {
  for (const group of NAV_GROUPS) {
    if (group.items.some((item) => isNavItemActive(pathname, item))) {
      return group.zone;
    }
  }
  return "ws";
}

/**
 * A stale count is worse than no count: showing yesterday's or a default 0
 * while the real number is still in flight reads as truth for the instant
 * before the query resolves. Rail.tsx renders no badge at all — not a
 * spinner, not a "…" — while `isLoading` is true.
 */
export function railBadgeCount(count: number | undefined, isLoading: boolean): number | undefined {
  return isLoading ? undefined : count;
}
