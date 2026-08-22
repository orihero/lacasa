/**
 * src/shell/PageHead — the toolbar row every screen opens with: filters and
 * segmented controls on the left, a quiet right-aligned fact next, actions
 * last. It is apps/web's list-screen header bar, `.ads-new`, with its
 * `.ads-tools` cluster on the right (web-design-contract.md §6):
 *
 *   .ads-new   { display: flex; justify-content: space-between; align-items:
 *                center; gap: 10px; }
 *   .ads-tools { display: flex; gap: 10px; }
 *
 * THERE IS DELIBERATELY NO `title` PROP, unlike apps/web's `.ads-title`
 * slot: the page title lives in the Topbar (shell/nav.ts's `titleForPath`) so
 * it stays visible when a 200-row table scrolls, and it is the page's one
 * `<h1>`. A screen that also rendered its own heading would be repeating it
 * two lines below itself.
 *
 * `note` is TEXT, not a control — "Newest first · 50 per page", "Sorted by
 * oldest first". Anything clickable belongs in `actions`.
 */
import type { ReactNode } from "react";
import "./pageHead.scss";

export interface PageHeadProps {
  /** Filters, segmented controls — the "what am I looking at" half. */
  children?: ReactNode;
  /** Buttons — the "what can I do" half, right-aligned. */
  actions?: ReactNode;
  /** A quiet right-aligned fact (sort order, page size). Text, not a control. */
  note?: ReactNode;
  className?: string;
}

export function PageHead({ children, actions, note, className }: PageHeadProps) {
  return (
    <div className={className ? `ads-new page-head ${className}` : "ads-new page-head"}>
      {children != null ? <div className="page-head__filters">{children}</div> : null}
      <div className="page-head__spacer" />
      {note != null ? <span className="page-head__note">{note}</span> : null}
      {actions != null ? <div className="ads-tools page-head__actions">{actions}</div> : null}
    </div>
  );
}
