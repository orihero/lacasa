/**
 * Avatar — F's `.avchip`/`.user-av`. PLAN.md §1 explicitly drops F's
 * procedural persona-SVG generator: named real people (Dilnoza Yusupova,
 * Sardor Abdullayev, …) in a working tool get a real photo when one exists,
 * and otherwise a plain two-letter initials chip — never stock-persona art
 * standing in for them.
 *
 * `initials` is deliberately hand-rolled here rather than imported from
 * `@lacasa/console`'s own `lib/format.ts` — that module is owned by a
 * different concurrently-written agent, and this component's one hard
 * requirement (PLAN.md §1: "same person, same chip, every render") can't
 * depend on a sibling module that doesn't exist yet at build time. Pure
 * function of the name, no randomness.
 */
import clsx from "clsx";
import type { Tone } from "./Tag";

// Pure helper deliberately co-located with Avatar (see file header) rather
// than split into its own file just to satisfy fast refresh.
// eslint-disable-next-line react-refresh/only-export-components
export function initials(fullName: string): string {
  const words = fullName.trim().split(/\s+/).filter(Boolean);
  const first = words[0] ?? "";
  const second = words[1];
  if (second) {
    return `${first[0] ?? ""}${second[0] ?? ""}`.toUpperCase();
  }
  return first.slice(0, 2).toUpperCase();
}

type Size = "sm" | "md" | "lg";

const SIZE_BOX: Record<Size, string> = {
  sm: "h-[30px] w-[30px]",
  md: "h-[34px] w-[34px]",
  lg: "h-10 w-10",
};

const SIZE_TEXT: Record<Size, string> = {
  sm: "text-tiny",
  md: "text-caption",
  lg: "text-body",
};

const TONE_CLASS: Record<Tone, string> = {
  ok: "bg-ok-soft text-ok",
  warn: "bg-warn-soft text-warn",
  err: "bg-err-soft text-err",
  info: "bg-info-soft text-info",
  mute: "bg-mute-soft text-mute",
  accent: "bg-accent-tint text-accent-text",
};

export interface AvatarProps {
  src?: string | null;
  name: string;
  size?: Size;
  tone?: Tone;
  className?: string;
}

export function Avatar({ src, name, size = "sm", tone = "mute", className }: AvatarProps) {
  if (src) {
    return (
      <img
        src={src}
        alt={name}
        className={clsx("shrink-0 rounded-full bg-surface-inner object-cover", SIZE_BOX[size], className)}
      />
    );
  }
  return (
    <span
      role="img"
      aria-label={name}
      className={clsx(
        "flex shrink-0 items-center justify-center rounded-full font-bold",
        SIZE_BOX[size],
        SIZE_TEXT[size],
        TONE_CLASS[tone],
        className,
      )}
    >
      {initials(name)}
    </span>
  );
}
