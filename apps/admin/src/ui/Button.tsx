/**
 * Button — MUI's Button wearing apps/web's five-line accent block.
 *
 * apps/web has no shared Button: the rule
 *
 *   button { padding: 12px 24px; background-color: #fece51; cursor: pointer; border: none; }
 *
 * is repeated verbatim in fourteen SCSS files (web-design-contract.md §2.1),
 * and inside MUI surfaces it switches to `<Button variant="contained">`. This
 * app is MUI end to end, so the rule lives once, in the theme, and this
 * component's only job is to map a CONSEQUENCE onto it.
 *
 * Which variant a control gets is a statement about consequence, not emphasis:
 *
 *   · `ghost`   — the default, and correctly most of them: reads, filters,
 *                 refreshes, "Try again", "Cancel". apps/web's quiet control is
 *                 the filter bar's `1px solid #e0e0e0` box, so that is what a
 *                 ghost button is. (Inside an MUI dialog apps/web's cancel is
 *                 likewise an outlined MUI Button, not the page-body navy.)
 *   · `accent`  — La Casa yellow. The one "do the main thing here" control per
 *                 screen.
 *   · `approve` — green. Grants something. The only colour an admin should ever
 *                 be able to hit twice without re-reading the row.
 *   · `danger`  — apps/web's `.delete-btn` red. IRREVERSIBLE: rejecting an
 *                 application, demoting an admin. Never for merely-unusual
 *                 actions — if it starts appearing on reversible controls it
 *                 stops carrying the warning.
 *
 * `type` defaults to `"button"`, so no button in this app can submit a form by
 * accident. `icon`/`iconRight` take a component reference, not an element, so
 * every glyph in a button is 14px without the call site saying so.
 */
import MuiButton from "@mui/material/Button";
import type { SxProps, Theme } from "@mui/material/styles";
import type { ButtonHTMLAttributes, ReactNode } from "react";
import type { IconComponent } from "./icons";

export type ButtonVariant = "ghost" | "accent" | "approve" | "danger";

const MUI_VARIANT: Record<ButtonVariant, "outlined" | "contained"> = {
  ghost: "outlined",
  accent: "contained",
  approve: "contained",
  danger: "contained",
};

const MUI_COLOR: Record<ButtonVariant, "inherit" | "primary" | "error"> = {
  ghost: "inherit",
  accent: "primary",
  approve: "inherit",
  danger: "error",
};

/**
 * Only what the theme cannot already say. `accent` and `danger` are empty
 * because `containedPrimary` (yellow on black) and `palette.error`
 * (rgb(216, 72, 53)) are already the theme's — restating them here is how one
 * yellow becomes two.
 */
const VARIANT_SX: Record<ButtonVariant, SxProps<Theme>> = {
  ghost: {
    // apps/web's filter-control border, on the white panel, with the list-row
    // hover underneath it. 11px/23px rather than 12px/24px so an outlined
    // button and a contained one line up to the same box once the 1px border
    // is counted.
    padding: "11px 23px",
    border: "1px solid #e0e0e0",
    backgroundColor: "#ffffff",
    color: "#2b2d42",
    "&:hover": { backgroundColor: "#eeeeee", borderColor: "#e0e0e0" },
  },
  accent: {},
  approve: {
    // StatusCell's `accepted` green. apps/web has no green button of its own;
    // this is its green, in the button box every other button here uses.
    backgroundColor: "#28a745",
    color: "#ffffff",
    "&:hover": { backgroundColor: "#28a745" },
  },
  danger: {},
};

/**
 * All native button props except `color`: React types it as the legacy HTML
 * string attribute, MUI types it as its own palette union, and the two cannot
 * be spread onto the same element. The variant decides the colour here anyway.
 */
export interface ButtonProps extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "color"> {
  variant?: ButtonVariant;
  icon?: IconComponent;
  iconRight?: IconComponent;
  children?: ReactNode;
}

export function Button({
  variant = "ghost",
  icon: Icon,
  iconRight: IconRight,
  children,
  type = "button",
  className,
  ...props
}: ButtonProps) {
  return (
    <MuiButton
      type={type}
      variant={MUI_VARIANT[variant]}
      color={MUI_COLOR[variant]}
      className={className}
      sx={{ gap: "8px", ...VARIANT_SX[variant] }}
      {...props}
    >
      {Icon ? <Icon size={14} aria-hidden="true" /> : null}
      {children}
      {IconRight ? <IconRight size={14} aria-hidden="true" /> : null}
    </MuiButton>
  );
}
