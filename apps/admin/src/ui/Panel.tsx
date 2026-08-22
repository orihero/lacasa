/**
 * Panel / PanelHead — the card every screen composes with.
 *
 * In apps/web this shape is written out at each call site as
 * `<Paper sx={{ width: "100%", overflow: "hidden" }}>` wrapping a table
 * (web-design-contract.md §6/§7.3), so that is exactly what Panel is: MUI's
 * Paper, square (the theme sets `shape.borderRadius: 0`), full width, and
 * `overflow: hidden` — which is load-bearing rather than cosmetic, because a
 * `<table>` dropped straight in would otherwise poke its corners past the card
 * and, more importantly, the horizontal scroller belongs to the table (see
 * Table.tsx) rather than to the panel.
 *
 * Panel deliberately has NO padding of its own: the table between a head and a
 * LoadMore footer is edge-to-edge, and content that wants padding says so.
 *
 * `PanelFoot` from the deleted app is NOT ported — it had no call site
 * anywhere (PRECEDENCE.md, factual correction 4). The bordered strip under a
 * table is `LoadMore`, and the two error strips are the screens' own markup.
 */
import Paper from "@mui/material/Paper";
import type { ReactNode } from "react";
import "./panel.scss";

export function Panel({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <Paper className={className ? `panel ${className}` : "panel"} sx={{ width: "100%", overflow: "hidden" }}>
      {children}
    </Paper>
  );
}

export function PanelHead({
  title,
  sub,
  children,
}: {
  title: ReactNode;
  /** The quiet second line — what this panel is showing, not a repeat of the title. */
  sub?: ReactNode;
  /** The right-aligned controls slot: a segmented switch, a count, a refresh button. */
  children?: ReactNode;
}) {
  return (
    <div className="panel-head">
      <div className="panel-head__heading">
        {/*
          An <h2>, because the ONE <h1> on a signed-in screen is the topbar's
          page title (PRECEDENCE.md, "Document structure / landmarks"). A panel
          title is a section inside that page, never a second page title.
        */}
        <h2 className="panel-head__title">{title}</h2>
        {sub != null ? <p className="panel-head__sub">{sub}</p> : null}
      </div>
      {children != null ? <div className="panel-head__tools">{children}</div> : null}
    </div>
  );
}
