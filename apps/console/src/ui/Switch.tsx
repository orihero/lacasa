/**
 * Switch — F's `.sw` toggle. PLAN.md §3.8 keeps the Connected accounts
 * screen's four status switches read-only ("Status switches are read-only
 * indicators", verbatim) — they mirror server-side connection state, not a
 * writable field — so `readOnly` renders an inert `<span role="switch"
 * aria-disabled>` rather than a `<button>` a keyboard user could tab to and
 * "toggle" with no effect.
 */
import clsx from "clsx";

export function Switch({
  checked,
  onChange,
  readOnly,
  label,
}: {
  checked: boolean;
  onChange?: (checked: boolean) => void;
  readOnly?: boolean;
  label: string;
}) {
  const track = clsx(
    "relative inline-block h-6 w-10 shrink-0 rounded-full border",
    checked ? "border-accent bg-accent" : "border-hairline bg-surface-inner",
    readOnly && "opacity-85",
  );
  const knob = (
    <span
      aria-hidden="true"
      className={clsx(
        "absolute top-[2px] h-[18px] w-[18px] rounded-full border bg-white transition-[left]",
        checked ? "left-[18px] border-transparent" : "left-[2px] border-hairline",
      )}
    />
  );

  if (readOnly) {
    return (
      <span role="switch" aria-checked={checked} aria-disabled="true" aria-label={label} className={track}>
        {knob}
      </span>
    );
  }

  return (
    <button
      type="button"
      role="switch"
      aria-checked={checked}
      aria-label={label}
      onClick={() => onChange?.(!checked)}
      className={clsx(track, "transition-colors")}
    >
      {knob}
    </button>
  );
}
