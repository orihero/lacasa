/**
 * Button — the control room's `.btn` (mockups/build/web-admin.src.html
 * `.btn`/`.btn--a`/`.btn--g`/`.btn--ok`/`.btn--x`). Four variants, and which
 * one a control gets is a statement about consequence, not about emphasis:
 *
 *   · `ghost`   — the default. Reads, filters, exports, "cancel". Most
 *                 buttons on this surface are this, and that is correct.
 *   · `accent`  — amber. The one "do the main thing here" control per screen.
 *   · `approve` — green. Grants something (approve an application). Green
 *                 because it is the only colour an admin should ever be able
 *                 to hit twice without re-reading the row.
 *   · `danger`  — magenta. IRREVERSIBLE. Rejecting an application, demoting
 *                 the last admin, anything that cannot be undone from this
 *                 UI. Never use it for merely-unusual actions; if magenta
 *                 starts appearing on reversible controls it stops carrying
 *                 the warning, which is the whole reason the brand colour is
 *                 quarantined to this variant (see tailwind.config.js).
 *
 * `icon`/`iconRight` take an `IconComponent` reference, not a pre-built
 * element, so this component controls size uniformly. Weight defaults to
 * Phosphor's "regular" — a call site that needs a specific weight passes a
 * small inline wrapper (`icon={(p) => <CheckIcon weight="bold" {...p} />}`)
 * rather than this component guessing a weight per glyph.
 */
import type { ButtonHTMLAttributes, ReactNode } from "react";
import { cva, type VariantProps } from "class-variance-authority";
import clsx from "clsx";
import type { IconComponent } from "./icons";

const button = cva(
  "inline-flex items-center justify-center gap-1.5 whitespace-nowrap rounded-control border px-[13px] py-1.5 text-body font-semibold transition-colors focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-acc focus-visible:ring-offset-2 focus-visible:ring-offset-app disabled:cursor-not-allowed disabled:opacity-50",
  {
    variants: {
      variant: {
        ghost: "border-line bg-sunk text-ink hover:bg-card",
        accent: "border-transparent bg-acc text-on-acc hover:bg-acc/90",
        approve: "border-transparent bg-ok text-on-ok hover:bg-ok/90",
        danger: "border-danger bg-danger-soft text-danger hover:bg-danger/25",
      },
    },
    defaultVariants: { variant: "ghost" },
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
      {Icon ? <Icon size={13} className="shrink-0" /> : null}
      {children}
      {IconRight ? <IconRight size={13} className="shrink-0" /> : null}
    </button>
  );
}
