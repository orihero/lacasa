/**
 * Panel — F's `.panel` superellipse surface (mockups/f/build/f-components.css
 * `.panel`/`.panel-head`), the single card shape every screen composes with:
 * stat cards, the chart card, the table wrapper, the editor's two-column
 * form, the accounts screen. `PanelHead`'s `children` are the right-aligned
 * controls slot (`.panel-ctl`) — a segmented control, an "Upload" button, a
 * date pill, whatever the screen needs next to the title.
 */
import type { ReactNode } from "react";
import clsx from "clsx";

export function Panel({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className={clsx("rounded-card border border-black/[.03] bg-surface p-[22px]", className)}>
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
    <div className="mb-4 flex items-start justify-between gap-3.5">
      <div>
        <div className="text-title font-semibold tracking-snug text-ink">{title}</div>
        {sub != null ? <div className="mt-[3px] text-small text-ink-2">{sub}</div> : null}
      </div>
      {children != null ? <div className="flex items-center gap-2">{children}</div> : null}
    </div>
  );
}
