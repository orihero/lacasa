/**
 * Field / Input / Select / SearchInput — the form controls.
 *
 * These are NATIVE elements, not MUI's `TextField`/`Select`, and that is the
 * house style rather than a shortcut: apps/web's forms are `register()`ed
 * native inputs, and its filter bar is explicitly "native selects, no MUI
 * Autocomplete" (web-design-contract.md §8.1/§8.4). The geometry below is that
 * filter bar's, quoted: `padding: 10px; border: 1px solid #e0e0e0;
 * border-radius: 5px; font-size: 14px`, a 10px label above the control, and the
 * accent-yellow focus border every input in apps/web takes.
 *
 * There is very little data entry on this surface — a login, a search box, a
 * role select — which is also why `Textarea` is not ported: the deleted app
 * exported one and no screen ever rendered it (PRECEDENCE.md, "Drop the dead
 * exports").
 *
 * `Field`'s `<label>` WRAPS its children (implicit association) rather than
 * taking an `id`/`htmlFor` pair, because this component does not control the id
 * its child control gets, and an implicit label works for any single control.
 * The label text is used verbatim — apps/web appends a colon (`Full name:`) and
 * this app does not, because the label text here is copy the specs pin and the
 * screens' tests select on.
 */
import { forwardRef, type ReactNode } from "react";
import type { InputHTMLAttributes, SelectHTMLAttributes } from "react";
import { Search } from "./icons";
import "./field.scss";

export function Field({
  label,
  hint,
  children,
  className,
}: {
  label: ReactNode;
  /** A quiet line under the control — why this filter exists, what it accepts. */
  hint?: ReactNode;
  children: ReactNode;
  className?: string;
}) {
  return (
    <div className={className ? `field ${className}` : "field"}>
      <label className="field__label">
        <span className="field__label-text">{label}</span>
        {children}
      </label>
      {hint != null ? <p className="field__hint">{hint}</p> : null}
    </div>
  );
}

export const Input = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(
  function Input({ className, ...props }, ref) {
    return (
      <input
        ref={ref}
        className={className ? `field__control ${className}` : "field__control"}
        {...props}
      />
    );
  },
);

/**
 * The native caret is kept rather than redrawn. The deleted app hid it and drew
 * its own, which then had to be `pointer-events: none` so it did not steal the
 * click that opens the dropdown; a native select has no such failure mode, and
 * native selects are what apps/web's filter bar uses.
 */
export const Select = forwardRef<HTMLSelectElement, SelectHTMLAttributes<HTMLSelectElement>>(
  function Select({ className, children, ...props }, ref) {
    return (
      <select
        ref={ref}
        className={
          className
            ? `field__control field__control--select ${className}`
            : "field__control field__control--select"
        }
        {...props}
      >
        {children}
      </select>
    );
  },
);

/**
 * Its own component rather than an `Input` with an icon slot: it is the one
 * control on this surface that always carries the magnifier and is always about
 * finding a record by name, email or UUID. `type="search"` so the browser
 * offers its own clear affordance, and the focus ring lives on the wrapper so
 * the box and the glyph light up together.
 */
export const SearchInput = forwardRef<HTMLInputElement, InputHTMLAttributes<HTMLInputElement>>(
  function SearchInput({ className, ...props }, ref) {
    return (
      <div className={className ? `search-input ${className}` : "search-input"}>
        <Search size={14} aria-hidden="true" />
        <input ref={ref} type="search" className="search-input__control" {...props} />
      </div>
    );
  },
);
