/**
 * src/ui/icons — the one place this app names a glyph.
 *
 * Nothing else imports `lucide-react` directly, so this file stays the single
 * audit point for iconography end to end: which glyphs are in play, and whether
 * a screen reached for one that nobody accounted for. That was the deleted
 * app's rule too (its `ui/icons.ts` re-exported Phosphor); only the underlying
 * package changes, because apps/web ships `lucide-react` and does not ship
 * `@phosphor-icons/react` (web-design-contract.md §4.4 — local hand-rolled SVGs
 * for sidebar nav, lucide for dashboard tiles, @mui/icons-material only where a
 * table or toolbar needs a stock glyph).
 *
 * The Phosphor → lucide mapping, so a spec that names the old glyph is still
 * findable:
 *
 *   ArrowsClockwise → RefreshCw     Buildings      → Building2
 *   CalendarBlank   → Calendar      CaretDown/L/R  → ChevronDown/Left/Right
 *   Funnel          → Filter        Gear           → Settings
 *   ListBullets     → List          LockSimple     → Lock
 *   MagnifyingGlass → Search        Prohibit       → Ban
 *   SignOut         → LogOut        SquaresFour    → LayoutGrid
 *   Trash           → Trash2        UserCircle     → CircleUser
 *   UserSwitch      → UserCog       UsersThree     → Users
 *   WarningCircle   → CircleAlert   Warning        → TriangleAlert
 *
 * The list covers the four in-scope screens (overview, applications, users,
 * audit) plus the shell, and nothing else — an icon in this file is a small
 * promise that some screen renders it. The out-of-scope moderation / 3D-tour /
 * plans screens have no glyphs here because they have no routes either.
 */
export {
  ArrowDownRight,
  ArrowRight,
  ArrowUpRight,
  Ban,
  Bell,
  Building2,
  Calendar,
  Check,
  ChevronDown,
  ChevronLeft,
  ChevronRight,
  CircleAlert,
  CircleUser,
  Clock,
  Database,
  Eye,
  Filter,
  Info,
  LayoutGrid,
  List,
  Lock,
  LogOut,
  Minus,
  RefreshCw,
  Search,
  Settings,
  Trash2,
  TriangleAlert,
  User,
  UserCog,
  Users,
  X,
} from "lucide-react";

import type { ComponentType } from "react";

/**
 * The narrow prop surface our own primitives (Button, IconButton, Tag,
 * RowAction, EmptyState, …) actually reach for. Every lucide icon satisfies it
 * structurally, which means a primitive can say "an icon goes here" without
 * importing lucide's full `LucideProps` (every SVG attribute, ref forwarding,
 * `absoluteStrokeWidth`, …).
 *
 * Icons are passed as a COMPONENT REFERENCE, never as a pre-built element
 * (`icon={CheckIcon}`, not `icon={<CheckIcon />}`), so the primitive owns the
 * size and every glyph in a given slot comes out the same size. A call site
 * that needs something specific passes a small inline wrapper of its own.
 */
export type IconComponent = ComponentType<{
  size?: number | string;
  className?: string;
  "aria-hidden"?: boolean | "true" | "false";
}>;
