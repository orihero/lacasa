/**
 * Modal — the control room's one overlay, ported from the mockup's `.ix`
 * index sheet: a blurred near-black scrim over a `card` panel.
 *
 * Not a full dialog framework (no portal, no focus trap): every consumer on
 * this surface is a short form or a two-button confirmation, so Escape,
 * a scrim click and a real close button are the affordances that have earned
 * their complexity. ConfirmDialog builds on this rather than re-solving it.
 *
 * One deliberate difference from apps/console's Modal: the scrim click is
 * wired to `onClose` here too, but ConfirmDialog's destructive path does NOT
 * treat a stray click as "cancel and forget" — see its own comment.
 */
import { useEffect, type ReactNode } from "react";
import { XIcon } from "./icons";

export function Modal({
  title,
  sub,
  onClose,
  children,
}: {
  title: string;
  sub?: ReactNode;
  onClose: () => void;
  children: ReactNode;
}) {
  useEffect(() => {
    function onKeyDown(event: KeyboardEvent) {
      if (event.key === "Escape") onClose();
    }
    document.addEventListener("keydown", onKeyDown);
    return () => document.removeEventListener("keydown", onKeyDown);
  }, [onClose]);

  return (
    <div
      className="fixed inset-0 z-[210] flex items-center justify-center bg-[rgba(4,6,10,.72)] p-6 backdrop-blur-lg"
      onClick={onClose}
    >
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onClick={(event) => event.stopPropagation()}
        className="w-full max-w-[480px] rounded-modal border border-line bg-card p-5 shadow-panel"
      >
        <div className="mb-3 flex items-start justify-between gap-3">
          <div className="min-w-0">
            <h3 className="text-lg font-semibold text-ink">{title}</h3>
            {sub != null ? <p className="mt-1 text-small leading-relaxed text-muted">{sub}</p> : null}
          </div>
          <button
            type="button"
            aria-label="Close"
            onClick={onClose}
            className="grid h-[25px] w-[25px] flex-none place-items-center rounded-act border border-line bg-sunk text-muted transition-colors hover:text-ink focus-visible:outline-none focus-visible:ring-2 focus-visible:ring-acc"
          >
            <XIcon size={12} />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}
