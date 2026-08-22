/**
 * ConfirmDialog — the one shape every consequential action goes through:
 * rejecting an application, changing a role, demoting an agent who still owns
 * listings.
 *
 * Three deliberate choices, all about the same failure mode — an admin
 * confirming the wrong row on autopilot:
 *
 *  1. `subject` is a standalone MONOSPACE RECORD LINE, not folded into the
 *     prose. The admin re-reads WHO this is about immediately above the button,
 *     in the same typeface the table row showed it in.
 *  2. `consequence` is REQUIRED. One sentence: what will be true after this is
 *     confirmed. A caller that cannot state that is not ready to show the
 *     dialog — which is why it is its own required prop rather than an optional
 *     line of `children`.
 *  3. The confirm button is NEVER auto-focused. A dialog that opens with
 *     "Reject" under the cursor's Enter key is a dialog that gets confirmed by
 *     the keystroke that opened it. (See Modal: nothing here sets `autoFocus`,
 *     and the close button is first in DOM order.)
 *
 * WHILE BUSY THE DIALOG CANNOT BE DISMISSED — both buttons disabled, Escape
 * disabled, scrim click ignored — and the confirm button reads "Working…".
 * This is the rebuild's one intentional behaviour change (PRECEDENCE.md): the
 * deleted app disabled only the buttons, so an admin could Escape out of an
 * in-flight approve and lose the error it came back with, on a mutation that
 * had already landed on someone's account.
 *
 * Cancelling must ALWAYS also reset the caller's mutation state (the deleted
 * app did that for role changes and not for decisions). That reset belongs to
 * the caller's `onCancel`, because the mutation is the caller's.
 */
import type { ReactNode } from "react";
import { useTranslation } from "react-i18next";
import { Button, type ButtonVariant } from "./Button";
import { Modal } from "./Modal";
import "./confirmDialog.scss";

export function ConfirmDialog({
  title,
  subject,
  consequence,
  confirmLabel,
  cancelLabel,
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
  /** One sentence: what will be true after this is confirmed. Required. */
  consequence: ReactNode;
  confirmLabel: string;
  /** Defaults to the shared "Cancel". */
  cancelLabel?: string;
  /** Maps onto Button's variants; `accent` is the neutral-but-primary case. */
  tone?: Extract<ButtonVariant, "danger" | "approve" | "accent">;
  busy?: boolean;
  /** Surfaced in place of a silent no-op when the mutation comes back 4xx. */
  error?: ReactNode;
  onConfirm: () => void;
  /** Must also reset the caller's mutation, so a reopened dialog is clean. */
  onCancel: () => void;
  /** Extra controls — a role select, a rejection reason. */
  children?: ReactNode;
}) {
  const { t } = useTranslation();

  return (
    <Modal title={title} onClose={onCancel} disableDismiss={busy === true}>
      <div className="confirm">
        {subject != null ? <div className="confirm__subject">{subject}</div> : null}

        <p className="confirm__consequence">{consequence}</p>

        {children != null ? <div className="confirm__extra">{children}</div> : null}

        {error != null ? (
          // role="alert" rather than status: this is the answer to something
          // the admin just did, and it has to interrupt.
          <p role="alert" className="confirm__error">
            {error}
          </p>
        ) : null}

        <div className="confirm__actions">
          <Button onClick={onCancel} disabled={busy}>
            {cancelLabel ?? t("cancel")}
          </Button>
          <Button variant={tone} onClick={onConfirm} disabled={busy}>
            {busy ? t("working") : confirmLabel}
          </Button>
        </div>
      </div>
    </Modal>
  );
}
