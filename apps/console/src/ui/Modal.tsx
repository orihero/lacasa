/**
 * Modal — the console's one overlay/panel primitive: dark scrim, flat
 * `rounded-card` panel, no drop shadow (PLAN.md §1's flat-depth rule).
 * Promoted from the coworkers screen's local `Modal.tsx` once a second and
 * third screen (My ads' delete confirmation, Leads' create form) each built
 * their own near-identical scrim+panel+Escape-to-close overlay independently
 * — this is that one shape, in `src/ui/` so nobody has to re-solve it again.
 *
 * Visually mirrors F's own stage-gate modal (f-console.src.html's
 * `#m-ov`/`.modal`) — this console has exactly one modal grammar, this is
 * it. Not a full dialog framework (no focus trap, no portal): every consumer
 * so far is a short form or a two-button confirmation, so Escape-to-close
 * plus a scrim click is all the keyboard/mouse affordance that's earned its
 * complexity.
 */
import { useEffect, type ReactNode } from "react";
import { XIcon } from "@/ui/icons";

export function Modal({
  title,
  onClose,
  children,
}: {
  title: string;
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
    <div className="fixed inset-0 z-50 flex items-center justify-center bg-ink/40 p-4" onClick={onClose}>
      <div
        role="dialog"
        aria-modal="true"
        aria-label={title}
        onClick={(event) => event.stopPropagation()}
        className="w-full max-w-[420px] rounded-card border border-black/[.03] bg-surface p-6"
      >
        <div className="mb-4 flex items-center justify-between gap-3">
          <h3 className="text-title font-semibold text-ink">{title}</h3>
          <button
            type="button"
            aria-label="Close"
            onClick={onClose}
            className="inline-flex h-8 w-8 shrink-0 items-center justify-center rounded-full border border-hairline bg-pill text-ink transition-colors hover:bg-surface-inner"
          >
            <XIcon size={14} />
          </button>
        </div>
        {children}
      </div>
    </div>
  );
}
