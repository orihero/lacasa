/**
 * FilterChip — the small "what is this list narrowed to" pill.
 *
 * It renders a REAL `<button>` only when `onClick` is given, and an inert
 * `<span>` otherwise. A fake affordance on a surface where the real controls
 * lock accounts is worse than a missing one: an admin who clicks a chip that
 * looks like a filter and gets nothing has no way to tell that from a filter
 * that ran and matched everything.
 *
 * `active` means the filter is actually narrowing the list. That is the
 * difference between "nothing is waiting on you" and "you filtered the queue
 * away" — four rows on screen mean opposite things in the two cases — so an
 * active chip takes the accent yellow, and carries `aria-pressed` when it is
 * interactive.
 */
import Chip from "@mui/material/Chip";
import type { ReactNode } from "react";
import type { IconComponent } from "./icons";

export function FilterChip({
  icon: Icon,
  children,
  onClick,
  active,
}: {
  icon?: IconComponent;
  children: ReactNode;
  /** Omit for a read-only chip; it then renders as a `<span>`, not a button. */
  onClick?: () => void;
  active?: boolean;
}) {
  const label = (
    <>
      {Icon ? <Icon size={12} aria-hidden="true" /> : null}
      {children}
    </>
  );

  const sx = {
    height: "auto",
    // 5px is apps/web's filter-control radius (`.filter .item input, select`).
    borderRadius: "5px",
    border: `1px solid ${active ? "#fece51" : "#e0e0e0"}`,
    backgroundColor: active ? "#fece51" : "#ffffff",
    color: active ? "#000000" : "#2b2d42",
    "& .MuiChip-label": {
      display: "inline-flex",
      alignItems: "center",
      gap: "6px",
      padding: "7px 10px",
      fontSize: "12px",
      fontWeight: 600,
    },
    ...(onClick
      ? { "&:hover": { backgroundColor: active ? "#fece51" : "#eeeeee" } }
      : {}),
  };

  if (onClick) {
    return (
      <Chip
        component="button"
        type="button"
        clickable
        onClick={onClick}
        aria-pressed={active}
        label={label}
        sx={sx}
      />
    );
  }
  return <Chip component="span" label={label} sx={sx} />;
}
