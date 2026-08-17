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
import type { AdminUserRow } from "@lacasa/api-client";
import type { UserRoleKey } from "@lacasa/domain";
import { ConfirmDialog } from "@/ui/ConfirmDialog";
import { Field, Select } from "@/ui/Field";
import { Notice } from "@/ui/States";
import { Tag } from "@/ui/Tag";
import { USER_ROLE_LABEL, USER_ROLE_ORDER, USER_ROLE_TONE } from "@/lib/labels";
import {
  isAdminGrant,
  isAdminRevoke,
  roleChangeConfirmLabel,
  roleChangeConsequence,
  roleChangeErrorMessage,
} from "./roleChangeCopy";

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
  const [nextRole, setNextRole] = useState<UserRoleKey>(user.role);
  const [noopAttempted, setNoopAttempted] = useState(false);

  const unchanged = nextRole === user.role;
  const grantingAdmin = isAdminGrant(user.role, nextRole);
  const irreversibleTone = grantingAdmin || isAdminRevoke(user.role, nextRole);

  // The server's refusal always wins the error slot: a stale "pick a
  // different role" hint must never sit on top of a real `last_admin`.
  const message: ReactNode =
    error != null
      ? roleChangeErrorMessage(error)
      : noopAttempted
        ? "That is the role this account already has. Pick a different one, or cancel."
        : null;

  return (
    <ConfirmDialog
      title="Change role"
      subject={
        <>
          <span className="block">
            {user.fullName} · {user.email}
          </span>
          {/* The full UUID, not lib/format's truncated display form: this is
              the last place the admin can check they are acting on the row
              they meant, and a prefix is not proof of identity. */}
          <span className="mt-0.5 block text-faint">{user.id}</span>
        </>
      }
      consequence={roleChangeConsequence(user, nextRole)}
      confirmLabel={roleChangeConfirmLabel(user.role, nextRole)}
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
        <Notice tone="danger" title="This is the strongest permission the platform has.">
          Every other role change on this screen is undone by making the opposite one. This one hands
          over the ability to make that reversal impossible.
        </Notice>
      ) : null}

      <div className="mb-3 flex items-center gap-2 text-tiny uppercase tracking-caps text-muted">
        Current role
        <Tag tone={USER_ROLE_TONE[user.role]}>{USER_ROLE_LABEL[user.role]}</Tag>
      </div>

      <Field label="New role">
        <Select
          value={nextRole}
          onChange={(event) => {
            setNextRole(event.target.value as UserRoleKey);
            setNoopAttempted(false);
          }}
        >
          {USER_ROLE_ORDER.map((role) => (
            <option key={role} value={role}>
              {USER_ROLE_LABEL[role]}
              {role === user.role ? " (current)" : ""}
            </option>
          ))}
        </Select>
      </Field>
    </ConfirmDialog>
  );
}
