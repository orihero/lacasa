/**
 * Seg — the control room's segmented control (`.seg`): one sunk track with
 * the selected option raised out of it. This surface's one recurring "pick
 * one of N" pattern — Applications' Pending/Approved/Rejected, Users'
 * All/Buyers/Agents/Coworkers, Audit's type filter.
 *
 * `hot` marks the amber-selected variant the mockup uses on the DEFAULT
 * segment of a queue ("Pending 3"): amber here says "this is the tab that
 * has work in it", which is why it is a per-Seg flag rather than a per-option
 * one — exactly one segment can be the queue, and it is whichever one is
 * currently selected while `hot` is on.
 *
 * Renders real `<button>`s with `aria-pressed`; the mockup's `.is-on` class
 * toggling is a visual-only convention with no semantics.
 */
import type { ReactNode } from "react";
import clsx from "clsx";

export interface SegOption<T extends string> {
  value: T;
  label: ReactNode;
}

export function Seg<T extends string>({
  options,
  value,
  onChange,
  hot,
  label,
}: {
  options: ReadonlyArray<SegOption<T>>;
  value: T;
  onChange: (value: T) => void;
  hot?: boolean;
  /** Names the group for screen readers ("Application status", "Role"). */
  label: string;
}) {
  return (
    <div
      role="group"
      aria-label={label}
      className="flex gap-0.5 rounded-control border border-line bg-sunk p-0.5"
    >
      {options.map((opt) => {
        const active = opt.value === value;
        return (
          <button
            key={opt.value}
            type="button"
            aria-pressed={active}
            onClick={() => onChange(opt.value)}
            className={clsx(
              "whitespace-nowrap rounded-act px-[11px] py-1 text-small font-semibold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-acc",
              active
                ? hot
                  ? "bg-acc text-on-acc"
                  : "bg-card text-ink shadow-panel"
                : "text-muted hover:text-ink",
            )}
          >
            {opt.label}
          </button>
        );
      })}
    </div>
  );
}
