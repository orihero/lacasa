/**
 * RowActions — F's `.acts` cluster, the trailing edit/broadcast/delete (or
 * call/note, or edit/delete) icon-button group on every table row. Renders
 * an `<a>` when an action carries `href` (e.g. Publish status' external-link
 * action) and a `<button>` otherwise — never a `<button>` masquerading as a
 * navigation link or vice versa.
 */
import clsx from "clsx";
import type { IconComponent } from "./icons";

export interface RowAction {
  icon: IconComponent;
  label: string;
  onClick?: () => void;
  tone?: "default" | "danger";
  href?: string;
}

export function RowActions({ actions }: { actions: ReadonlyArray<RowAction> }) {
  return (
    <div className="flex justify-end gap-1.5">
      {actions.map((action, index) => {
        const Icon = action.icon;
        const className = clsx(
          "inline-flex h-[30px] w-[30px] items-center justify-center rounded-full border border-hairline bg-pill transition-colors hover:bg-surface-inner",
          action.tone === "danger" ? "text-err" : "text-ink",
        );
        const key = `${action.label}-${index}`;
        if (action.href) {
          return (
            <a
              key={key}
              href={action.href}
              aria-label={action.label}
              title={action.label}
              className={className}
            >
              <Icon size={13} />
            </a>
          );
        }
        return (
          <button
            key={key}
            type="button"
            onClick={action.onClick}
            aria-label={action.label}
            title={action.label}
            className={className}
          >
            <Icon size={13} />
          </button>
        );
      })}
    </div>
  );
}
