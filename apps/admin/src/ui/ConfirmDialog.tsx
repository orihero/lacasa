/**
 * ConfirmDialog — the one shape every consequential action on this surface
 * goes through: rejecting an application, changing someone's role, demoting
 * an agent who still owns listings.
 *
 * Three deliberate choices, all of them about the same failure mode (an
 * admin confirming the wrong row on autopilot):
 *
 *  1. `subject` is rendered as a monospace record line, not folded into the
 *     prose. The admin re-reads WHO this is about right above the button,
 *     in the same typeface the table row showed it in.
 *  2. `consequence` is required for the destructive tone. If a caller cannot
 *     state what will happen in one sentence, the dialog is not ready to be
 *     shown — this is why it is a separate required prop rather than an
 *     optional line of `children`.
 *  3. The confirm button is never focused on open. A dialog that opens with
 *     "Reject" under the cursor's Enter key is a dialog that gets confirmed
 *     by the keystroke that opened it.
 *
 * Escape and the close button cancel, exactly as Modal defines. A scrim
 * click cancels too — cancelling by accident is always recoverable here,
 * where confirming by accident is the thing that is not.
 */
import type { ReactNode } from "react";
import { Button } from "./Button";
import { Modal } from "./Modal";

export function ConfirmDialog({
  title,
  subject,
  consequence,
  confirmLabel,
  cancelLabel = "Cancel",
  tone = "danger",
  busy,
  error,
  onConfirm,
  onCancel,
  children,
}: {
  title: string;
  /** The record being acted on — a name, an email, an id. Shown verbatim. */
  subject?: ReactNode;
  /** One sentence: what will be true after this is confirmed. */
  consequence: ReactNode;
  confirmLabel: string;
  cancelLabel?: string;
  tone?: "danger" | "approve" | "accent";
  busy?: boolean;
  /** Surfaced in place of a silent no-op when the mutation comes back 4xx. */
  error?: ReactNode;
  onConfirm: () => void;
  onCancel: () => void;
  /** Optional extra controls — a rejection reason, a role select. */
  children?: ReactNode;
}) {
  return (
    <Modal title={title} onClose={onCancel}>
      {subject != null ? (
        <div className="mb-3 rounded-control border border-line bg-sunk px-3 py-2 font-mono text-record text-ink">
          {subject}
        </div>
      ) : null}

      <p className="text-small leading-relaxed text-ink-2">{consequence}</p>

      {children != null ? <div className="mt-3.5">{children}</div> : null}

      {error != null ? (
        <p role="alert" className="mt-3 text-small text-err">
          {error}
        </p>
      ) : null}

      <div className="mt-4 flex justify-end gap-2">
        <Button onClick={onCancel} disabled={busy}>
          {cancelLabel}
        </Button>
        <Button variant={tone} onClick={onConfirm} disabled={busy}>
          {busy ? "Working…" : confirmLabel}
        </Button>
      </div>
    </Modal>
  );
}
