/**
 * FilterChip — the control room's `.filt` pill. The mockup's chips ("Any
 * status", "All actors", "Last 24 h") are inert `<span>`s wired to nothing.
 * Rather than ship a control that looks clickable and isn't, this renders a
 * real `<button>` only when `onClick` is given and a plain `<span>`
 * otherwise — a fake affordance on a surface where the real controls lock
 * accounts is worse than a missing one.
 *
 * `active` dims up the border and text when a filter is actually narrowing
 * the list, so an admin can tell at a glance that the 4 rows on screen are 4
 * rows of a filtered set rather than 4 rows total. That distinction is the
 * difference between "nothing is waiting" and "you filtered the queue away".
 */
import type { ReactNode } from "react";
import clsx from "clsx";
import type { IconComponent } from "./icons";

export function FilterChip({
  icon: Icon,
  children,
  onClick,
  active,
}: {
  icon?: IconComponent;
  children: ReactNode;
  onClick?: () => void;
  active?: boolean;
}) {
  const className = clsx(
    "inline-flex items-center gap-1.5 whitespace-nowrap rounded-control border px-2.5 py-1 text-small font-medium",
    active ? "border-acc-line bg-acc-soft text-acc" : "border-line bg-sunk text-ink",
    onClick &&
      "transition-colors hover:border-line focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-acc",
    onClick && !active && "hover:bg-card",
  );
  const content = (
    <>
      {Icon ? (
        <Icon size={12} className={clsx("shrink-0", active ? "text-acc" : "text-muted")} />
      ) : null}
      {children}
    </>
  );

  if (onClick) {
    return (
      <button type="button" onClick={onClick} aria-pressed={active} className={className}>
        {content}
      </button>
    );
  }
  return <span className={className}>{content}</span>;
}
