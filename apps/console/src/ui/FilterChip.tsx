/**
 * FilterChip — F's `.filt` pill. The prototype's filter chips ("Chilonzor",
 * "Newest first", "All stages") are inert `<span>`s wired to nothing; most
 * of them stay exactly that until a screen actually wires filtering, so this
 * renders a `<button>` only when `onClick` is given and a plain `<span>`
 * otherwise — never a clickable-looking control with no click handler.
 */
import type { ReactNode } from "react";
import clsx from "clsx";
import type { IconComponent } from "./icons";

export function FilterChip({
  icon: Icon,
  children,
  onClick,
}: {
  icon?: IconComponent;
  children: ReactNode;
  onClick?: () => void;
}) {
  const className = clsx(
    "inline-flex items-center gap-[7px] whitespace-nowrap rounded-full border border-hairline bg-pill px-[15px] py-[9px] text-label text-ink",
    onClick && "transition-colors hover:bg-surface-inner",
  );
  const content = (
    <>
      {Icon ? <Icon size={13} className="shrink-0 text-ink-2" /> : null}
      {children}
    </>
  );

  if (onClick) {
    return (
      <button type="button" onClick={onClick} className={className}>
        {content}
      </button>
    );
  }
  return <span className={className}>{content}</span>;
}
