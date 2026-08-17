/**
 * src/shell/PageHead — the toolbar row every screen opens with (the mockup's
 * `.tools`): filters and segmented controls on the left, actions on the right,
 * with an optional right-aligned status line for the quiet facts the mockup
 * puts there ("Sorted by oldest first", "Processing queue: 2 running").
 *
 * There is no `title` prop, unlike apps/console's PageHead: the page title
 * lives in the Topbar (shell/nav.ts's `titleForPath`) so it stays visible when
 * a 200-row table scrolls. A screen that also rendered its own <h1> would be
 * repeating the heading two lines below itself.
 */
import type { ReactNode } from "react";
import clsx from "clsx";

export interface PageHeadProps {
  /** Filters, segmented controls — the "what am I looking at" half. */
  children?: ReactNode;
  /** Buttons — the "what can I do" half, right-aligned. */
  actions?: ReactNode;
  /** A quiet right-aligned fact (sort order, queue depth). Text, not a control. */
  note?: ReactNode;
  className?: string;
}

export function PageHead({ children, actions, note, className }: PageHeadProps) {
  return (
    <div className={clsx("mb-3.5 flex flex-wrap items-center gap-2", className)}>
      {children}
      <div className="flex-1" />
      {note != null ? <span className="text-record text-muted">{note}</span> : null}
      {actions}
    </div>
  );
}
