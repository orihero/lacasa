/**
 * Modal — MUI's `Dialog`, which is the one place this app knowingly reaches for
 * a component apps/web does not use.
 *
 * apps/web has `Modal` + `<Box sx={style}>` and no `Dialog` at all
 * (web-design-contract.md §9.1/§15.12). Its own modals are a title, a field and
 * two buttons; ours are the confirmations that approve an application or hand
 * someone the admin role, and `Dialog` is what brings the scrim, the escape
 * key, focus containment and focus restoration without four of us
 * hand-rolling them differently. The look is apps/web's: square (the theme's
 * `MuiDialog.paper`), white, with the same `.field` controls inside it.
 *
 * Behaviour that must survive:
 *  · `role="dialog"`, `aria-modal="true"` (both MUI's) and an accessible name
 *    equal to `title` — supplied here as `aria-labelledby` pointing at the
 *    heading, so the name and the visible title cannot drift apart.
 *  · Escape, the scrim and an explicit close button labelled "Close" all
 *    dismiss — UNLESS `disableDismiss` is set. Cancelling by accident is always
 *    recoverable on this surface; confirming by accident is the thing that is
 *    not, which is why every dismissal path is a cancel and none of them is a
 *    confirm.
 *  · The title is an `<h3>`: the topbar owns the page's one `<h1>` and a panel
 *    head is the `<h2>` beneath it.
 *
 * `disableDismiss` is how ConfirmDialog freezes the dialog while a mutation is
 * in flight (PRECEDENCE.md, "the one deliberate behavioural deviation"): a
 * dialog that can be escaped mid-flight throws away the in-dialog error of a
 * decision that is still landing on someone's account.
 *
 * NOTHING IS AUTO-FOCUSED INTO A BUTTON on open. MUI's FocusTrap moves focus to
 * the dialog surface itself, and the close button is the first control in DOM
 * order, so the confirm button never sits under the Enter key that opened the
 * dialog. Do not add `autoFocus` to a control inside a Modal.
 */
import Dialog from "@mui/material/Dialog";
import { useId, type ReactNode } from "react";
import { useTranslation } from "react-i18next";
import { IconButton } from "./IconButton";
import { X } from "./icons";
import "./modal.scss";

export function Modal({
  title,
  sub,
  onClose,
  open = true,
  disableDismiss = false,
  maxWidth = "sm",
  children,
}: {
  title: string;
  sub?: ReactNode;
  onClose: () => void;
  /**
   * Defaults to `true` because every consumer mounts the dialog conditionally
   * (`{pending && <ConfirmDialog … />}`), which is how the deleted app did it.
   * Pass it explicitly to keep a dialog mounted across its own close.
   */
  open?: boolean;
  /** While set: Escape, the scrim and the close button all stop working. */
  disableDismiss?: boolean;
  maxWidth?: "xs" | "sm" | "md";
  children: ReactNode;
}) {
  const { t } = useTranslation();
  const titleId = useId();

  return (
    <Dialog
      open={open}
      // MUI hands back the reason; both reasons mean cancel, and neither is
      // honoured while the dialog is frozen.
      onClose={() => {
        if (disableDismiss) return;
        onClose();
      }}
      disableEscapeKeyDown={disableDismiss}
      aria-labelledby={titleId}
      fullWidth
      maxWidth={maxWidth}
    >
      <div className="modal">
        <div className="modal__head">
          <div className="modal__heading">
            <h3 className="modal__title" id={titleId}>
              {title}
            </h3>
            {sub != null ? <p className="modal__sub">{sub}</p> : null}
          </div>
          <IconButton
            icon={X}
            label={t("close")}
            size="sm"
            onClick={onClose}
            disabled={disableDismiss}
          />
        </div>
        <div className="modal__body">{children}</div>
      </div>
    </Dialog>
  );
}
