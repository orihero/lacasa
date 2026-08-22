/**
 * IconButton — F's round `.icon-btn` (f-components.css), the topbar's bell/
 * gear/search-adjacent controls and every rail/table icon-only action.
 * `label` is required, not optional: the prototype fakes these as bare
 * `<span class="i">` glyphs with no accessible name at all, and the real app
 * must not ship an icon-only control a screen reader announces as nothing.
 *
 * `dot` renders the bell's accent unread pip (`.ndot`) — note the ring
 * around it is `ring-2 ring-pill`, not a `shadow-*` utility: it's a solid,
 * zero-blur "cut a gap in the background" trick, not an elevation shadow,
 * so it doesn't violate the flat-depth rule.
 */
import type { ButtonHTMLAttributes } from "react";
import clsx from "clsx";
import type { IconComponent } from "./icons";

export interface IconButtonProps extends ButtonHTMLAttributes<HTMLButtonElement> {
  icon: IconComponent;
  label: string;
  dot?: boolean;
  size?: "sm";
}

export function IconButton({
  icon: Icon,
  label,
  dot,
  size,
  className,
  type = "button",
  ...props
}: IconButtonProps) {
  const sm = size === "sm";
  return (
    <button
      type={type}
      aria-label={label}
      title={label}
      className={clsx(
        "relative inline-flex shrink-0 items-center justify-center rounded-full border border-hairline bg-pill text-ink transition-colors hover:bg-surface-inner",
        sm ? "h-8 w-8" : "h-10 w-10",
        className,
      )}
      {...props}
    >
      <Icon size={sm ? 14 : 17} />
      {dot ? (
        <span
          aria-hidden="true"
          className="absolute right-[10px] top-[9px] h-[7px] w-[7px] rounded-full bg-accent ring-2 ring-pill"
        />
      ) : null}
    </button>
  );
}
