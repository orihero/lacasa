/**
 * IconButton — the topbar's square controls and any icon-only action.
 *
 * `label` is REQUIRED, not optional, and is used as both `aria-label` and
 * `title`: a surface whose buttons lock other people's accounts must not ship a
 * control a screen reader announces as nothing. That is the whole reason this
 * primitive exists rather than a bare `<MuiIconButton>`.
 *
 * `dot` renders a notification pip and is `aria-hidden` — it is a visual
 * echo of something the page already says in text. The topbar's bell
 * deliberately does NOT pass it: there is no notifications model behind this
 * surface, and a pip would be a fabricated "something needs you" on the one
 * screen whose entire job is telling an admin what needs them.
 */
import MuiIconButton from "@mui/material/IconButton";
import type { ButtonHTMLAttributes } from "react";
import type { IconComponent } from "./icons";

export interface IconButtonProps
  extends Omit<ButtonHTMLAttributes<HTMLButtonElement>, "color"> {
  icon: IconComponent;
  /** Used as both `aria-label` and `title`. Required. */
  label: string;
  dot?: boolean;
  size?: "sm";
}

export function IconButton({
  icon: Icon,
  label,
  dot,
  size,
  type = "button",
  className,
  ...props
}: IconButtonProps) {
  const sm = size === "sm";
  return (
    <MuiIconButton
      type={type}
      aria-label={label}
      title={label}
      className={className}
      sx={{
        position: "relative",
        flex: "none",
        // Square, like everything else here — the theme sets
        // `shape.borderRadius: 0` and MUI's icon buttons are round by default.
        borderRadius: 0,
        width: sm ? "30px" : "36px",
        height: sm ? "30px" : "36px",
        // apps/web's filter-control box, at icon size.
        border: "1px solid #e0e0e0",
        backgroundColor: "#ffffff",
        color: "#8d99ae",
        "&:hover": { backgroundColor: "#eeeeee" },
        "&.Mui-disabled": { borderColor: "#e0e0e0" },
      }}
      {...props}
    >
      <Icon size={sm ? 14 : 16} aria-hidden="true" />
      {dot ? (
        <span
          aria-hidden="true"
          style={{
            position: "absolute",
            top: "5px",
            right: "5px",
            width: "6px",
            height: "6px",
            borderRadius: "50%",
            backgroundColor: "#fece51",
          }}
        />
      ) : null}
    </MuiIconButton>
  );
}
