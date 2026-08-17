/**
 * Panel — the control room's `.panel`: the single raised card shape every
 * screen composes with (the KPI row, the trend chart, every table wrapper,
 * the queue list). `overflow-hidden` is load-bearing rather than cosmetic —
 * a `<table>` dropped straight in has square corners that would otherwise
 * poke out past the panel's 11px radius.
 *
 * `PanelHead`'s `children` are the right-aligned controls slot (a segmented
 * range switch, an export button, a count) and `PanelFoot` is the mockup's
 * bordered strip under a table (storage bars, totals, an explanatory note).
 * Both sit OUTSIDE the panel's own padding because the table between them is
 * edge-to-edge: `Panel` deliberately has no padding of its own, and content
 * that needs it says so (`<div className="p-[15px]">`), exactly as the
 * mockup does.
 */
import type { ReactNode } from "react";
import clsx from "clsx";

export function Panel({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div
      className={clsx(
        "overflow-hidden rounded-panel border border-line bg-card shadow-panel",
        className,
      )}
    >
      {children}
    </div>
  );
}

export function PanelHead({
  title,
  sub,
  children,
}: {
  title: ReactNode;
  sub?: ReactNode;
  children?: ReactNode;
}) {
  return (
    <div className="flex items-center gap-3 border-b border-line px-[15px] py-3">
      <div className="min-w-0">
        <h2 className="text-label font-semibold text-ink">{title}</h2>
        {sub != null ? <p className="mt-px text-tiny text-muted">{sub}</p> : null}
      </div>
      {children != null ? (
        <div className="ml-auto flex flex-none items-center gap-2">{children}</div>
      ) : null}
    </div>
  );
}

export function PanelFoot({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className={clsx("border-t border-line px-[15px] py-3", className)}>{children}</div>
  );
}
