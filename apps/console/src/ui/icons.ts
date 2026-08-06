/**
 * Central re-export of every Phosphor icon the console draws on, under
 * Phosphor's own names — nothing else in this app imports
 * `@phosphor-icons/react` directly, so this file is the one place to audit
 * iconography end to end (which glyphs are in play, whether a screen reached
 * for a new one that isn't accounted for in the design).
 *
 * @phosphor-icons/react v2.1.10 ships every icon under two export names: a
 * deprecated bare one (`House`) kept only for v1 back-compat, and the
 * recommended weight-agnostic one (`HouseIcon`) that this file always
 * re-exports. Weight (regular/bold/fill/…) is a runtime prop, not baked into
 * the import — the prototype's `house-fill` is `<HouseIcon weight="fill" />`
 * at the call site, not a separate `HouseFillIcon` export.
 *
 * This list is every `data-i` glyph slug used anywhere across the 8 screens
 * of mockups/f/f-console.src.html (including the kanban drag module and the
 * stage-gate modal), not just the glyphs the design-system primitives
 * themselves render — the screen agents building on top of these primitives
 * should never need to reach past this file into the icon package.
 */
export {
  ArrowLeftIcon,
  ArrowRightIcon,
  ArrowUpRightIcon,
  BellIcon,
  BroadcastIcon,
  BuildingsIcon,
  CameraIcon,
  CaretDownIcon,
  CaretUpDownIcon,
  CheckCircleIcon,
  CheckIcon,
  ClockIcon,
  EyeIcon,
  FunnelIcon,
  GearIcon,
  HouseIcon,
  InstagramLogoIcon,
  KanbanIcon,
  LinkSimpleIcon,
  MagnifyingGlassIcon,
  NotePencilIcon,
  PaperPlaneTiltIcon,
  PhoneIcon,
  PlusIcon,
  SignOutIcon,
  SquaresFourIcon,
  StorefrontIcon,
  TagIcon,
  TelegramLogoIcon,
  TrashIcon,
  UploadSimpleIcon,
  UserIcon,
  UsersThreeIcon,
  WarningIcon,
  XIcon,
  YoutubeLogoIcon,
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
