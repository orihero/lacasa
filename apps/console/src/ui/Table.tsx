/**
 * Table — F's net-new `.tbl` primitive (f-components.css `.tbl`/`.cellmain`/
 * `.thumb`/ghost-row block). F itself has zero table precedent; this is the
 * single largest net-new component in the port (PLAN.md §3.2/§5) and backs
 * all four table-heavy screens (My ads, Publish status, Leads, Coworkers).
 *
 * Zebra and selection are row-level facts (even/odd position, `selected`)
 * that have to repaint on every *cell* to keep the "row reads as one
 * continuous pill" look — the zebra background and the first/last-cell end
 * caps live on `<td>`, not `<tr>`, exactly as the ported CSS does, because a
 * background painted on `<tr>` doesn't clip to a child `<td>`'s border-radius
 * in table layout. `TR` marks itself `group` (+ `data-selected` when
 * selected) and every `TD` reads that via `group-even:`/
 * `group-data-[selected]:` — verified against this repo's own Tailwind
 * config to compile to the expected `:nth-child(even)`/`[data-selected]`
 * selectors, not assumed.
 *
 * `CellMain`'s `thumb` slot is deliberately a bare `ReactNode`, not a photo
 * URL: the same cell shape backs three different leading visuals across the
 * app — a square `Thumb` photo box (My ads), a round `Avatar` chip (Leads,
 * Coworkers), or nothing at all (Publish status uses `icon` instead). This
 * primitive lays out whichever one the screen hands it; it doesn't impose a
 * shape.
 */
import type { ReactNode } from "react";
import clsx from "clsx";
import type { IconComponent } from "./icons";

export function Table({ children, className }: { children: ReactNode; className?: string }) {
  return (
    <div className="overflow-x-auto">
      <table
        className={clsx("w-full border-separate border-spacing-0 text-body", className)}
      >
        {children}
      </table>
    </div>
  );
}

export function THead({ children }: { children: ReactNode }) {
  return <thead>{children}</thead>;
}

export function TH({
  align = "left",
  children,
}: {
  align?: "left" | "right";
  children?: ReactNode;
}) {
  return (
    <th
      className={clsx(
        "whitespace-nowrap px-3 pb-3 pt-2 text-tiny font-semibold uppercase tracking-caps text-ink-2",
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
      // A bare <tr onClick> is invisible to a keyboard-only agent — no
      // native focus, no Enter/Space activation. My ads' row-select (the
      // bg-accent-tint pairing PLAN.md §1 names for that screen) has to be
      // reachable the same way a mouse click reaches it, not just visually
      // present once you happen to be there with a pointer.
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
      data-selected={selected ? "" : undefined}
      className={clsx(
        "group",
        onClick && "cursor-pointer focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-inset focus-visible:ring-dark",
      )}
    >
      {children}
    </tr>
  );
}

export function TD({
  align = "left",
  children,
  className,
}: {
  align?: "left" | "right";
  children?: ReactNode;
  className?: string;
}) {
  return (
    <td
      className={clsx(
        "px-3 py-2.5 align-middle text-body text-ink",
        "group-even:bg-surface-inner group-data-[selected]:bg-accent-tint",
        "first:rounded-l-input last:rounded-r-input",
        align === "right" ? "text-right" : "text-left",
        className,
      )}
    >
      {children}
    </td>
  );
}

/** The 36px square photo box (`.thumb`) — My ads' and Coworkers' listing art. */
export function Thumb({
  src,
  alt,
  className,
}: {
  src?: string | null;
  alt: string;
  className?: string;
}) {
  return (
    <div
      role="img"
      aria-label={alt}
      className={clsx("h-9 w-9 shrink-0 rounded-chip bg-surface-inner bg-cover bg-center", className)}
      style={src ? { backgroundImage: `url(${src})` } : undefined}
    />
  );
}

export function CellMain({
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
    <div className="flex min-w-0 items-center gap-[11px]">
      {thumb ?? (Icon ? <Icon size={18} className="shrink-0 text-ink-2" /> : null)}
      <div className="min-w-0">
        <div className="truncate text-body font-semibold leading-[1.3] text-ink">{title}</div>
        {sub != null ? (
          <span className="block text-tiny leading-[1.3] text-ink-2">{sub}</span>
        ) : null}
      </div>
    </div>
  );
}

/**
 * The sparse-table terminal "create" row (`tr.ghost`) — a dashed, accent-
 * tinted call to action that reads as the table's own last row rather than
 * a button bolted on below it. `colSpan` must match the table's real column
 * count or the dashed pill won't span the full width.
 */
export function GhostRow({
  colSpan,
  icon: Icon,
  children,
  onClick,
}: {
  colSpan: number;
  icon?: IconComponent;
  children: ReactNode;
  onClick?: () => void;
}) {
  return (
    <tr>
      <td colSpan={colSpan} className="p-0">
        <button
          type="button"
          onClick={onClick}
          className="mt-2 flex w-full items-center justify-center gap-2 rounded-input border-1.5 border-dashed border-black/[.16] bg-accent-tint px-3.5 py-3.5 text-body font-semibold text-accent-text transition-colors hover:bg-accent"
        >
          {Icon ? <Icon size={14} /> : null}
          {children}
        </button>
      </td>
    </tr>
  );
}
