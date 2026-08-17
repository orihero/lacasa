/**
 * InlineBanner — a dismissible strip above the table for facts that arrived
 * AFTER the page rendered: "another admin already decided this one", "the
 * background refresh failed".
 *
 * Why not ui/States' `Notice`, which is the same shape? Two reasons, and both
 * are about this surface's colour discipline rather than about layout:
 *
 *  · Notice only offers `acc` (amber) and `danger` (magenta). Amber on this
 *    surface means WAITING ON YOU (tailwind.config.js rule 2, labels.ts's tone
 *    allocation) and magenta means IRREVERSIBLE — a message saying a decision
 *    has already been taken is neither. Painting it amber would put a second
 *    kind of amber next to the pending queue's badge and cost that badge its
 *    meaning; painting it magenta would imply something was destroyed.
 *  · Notice is permanent. These two messages are transient by nature: the
 *    stale-decision one is answered by the refetch it announces, and a banner
 *    that cannot be cleared becomes wallpaper long before it stops being
 *    displayed.
 *
 * So: `neutral` uses the plain sunk/hairline record palette, and `error` uses
 * the semantic `err` status colour — which is the settled-outcome red the tag
 * scale already uses, not the quarantined magenta.
 */
import type { ReactNode } from "react";
import clsx from "clsx";
import { InfoIcon, WarningCircleIcon, XIcon } from "@/ui/icons";

export type InlineBannerTone = "neutral" | "error";

export function InlineBanner({
  tone = "neutral",
  children,
  onDismiss,
}: {
  tone?: InlineBannerTone;
  children: ReactNode;
  /** Renders the close affordance. Omit for a banner that must stay put. */
  onDismiss?: () => void;
}) {
  const isError = tone === "error";
  const Icon = isError ? WarningCircleIcon : InfoIcon;

  return (
    <div
      // `status`, never `alert`: both of these interrupt a screen reader mid
      // sentence if announced assertively, and neither is urgent enough to
      // justify that on a screen where the admin is mid-decision.
      role="status"
      className={clsx(
        "mb-3.5 flex items-start gap-2.5 rounded-panel border px-3 py-2.5",
        isError ? "border-err/40 bg-err-soft" : "border-line bg-sunk",
      )}
    >
      <Icon
        size={15}
        className={clsx("mt-px flex-none", isError ? "text-err" : "text-muted")}
      />
      <div className="min-w-0 text-small leading-relaxed text-ink-2">{children}</div>
      {onDismiss ? (
        <button
          type="button"
          aria-label="Dismiss"
          onClick={onDismiss}
          className="-my-0.5 -mr-1 ml-auto grid h-[25px] w-[25px] flex-none place-items-center rounded-act text-muted transition-colors hover:text-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-acc"
        >
          <XIcon size={12} />
        </button>
      ) : null}
    </div>
  );
}
