/**
 * Tag — the control room's `.tag` status pill: uppercase, tracked-out, 10px.
 * Every enum-shaped value this surface displays (role, realtor status, ad
 * stage, publication status, audit level) renders through this one component
 * so their colour codings can never drift into the amber signal.
 *
 * `acc` (amber) is reserved for "this is waiting on YOU" — a pending
 * application, a queue depth, an unreviewed item. It is not a general
 * emphasis tone: if an already-decided row shows amber, the badge stops
 * meaning "act on this" and the overview's queue counts stop being scannable.
 * `danger` is likewise reserved for the irreversible (see Button).
 */
import type { ReactNode } from "react";
import clsx from "clsx";
import type { IconComponent } from "./icons";

export type Tone = "ok" | "acc" | "err" | "info" | "mute" | "danger";

const TONE_CLASS: Record<Tone, string> = {
  ok: "bg-ok-soft text-ok",
  acc: "bg-acc-soft text-acc",
  err: "bg-err-soft text-err",
  info: "bg-info-soft text-info",
  mute: "border border-line bg-sunk text-muted",
  danger: "bg-danger-soft text-danger",
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
        "inline-flex items-center gap-1 whitespace-nowrap rounded-tag px-[7px] py-0.5 text-mini font-bold uppercase tracking-caps",
        TONE_CLASS[tone],
      )}
    >
      {dot ? (
        <span aria-hidden="true" className="h-[5px] w-[5px] shrink-0 rounded-full bg-current" />
      ) : null}
      {Icon ? <Icon size={10} className="shrink-0" /> : null}
      {children}
    </span>
  );
}
