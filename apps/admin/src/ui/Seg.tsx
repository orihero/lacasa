/**
 * Seg — the "pick one of N" control: Applications' Pending/Approved/Rejected,
 * Users' All/Buyers/Agents/Coworkers, Audit's event-type filter.
 *
 * Built on MUI's `ToggleButtonGroup`, which gives the semantics the screens'
 * tests select on for free: a `role="group"` carrying the group's accessible
 * name, and real `<button>`s each carrying `aria-pressed`. (apps/web's own
 * segmented vocabulary, `register.jsx`'s `.seg` pill, is class toggling with no
 * semantics at all — the look is worth borrowing, the markup is not.)
 *
 * `label` is required: "Application status" and "Role" are what tell a screen
 * reader user which of the three groups on a screen they have landed in.
 *
 * `hot` is a per-Seg flag rather than a per-option one. Exactly one segment can
 * be "the queue", and it is whichever one is selected while `hot` is on — the
 * accent yellow then says "this is the tab that has work in it", which is the
 * same thing the yellow says everywhere else on this surface.
 *
 * Changing the selection re-runs the query for the new filter, and every filter
 * combination is its own cache entry, so the table drops to its skeleton rather
 * than holding the previous tab's rows. That is deliberate (PRECEDENCE.md):
 * showing the last tab's rows under a new tab's heading is how an admin acts on
 * the wrong row. Do not add `placeholderData: keepPreviousData`.
 */
import ToggleButton from "@mui/material/ToggleButton";
import ToggleButtonGroup from "@mui/material/ToggleButtonGroup";
import type { ReactNode } from "react";

export interface SegOption<T extends string> {
  value: T;
  label: ReactNode;
}

export function Seg<T extends string>({
  options,
  value,
  onChange,
  hot,
  label,
}: {
  options: ReadonlyArray<SegOption<T>>;
  value: T;
  onChange: (value: T) => void;
  hot?: boolean;
  /** Names the group for screen readers ("Application status", "Role"). */
  label: string;
}) {
  return (
    <ToggleButtonGroup
      exclusive
      value={value}
      // MUI hands back `null` when the pressed option was already selected.
      // A segmented filter always has exactly one answer, so that is a no-op
      // rather than a way to clear the filter.
      onChange={(_event, next: unknown) => {
        if (typeof next === "string") onChange(next as T);
      }}
      aria-label={label}
      sx={{
        // apps/web's filter-control box, holding the options in the app canvas
        // grey so the selected one reads as lifted out of the track.
        border: "1px solid #e0e0e0",
        backgroundColor: "#f5f6fa",
        padding: "3px",
        gap: "3px",
        "& .MuiToggleButtonGroup-grouped": {
          margin: 0,
          border: "none",
          borderRadius: 0,
          padding: "6px 14px",
          fontSize: "13px",
          fontWeight: 600,
          color: "#8d99ae",
          "&:hover": { backgroundColor: "#eeeeee" },
          "&.Mui-selected": {
            backgroundColor: hot ? "#fece51" : "#ffffff",
            color: "#000000",
            "&:hover": { backgroundColor: hot ? "#fece51" : "#ffffff" },
          },
        },
      }}
    >
      {options.map((option) => (
        <ToggleButton key={option.value} value={option.value}>
          {option.label}
        </ToggleButton>
      ))}
    </ToggleButtonGroup>
  );
}
