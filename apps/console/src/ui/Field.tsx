/**
 * Field/PillInput/PillSelect/PillTextarea — F's `.f`/`.in` form primitives,
 * ported as real form controls rather than the prototype's non-interactive
 * `<div class="in">` fakes (the ground rule against fake affordance applies
 * doubly to a form). `PillSelect` hides the native arrow and draws F's own
 * caret glyph in its place so every field in a `.fgrid` still reads as one
 * consistent `rounded-input` pill — the caret is `pointer-events-none` so it
 * never steals the click that should open the native dropdown.
 *
 * `Field`'s `<label>` wraps its `children` (implicit label association)
 * instead of taking an `id`/`htmlFor` pair — this component doesn't control
 * the id its child control gets, and an implicit label works for any single
 * form control without one.
 */
import { forwardRef, type ReactNode } from "react";
import type {
  InputHTMLAttributes,
  SelectHTMLAttributes,
  TextareaHTMLAttributes,
} from "react";
import clsx from "clsx";
import { CaretDownIcon } from "./icons";

export function Field({
  label,
  full,
  hint,
  children,
}: {
  label: ReactNode;
  full?: boolean;
  hint?: ReactNode;
  children: ReactNode;
}) {
  return (
    <div className={clsx(full && "col-span-full")}>
      <label className="block">
        <span className="mb-1.5 block text-tiny font-medium tracking-[0.02em] text-ink-2">
          {label}
        </span>
        {children}
      </label>
      {hint != null ? (
        <p className="mt-1.5 text-caption leading-[1.55] text-ink-2">{hint}</p>
      ) : null}
    </div>
  );
}

// Shared with PillSelect/PillTextarea so the three controls read as one
// family — same radius, fill, border and text size (F's "editable" pill).
const controlBase =
  "min-h-[41px] w-full rounded-input border border-hairline bg-pill px-3.5 py-2.5 text-body text-ink placeholder:text-ink-2 focus:outline-none focus-visible:ring-2 focus-visible:ring-dark";

export const PillInput = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(
  function PillInput({ className, ...props }, ref) {
    return <input ref={ref} className={clsx(controlBase, className)} {...props} />;
  },
);

export const PillSelect = forwardRef<
  HTMLSelectElement,
  SelectHTMLAttributes<HTMLSelectElement>
>(function PillSelect({ className, children, ...props }, ref) {
  return (
    <div className="relative">
      <select
        ref={ref}
        className={clsx(controlBase, "appearance-none pr-9", className)}
        {...props}
      >
        {children}
      </select>
      <CaretDownIcon
        size={12}
        weight="fill"
        className="pointer-events-none absolute right-3.5 top-1/2 -translate-y-1/2 text-ink-2"
      />
    </div>
  );
});

export const PillTextarea = forwardRef<
  HTMLTextAreaElement,
  TextareaHTMLAttributes<HTMLTextAreaElement>
>(function PillTextarea({ className, ...props }, ref) {
  return (
    <textarea
      ref={ref}
      className={clsx(controlBase, "min-h-[96px] resize-y leading-[1.6]", className)}
      {...props}
    />
  );
});
