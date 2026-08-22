/**
 * Seg — F's segmented pill control (`.seg`), the console's one recurring
 * "pick one of N" pattern: My ads' All/Active/Sold/Draft filter, the
 * Statistics chart's Month/Quarter/Year range, Leads' Table/Kanban view
 * switch. Renders real `<button>`s with `aria-pressed` — the prototype's
 * `.seg button.is-on` toggling is a visual-only convention with no
 * semantics; this is the one place in the port that adds them back.
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
}: {
  options: ReadonlyArray<SegOption<T>>;
  value: T;
  onChange: (value: T) => void;
}) {
  return (
    <div className="flex gap-1.5">
      {options.map((opt) => {
        const active = opt.value === value;
        return (
          <button
            key={opt.value}
            type="button"
            aria-pressed={active}
            onClick={() => onChange(opt.value)}
            className={clsx(
              "whitespace-nowrap rounded-full border px-[15px] py-[9px] text-label font-medium transition-colors",
              active
                ? "border-dark bg-dark text-dark-text"
                : "border-hairline bg-pill text-ink hover:bg-surface-inner",
            )}
          >
            {opt.label}
          </button>
        );
      })}
    </div>
  );
}
