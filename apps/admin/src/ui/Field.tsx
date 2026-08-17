/**
 * Field/Input/Select/Textarea — the control room's form controls, built on
 * the mockup's `.search`/`.filt` pill geometry (sunk fill, 1px line, 8px
 * radius) rather than the console's larger 14px "editable pill". There is
 * very little data entry on this surface — a login, a search box, a role
 * select, a rejection reason — so these are deliberately compact rather than
 * comfortable.
 *
 * `Field`'s `<label>` wraps its `children` (implicit label association)
 * instead of taking an `id`/`htmlFor` pair: this component doesn't control
 * the id its child control gets, and an implicit label works for any single
 * form control without one.
 *
 * `Select` hides the native arrow and draws the caret itself so a select and
 * an input read as the same pill; the caret is `pointer-events-none` so it
 * never steals the click that should open the native dropdown.
 */
import { forwardRef, type ReactNode } from "react";
import type {
  InputHTMLAttributes,
  SelectHTMLAttributes,
  TextareaHTMLAttributes,
} from "react";
import clsx from "clsx";
import { CaretDownIcon, MagnifyingGlassIcon } from "./icons";

export function Field({
  label,
  hint,
  children,
  className,
}: {
  label: ReactNode;
  hint?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={className}>
      <label className="block">
        <span className="mb-1.5 block text-caps font-bold uppercase tracking-caps-wide text-muted">
          {label}
        </span>
        {children}
      </label>
      {hint != null ? <p className="mt-1.5 text-tiny leading-relaxed text-muted">{hint}</p> : null}
    </div>
  );
}

// Shared by all three controls so they read as one family — same radius,
// fill, border and text size.
const controlBase =
  "w-full rounded-control border border-line bg-sunk px-2.5 py-1.5 text-small text-ink placeholder:text-faint focus:outline-none focus-visible:ring-2 focus-visible:ring-acc";

export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(
  function Input({ className, ...props }, ref) {
    return <input ref={ref} className={clsx(controlBase, "min-h-[31px]", className)} {...props} />;
  },
);

export const Select = forwardRef<HTMLSelectElement, SelectHTMLAttributes<HTMLSelectElement>>(
  function Select({ className, children, ...props }, ref) {
    return (
      <div className="relative">
        <select
          ref={ref}
          className={clsx(controlBase, "min-h-[31px] appearance-none pr-8", className)}
          {...props}
        >
          {children}
        </select>
        <CaretDownIcon
          size={11}
          weight="fill"
          className="pointer-events-none absolute right-2.5 top-1/2 -translate-y-1/2 text-muted"
        />
      </div>
    );
  },
);

export const Textarea = forwardRef<HTMLTextAreaElement, TextareaHTMLAttributes<HTMLTextAreaElement>>(
  function Textarea({ className, ...props }, ref) {
    return (
      <textarea
        ref={ref}
        className={clsx(controlBase, "min-h-[76px] resize-y leading-relaxed", className)}
        {...props}
      />
    );
  },
);

/**
 * The topbar's search box (`.search`). Its own component rather than an
 * `Input` with an icon slot because it is the one control on this surface
 * that is always 250px wide, always carries the magnifier, and is always
 * about finding a record by name, email or UUID.
 */
export const SearchInput = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(
  function SearchInput({ className, ...props }, ref) {
    return (
      <div
        className={clsx(
          "flex items-center gap-2 rounded-control border border-line bg-sunk px-2.5 py-1 focus-within:ring-2 focus-within:ring-acc",
          className,
        )}
      >
        <MagnifyingGlassIcon size={13} className="shrink-0 text-muted" />
        <input
          ref={ref}
          type="search"
          className="min-w-0 flex-1 bg-transparent text-small text-ink placeholder:text-muted focus:outline-none"
          {...props}
        />
      </div>
    );
  },
);
