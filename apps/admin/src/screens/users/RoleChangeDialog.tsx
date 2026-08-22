/**
 * screens/users/RoleChangeDialog — the confirmation every role change goes
 * through. Wraps ui/ConfirmDialog rather than ui/Modal directly, so this
 * screen's one destructive control has the same shape (subject line, required
 * consequence, never-autofocused confirm) as every other consequential action
 * in the control room.
 *
 * WHY THE ROLE PICKER LIVES INSIDE THE CONFIRMATION rather than in the table
 * row: a row-level dropdown would make "pick a role" and "commit the change"
 * the same gesture, which is precisely the misclick this dialog exists to
 * catch. Here the admin picks, reads what that choice means for this specific
 * account, and only then confirms — and changing the selection rewrites the
 * consequence sentence and the button's own label under their eyes.
 *
 * The confirm button is deliberately NOT disabled when the selection still
 * equals the current role. ConfirmDialog's only disabling input is `busy`,
 * which would mislabel the button "Working…" — and a dead button explains
 * nothing anyway. Confirming a no-op change instead answers with the reason,
 * in the same slot a server refusal would appear in.
 */
import { useState, type ReactNode } from "react";
import { useTranslation } from "react-i18next";
import type { AdminUserRow } from "@lacasa/api-client";
import type { UserRoleKey } from "@lacasa/domain";
import { ConfirmDialog } from "@/ui/ConfirmDialog";
import { Field, Select } from "@/ui/Field";
import { Notice } from "@/ui/States";
import { Tag } from "@/ui/Tag";
import { USER_ROLE_ORDER, userRoleLabel, userRoleTone } from "@/lib/labels";
import {
  isAdminGrant,
  isAdminRevoke,
  roleChangeConfirmLabel,
  roleChangeConsequence,
  roleChangeErrorMessage,
} from "./roleChangeCopy";
import "./roleChangeDialog.scss";

export function RoleChangeDialog({
  user,
  busy,
  error,
  onConfirm,
  onCancel,
}: {
  user: AdminUserRow;
  busy?: boolean;
  /** Whatever the mutation rejected with — mapped to a guard-rail sentence. */
  error: unknown;
  onConfirm: (role: UserRoleKey) => void;
  onCancel: () => void;
}) {
  const { t } = useTranslation();
  const [nextRole, setNextRole] = useState<UserRoleKey>(user.role);
  const [noopAttempted, setNoopAttempted] = useState(false);

  const unchanged = nextRole === user.role;
  const grantingAdmin = isAdminGrant(user.role, nextRole);
  const irreversibleTone = grantingAdmin || isAdminRevoke(user.role, nextRole);

  // The server's refusal always wins the error slot: a stale "pick a
  // different role" hint must never sit on top of a real `last_admin`.
  const message: ReactNode =
    error != null
      ? roleChangeErrorMessage(t, error)
      : noopAttempted
        ? t("roleUnchangedWarning")
        : null;

  return (
    <ConfirmDialog
      title={t("dialogChangeRoleTitle")}
      subject={
        <>
          <span className="role-dialog__subject-line">
            {user.fullName} · {user.email}
          </span>
          {/* The full UUID, not lib/format's truncated display form: this is
              the last place the admin can check they are acting on the row
              they meant, and a prefix is not proof of identity. */}
          <span className="role-dialog__subject-id">{user.id}</span>
        </>
      }
      consequence={roleChangeConsequence(t, user, nextRole)}
      confirmLabel={roleChangeConfirmLabel(t, user.role, nextRole)}
      tone={irreversibleTone ? "danger" : "accent"}
      busy={busy}
      error={message}
      onConfirm={() => {
        if (unchanged) {
          setNoopAttempted(true);
          return;
        }
        onConfirm(nextRole);
      }}
      onCancel={onCancel}
    >
      {grantingAdmin ? (
        <Notice tone="danger" title={t("adminGrantNoticeTitle")}>
          {t("adminGrantNoticeBody")}
        </Notice>
      ) : null}

      <div className="role-dialog__current">
        {t("currentRole")}
        <Tag tone={userRoleTone(user.role)}>{userRoleLabel(t, user.role)}</Tag>
      </div>

      <Field label={t("newRole")}>
        <Select
          value={nextRole}
          onChange={(event) => {
            setNextRole(event.target.value as UserRoleKey);
            setNoopAttempted(false);
          }}
        >
          {USER_ROLE_ORDER.map((role) => (
            // One interpolated child, not two: an <option> with several text
            // children is an option whose `.text` an assistive tech (and a
            // test) has to reassemble.
            <option key={role} value={role}>
              {`${userRoleLabel(t, role)}${role === user.role ? t("roleOptionCurrentSuffix") : ""}`}
            </option>
          ))}
        </Select>
      </Field>
    </ConfirmDialog>
  );
}
