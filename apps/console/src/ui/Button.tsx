/**
 * Button — F's unified `.btn` pill (f-components.css `.btn`/`.btn--p`/
 * `.btn--dark`/`.btn--d`). `primary` is the one accent-discipline CTA
 * variant (`bg-accent text-accent-text`) — PLAN.md §1's table names exactly
 * which button on each screen is allowed to be it; every other button on
 * that screen stays `default`/`dark`/`danger`.
 *
 * `icon`/`iconRight` take an `IconComponent` reference, not a pre-built
 * element, so this component controls size uniformly. Weight defaults to
 * Phosphor's own "regular" — a screen that needs a specific weight (a
 * bold check, a filled paper-plane) passes a small inline wrapper
 * (`icon={(p) => <CheckIcon weight="bold" {...p} />}`) rather than this
 * component guessing a weight per glyph.
 */
import type { ButtonHTMLAttributes, ReactNode } from "react";
import { cva, type VariantProps } from "class-variance-authority";
import clsx from "clsx";
import type { IconComponent } from "./icons";

const button = cva(
  "inline-flex items-center justify-center gap-[7px] whitespace-nowrap rounded-full border px-[17px] py-[10px] text-body font-semibold transition-colors disabled:cursor-not-allowed disabled:opacity-50",
  {
    variants: {
      variant: {
        default: "border-hairline bg-pill text-ink hover:bg-surface-inner",
        primary: "border-transparent bg-accent text-accent-text hover:bg-accent-tint",
        dark: "border-dark bg-dark text-dark-text hover:bg-ink",
        danger: "border-hairline bg-pill text-err hover:bg-err-soft",
      },
    },
    defaultVariants: { variant: "default" },
  },
);

export interface ButtonProps
  extends ButtonHTMLAttributes<HTMLButtonElement>,
    VariantProps<typeof button> {
  icon?: IconComponent;
  iconRight?: IconComponent;
  children?: ReactNode;
}

export function Button({
  variant,
  icon: Icon,
  iconRight: IconRight,
  children,
  className,
  type = "button",
  ...props
}: ButtonProps) {
  return (
    <button type={type} className={clsx(button({ variant }), className)} {...props}>
      {Icon ? <Icon size={14} className="shrink-0" /> : null}
      {children}
      {IconRight ? <IconRight size={14} className="shrink-0" /> : null}
    </button>
  );
}
