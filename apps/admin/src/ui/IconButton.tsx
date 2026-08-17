/**
 * IconButton — the topbar's square `.ib` control and every icon-only row
 * action. `label` is required, not optional: the mockup fakes these as bare
 * `<span class="i">` glyphs with no accessible name at all, and a surface
 * whose buttons lock accounts must not ship a control a screen reader
 * announces as nothing.
 *
 * `dot` renders the notification pip (`.ib__d`). Its ring is `ring-2
 * ring-card` — a solid, zero-blur "cut a gap in the background" trick rather
 * than an elevation shadow, so it reads cleanly against the dark canvas
 * whatever surface the button sits on.
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
        "relative inline-grid shrink-0 place-items-center rounded-control border border-line bg-sunk text-ink-2 transition-colors hover:text-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-acc",
        sm ? "h-[25px] w-[25px]" : "h-[29px] w-[29px]",
        className,
      )}
      {...props}
    >
      <Icon size={sm ? 12 : 14} />
      {dot ? (
        <span
          aria-hidden="true"
          className="absolute right-[5px] top-[5px] h-1.5 w-1.5 rounded-full bg-acc ring-2 ring-card"
        />
      ) : null}
    </button>
  );
}
