/**
 * src/shell/PageHead — the `.page-head` grammar every screen opens with: a
 * breadcrumb + h1 on the left, arbitrary controls (a date pill, an export
 * button, a segmented toggle, …) right-aligned via the same flex-spacer the
 * topbar and toolbar use.
 */
import type { ReactNode } from "react";

export interface PageHeadProps {
  crumb: ReactNode;
  title: string;
  children?: ReactNode;
}

export function PageHead({ crumb, title, children }: PageHeadProps) {
  return (
    <div className="mb-[18px] flex flex-wrap items-end gap-4">
      <div>
        <div className="mb-[7px] flex items-center gap-1.5 text-small text-ink-2">{crumb}</div>
        <h1 className="text-h1 font-semibold tracking-display">{title}</h1>
      </div>
      <div className="flex-1" />
      {children}
    </div>
  );
}
