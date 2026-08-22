/**
 * Table primitives — MUI's table in apps/web's exact shape.
 *
 * The house pattern is apps/web/src/components/coworkerList/CoworkerList.jsx
 * (web-design-contract.md §7): one component per line from a deep MUI path,
 * `<Paper sx={{ width: "100%", overflow: "hidden" }}>` (that is `Panel`) around
 * `<TableContainer sx={{ maxHeight: 540 }}>` around
 * `<Table stickyHeader aria-label="sticky table">`. Reproduced here once as a
 * primitive rather than copy-pasted into four screens, because unlike apps/web
 * this app renders the same table shape on three screens that all have to agree
 * about skeleton rhythm, mono columns and row actions.
 *
 * Three deliberate departures from the copy-paste, all forced by specs that
 * outrank the design contract (PRECEDENCE.md):
 *
 *  1. NO `TablePagination`. Every admin list is keyset-paged on
 *     `(createdAt desc, id desc)` behind an opaque cursor; there is no total
 *     and no way to jump to page 7, so a numbered pager could only lie. The
 *     footer is `LoadMore` (conflict 1).
 *  2. NO `role="checkbox"` on rows. apps/web puts it on every row and it is
 *     simply wrong; here it would also overwrite the row's real ARIA role, and
 *     this app's screens are queried by role in their tests (conflict 8).
 *  3. NO row `onClick`. Nothing in this app opens a record by clicking its
 *     row — the deleted app's `TR.onClick` had no call site — so the
 *     keyboard-operable-row machinery is not ported either (PRECEDENCE.md,
 *     "Drop the dead exports"). Row-level affordances are `RowAction`s, which
 *     are real buttons with real accessible names.
 */
import Button from "@mui/material/Button";
import MuiTable from "@mui/material/Table";
import TableBody from "@mui/material/TableBody";
import TableCell from "@mui/material/TableCell";
import TableContainer from "@mui/material/TableContainer";
import TableHead from "@mui/material/TableHead";
import TableRow from "@mui/material/TableRow";
import type { ReactNode } from "react";
import type { IconComponent } from "./icons";
import "./table.scss";

export function Table({
  children,
  /**
   * apps/web's `<TableContainer sx={{ maxHeight: 540 }}>`. The sticky header
   * needs a bounded scroller to stick against, and the page itself must not be
   * the scroller — a nine-column users table has to slide sideways INSIDE this
   * box rather than taking the rail and topbar with it.
   */
  maxHeight = 540,
  ariaLabel = "sticky table",
}: {
  children: ReactNode;
  maxHeight?: number | string;
  ariaLabel?: string;
}) {
  return (
    <TableContainer className="tbl" sx={{ maxHeight }}>
      <MuiTable stickyHeader aria-label={ariaLabel}>
        {children}
      </MuiTable>
    </TableContainer>
  );
}

export function THead({ children }: { children: ReactNode }) {
  return <TableHead>{children}</TableHead>;
}

export function TH({
  align = "left",
  width,
  children,
}: {
  align?: "left" | "right";
  /** A fixed column width, as apps/web's `style={{ minWidth: column.minWidth }}`. */
  width?: number | string;
  children?: ReactNode;
}) {
  return (
    <TableCell
      align={align}
      className="tbl__th"
      style={width === undefined ? undefined : { width, minWidth: width }}
    >
      {children}
    </TableCell>
  );
}

export function TBody({ children }: { children: ReactNode }) {
  return <TableBody>{children}</TableBody>;
}

export function TR({
  selected,
  children,
}: {
  /** A selection state, distinct from hover — not used by any screen yet. */
  selected?: boolean;
  children: ReactNode;
}) {
  return (
    <TableRow hover selected={selected}>
      {children}
    </TableRow>
  );
}

export function TD({
  align = "left",
  mono,
  children,
  className,
}: {
  align?: "left" | "right";
  /** UUIDs, timestamps, counts, phone numbers — anything read character by character. */
  mono?: boolean;
  children?: ReactNode;
  className?: string;
}) {
  const classes = ["tbl__td", mono ? "tbl__td--mono" : "", className ?? ""]
    .filter(Boolean)
    .join(" ");
  return (
    <TableCell align={align} className={classes}>
      {children}
    </TableCell>
  );
}

export function CellMain({
  /**
   * An arbitrary node, not a photo URL: the same cell carries a round `Avatar`
   * on users and applications, a square listing thumb, or a plain status glyph
   * on the overview queue. This primitive lays out whatever it is handed and
   * imposes no shape.
   */
  thumb,
  icon: Icon,
  title,
  sub,
}: {
  thumb?: ReactNode;
  icon?: IconComponent;
  title: ReactNode;
  sub?: ReactNode;
}) {
  return (
    <div className="cell-main">
      {thumb ?? (Icon ? <Icon size={16} aria-hidden="true" /> : null)}
      <div className="cell-main__text">
        <div className="cell-main__title">{title}</div>
        {sub != null ? <span className="cell-main__sub">{sub}</span> : null}
      </div>
    </div>
  );
}

/** The right-aligned cluster of row-level buttons. */
export function RowActions({ children }: { children: ReactNode }) {
  return <div className="row-actions">{children}</div>;
}

const ROW_ACTION_COLOR: Record<"neutral" | "ok" | "no", string> = {
  neutral: "#2b2d42",
  // The settled-good green from apps/web's StatusCell (`accepted`).
  ok: "#28a745",
  // `.icons { color: rgb(235, 59, 59); }` — apps/web's row-level destructive.
  no: "rgb(235, 59, 59)",
};

export function RowAction({
  icon: Icon,
  label,
  tone = "neutral",
  onClick,
  disabled,
  children,
}: {
  icon: IconComponent;
  /**
   * REQUIRED, and used as both `aria-label` and `title`, even when `children`
   * gives the button visible text. These are the controls that change someone
   * else's account: `Approve Dilnoza Yusupova` is what a screen reader has to
   * announce, and it is what the screens' tests select on.
   */
  label: string;
  /** `ok` grants, `no` refuses, `neutral` merely navigates or filters. */
  tone?: "neutral" | "ok" | "no";
  onClick?: () => void;
  disabled?: boolean;
  /** Optional visible text beside the glyph. */
  children?: ReactNode;
}) {
  return (
    <Button
      type="button"
      variant="text"
      size="small"
      className="row-action"
      aria-label={label}
      title={label}
      onClick={onClick}
      disabled={disabled}
      sx={{
        minWidth: 0,
        padding: "4px 8px",
        fontSize: "13px",
        gap: "6px",
        color: ROW_ACTION_COLOR[tone],
        "&:hover": { backgroundColor: "#eeeeee" },
      }}
    >
      <Icon size={14} aria-hidden="true" />
      {children}
    </Button>
  );
}
