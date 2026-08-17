/**
 * Central re-export of every Phosphor icon the control room draws on, under
 * Phosphor's own names — nothing else in this app imports
 * `@phosphor-icons/react` directly, so this file is the one place to audit
 * iconography end to end (which glyphs are in play, whether a screen reached
 * for one that isn't accounted for in the design).
 *
 * @phosphor-icons/react v2.1.10 ships every icon under two export names: a
 * deprecated bare one (`Bell`) kept only for v1 back-compat, and the
 * recommended weight-agnostic one (`BellIcon`) that this file always
 * re-exports. Weight (regular/bold/fill/…) is a runtime prop, not baked into
 * the import — the mockup's `squares-four-fill` is
 * `<SquaresFourIcon weight="fill" />` at the call site, not a separate
 * `SquaresFourFillIcon` export.
 *
 * This list covers every `data-i` glyph slug used by the FOUR IN-SCOPE
 * screens of mockups/build/web-admin.src.html (overview, applications,
 * users, audit) plus the shell around them. The mockup's moderation, 3D-tour
 * and plans screens are out of scope, so their glyphs (`map-pin-fill`,
 * `eye-slash`, `video-camera-fill`, `tag-fill`) are deliberately absent — an
 * icon in this file is a small promise that some screen renders it.
 */
export {
  ArrowDownRightIcon,
  ArrowRightIcon,
  ArrowUpRightIcon,
  ArrowsClockwiseIcon,
  BellIcon,
  BuildingsIcon,
  CalendarBlankIcon,
  CaretDownIcon,
  CaretLeftIcon,
  CaretRightIcon,
  CheckIcon,
  ClockIcon,
  DatabaseIcon,
  EyeIcon,
  FunnelIcon,
  GearIcon,
  InfoIcon,
  ListBulletsIcon,
  LockSimpleIcon,
  MagnifyingGlassIcon,
  MinusIcon,
  ProhibitIcon,
  SignOutIcon,
  SquaresFourIcon,
  TrashIcon,
  UserCircleIcon,
  UserIcon,
  UserSwitchIcon,
  UsersThreeIcon,
  WarningCircleIcon,
  WarningIcon,
  XIcon,
} from "@phosphor-icons/react";
export type { IconWeight } from "@phosphor-icons/react";

import type { ComponentType } from "react";
import type { IconWeight } from "@phosphor-icons/react";

/**
 * The narrow prop surface our own primitives (Button, IconButton, Tag,
 * RowActions, …) actually reach for. Every Phosphor icon component satisfies
 * this structurally — spelling it out here means a primitive's props file
 * doesn't need to import the full `@phosphor-icons/react` IconProps surface
 * (SVG attrs, ref forwarding, `mirrored`, …) just to say "an icon goes here".
 */
export type IconComponent = ComponentType<{
  size?: number;
  weight?: IconWeight;
  className?: string;
}>;
