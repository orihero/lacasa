/**
 * Tag — F's status pill (`.tag`/`.tag--ok`/`.tag--warn`/…). This is the
 * semantic status layer PLAN.md §1 calls out as a deliberate third color
 * category, distinct from both the neutrals and the accent: Ad.stage,
 * Lead.status and publish status all render through this one component so
 * their five-ish color codings can never drift into the accent lime
 * (`accent` tone exists for the one legitimate exception — Sold rows,
 * PLAN.md §3.2 — not for general emphasis).
 */
import type { ReactNode } from "react";
import clsx from "clsx";
import type { IconComponent } from "./icons";

export type Tone = "ok" | "warn" | "err" | "info" | "mute" | "accent";

const TONE_CLASS: Record<Tone, string> = {
  ok: "bg-ok-soft text-ok",
  warn: "bg-warn-soft text-warn",
  err: "bg-err-soft text-err",
  info: "bg-info-soft text-info",
  mute: "bg-mute-soft text-mute",
  accent: "bg-accent-tint text-accent-text",
};

export function Tag({
  tone = "mute",
  dot,
  icon: Icon,
  children,
}: {
  tone?: Tone;
  dot?: boolean;
  icon?: IconComponent;
  children: ReactNode;
}) {
  return (
    <span
      className={clsx(
        "inline-flex items-center gap-[5px] whitespace-nowrap rounded-chip px-[9px] py-[3.5px] text-caption font-semibold",
        TONE_CLASS[tone],
      )}
    >
      {dot ? (
        <span aria-hidden="true" className="h-1.5 w-1.5 shrink-0 rounded-full bg-current" />
      ) : null}
      {Icon ? <Icon size={11} className="shrink-0" /> : null}
      {children}
    </span>
  );
}
