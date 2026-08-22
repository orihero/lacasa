/**
 * Checkbox — F's round `.cb` (the Listing editor's per-channel publish
 * toggle). Keeps its check glyph mounted at all times and swaps
 * `text-transparent`/`text-dark-text` rather than conditionally rendering
 * it, matching the prototype's opacity-swap (`.cb .i{opacity:0}` /
 * `.cb.is-on .i{opacity:1}`) so the control never changes size when it
 * flips.
 */
import clsx from "clsx";
import { CheckIcon } from "./icons";

export function Checkbox({
  checked,
  onChange,
  label,
  disabled,
}: {
  checked: boolean;
  onChange?: (checked: boolean) => void;
  label: string;
  disabled?: boolean;
}) {
  return (
    <button
      type="button"
      role="checkbox"
      aria-checked={checked}
      aria-label={label}
      disabled={disabled}
      onClick={() => onChange?.(!checked)}
      className={clsx(
        "inline-flex h-[26px] w-[26px] shrink-0 items-center justify-center rounded-full border transition-colors disabled:cursor-not-allowed disabled:opacity-50",
        checked ? "border-dark bg-dark text-dark-text" : "border-hairline bg-pill text-transparent",
      )}
    >
      <CheckIcon size={12} weight="bold" />
    </button>
  );
}
