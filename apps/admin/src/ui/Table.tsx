/**
 * Table — the control room's `.tbl`: 38px rows, a sunk uppercase header, a
 * half-strength hairline between rows and nothing else. Backs the Users
 * table, the Audit log and the Overview queue list.
 *
 * Deliberately NOT apps/console's zebra-striped, pill-shaped table. Density
 * is the point here (see tailwind.config.js rule 4): an admin scans hundreds
 * of rows looking for the one that is wrong, so rows are separated by a
 * hairline rather than by alternating fills, which at this row height would
 * turn the table into a barcode.
 *
 * `border-collapse` (not the console's `border-separate` + rounded end caps)
 * because these rows are records in a ledger, not cards in a list — a
 * continuous rule from column one to column N is exactly what a ledger wants.
 *
 * `CellMain`'s `thumb` slot is a bare `ReactNode`, not a photo URL: the same
 * cell shape carries a round `Avatar` (users, applications), a 26px square
 * listing thumb, or a plain status glyph (the Overview queue rows). This
 * primitive lays out whichever one the screen hands it; it doesn't impose a
 * shape.
 */
import type { ReactNode } from "react";
import clsx from "clsx";
import type { IconComponent } from "./icons";

export function Table({ children, className }: { children: ReactNode; className?: string }) {
  return (
    // The horizontal scroller lives here rather than on the page: a Users
    // table with 9 columns overflows a narrow window, and the whole page
    // sliding sideways would take the rail and topbar with it.
    <div className="overflow-x-auto">
      <table className={clsx("w-full border-collapse text-body", className)}>{children}</table>
    </div>
  );
}

export function THead({ children }: { children: ReactNode }) {
  return <thead>{children}</thead>;
}

export function TH({
  align = "left",
  width,
  children,
}: {
  align?: "left" | "right";
  width?: string;
  children?: ReactNode;
}) {
  return (
    <th
      style={width ? { width } : undefined}
      className={clsx(
        "whitespace-nowrap border-b border-line bg-sunk px-[13px] py-2 text-caps font-bold uppercase tracking-caps-wide text-faint",
        align === "right" ? "text-right" : "text-left",
      )}
    >
      {children}
    </th>
  );
}

export function TBody({ children }: { children: ReactNode }) {
  return <tbody>{children}</tbody>;
}

export function TR({
  selected,
  onClick,
  children,
}: {
  selected?: boolean;
  onClick?: () => void;
  children: ReactNode;
}) {
  return (
    <tr
      onClick={onClick}
      // A bare <tr onClick> is invisible to a keyboard-only admin — no native
      // focus, no Enter/Space activation. Every row-level affordance on this
      // surface opens a record an admin may then act destructively on, so it
      // has to be reachable the same way a mouse reaches it.
      tabIndex={onClick ? 0 : undefined}
      role={onClick ? "button" : undefined}
      onKeyDown={
        onClick
          ? (event) => {
              if (event.key !== "Enter" && event.key !== " ") return;
              event.preventDefault();
              onClick();
            }
          : undefined
      }
      className={clsx(
        // The last row's rule would otherwise double up with the enclosing
        // Panel's own bottom border, which reads as a 2px seam on a dark
        // canvas. Expressed here rather than on TD because "am I the last
        // row?" is a fact about the row, and a TD cannot see it.
        "h-row [&:last-child>td]:border-b-0",
        selected ? "bg-acc-soft" : "hover:bg-sunk",
        onClick &&
          "cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-acc",
      )}
    >
      {children}
    </tr>
  );
}

export function TD({
  align = "left",
  mono,
  children,
  className,
}: {
  align?: "left" | "right";
  /** UUIDs, timestamps, counts, phone numbers — see tailwind.config.js rule 3. */
  mono?: boolean;
  children?: ReactNode;
  className?: string;
}) {
  return (
    <td
      className={clsx(
        "border-b border-line-2 px-[13px] py-[7px] align-middle text-body text-ink",
        mono && "font-mono text-record",
        align === "right" ? "text-right" : "text-left",
        className,
      )}
    >
      {children}
    </td>
  );
}

export function CellMain({
  thumb,
  icon: Icon,
  iconClassName,
  title,
  sub,
}: {
  thumb?: ReactNode;
  icon?: IconComponent;
  iconClassName?: string;
  title: ReactNode;
  sub?: ReactNode;
}) {
  return (
    <div className="flex min-w-0 items-center gap-[9px]">
      {thumb ?? (Icon ? <Icon size={16} className={clsx("shrink-0", iconClassName)} /> : null)}
      <div className="min-w-0">
        <div className="truncate text-body font-semibold leading-tight text-ink">{title}</div>
        {sub != null ? (
          <span className="block truncate text-mini leading-tight text-muted">{sub}</span>
        ) : null}
      </div>
    </div>
  );
}

/**
 * The right-aligned row-action cluster (`.acts`) — small, quiet buttons that
 * only take on colour on hover, so a table of 200 rows isn't a wall of
 * green and red. `tone` decides which colour they take: `ok` for granting,
 * `no` for refusing.
 */
export function RowActions({ children }: { children: ReactNode }) {
  return <div className="flex justify-end gap-[3px]">{children}</div>;
}

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
   * Required even when `children` gives the button visible text — an
   * icon-only action ("view", "lock") would otherwise announce as nothing,
   * and these are the controls that change someone's account.
   */
  label: string;
  tone?: "neutral" | "ok" | "no";
  onClick?: () => void;
  disabled?: boolean;
  /** Optional visible text next to the glyph (the mockup's "Review", "Keep"). */
  children?: ReactNode;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      disabled={disabled}
      aria-label={label}
      title={label}
      className={clsx(
        "inline-flex h-[25px] items-center gap-1.5 rounded-act border border-transparent px-2 text-record font-semibold text-muted transition-colors hover:border-line hover:bg-sunk focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-acc disabled:cursor-not-allowed disabled:opacity-40",
        tone === "ok" && "hover:border-ok hover:text-ok",
        tone === "no" && "hover:border-err hover:text-err",
        tone === "neutral" && "hover:text-ink",
      )}
    >
      <Icon size={13} className="shrink-0" />
      {children}
    </button>
  );
}
