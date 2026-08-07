/**
 * src/shell/Toolbar — the `.tools` row: segmented filters, filter chips and
 * a trailing action button, wrapped and gapped consistently across every
 * table screen (My ads, Publish status, Leads, Coworkers).
 */
import type { ReactNode } from "react";

export interface ToolbarProps {
  children: ReactNode;
}

export function Toolbar({ children }: ToolbarProps) {
  return <div className="mb-4 flex flex-wrap items-center gap-2">{children}</div>;
}
