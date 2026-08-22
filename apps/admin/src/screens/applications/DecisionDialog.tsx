/**
 * DecisionDialog — the confirmation an admin passes through before approving or
 * rejecting a realtor application.
 *
 * The two consequence sentences live here, in one file, rather than at the two
 * call sites: they are the only place this app states in words what the button
 * is about to do to somebody else's account, and a copy of each that can drift
 * from the other is a copy that will eventually describe the wrong outcome.
 * Both name the applicant explicitly — ConfirmDialog's own header explains why
 * (an admin confirming the wrong row on autopilot is the failure the whole
 * dialog exists to prevent), and this screen is the sharpest case of it, since
 * approving hands a stranger the ability to publish listings under the La Casa
 * name.
 *
 * TONE IS NOT SYMMETRIC, deliberately. Reject is the `danger` variant and
 * Approve the `approve` one, even though approving is by far the more
 * consequential of the two — because tone on this surface encodes
 * REVERSIBILITY, not weight. A rejected application cannot be un-rejected from
 * this UI: the endpoint only accepts a PENDING row, so the same 409 guard that
 * prevents a double decision also means there is no second chance. Approving is
 * a grant. `danger` is quarantined to exactly this one control on this screen.
 *
 * The applicant's name is BOLD INSIDE the sentence, not lifted onto a line of
 * its own — the sentence has to read as one sentence. Because apps/web uses no
 * `<Trans>`, the copy is carried as a prefix key + the name + a suffix key
 * rather than as interpolated markup; the three fragments concatenate to
 * exactly the string the spec quotes.
 */
import type { AdminApplicationRow } from "@lacasa/api-client";
import { useTranslation } from "react-i18next";
import { ConfirmDialog } from "@/ui/ConfirmDialog";
import type { ApplicationDecision } from "@/data/useApplications";
import "./applications.scss";

export function DecisionDialog({
  application,
  decision,
  busy,
  error,
  onConfirm,
  onCancel,
}: {
  application: AdminApplicationRow;
  decision: ApplicationDecision;
  busy?: boolean;
  /**
   * A failed decision, in the API's own words. Null for the 409, which the
   * screen answers with a banner and a refetch instead — see ApplicationsScreen.
   */
  error?: string | null;
  onConfirm: () => void;
  /** Closes the dialog AND resets the mutation — both belong to the caller. */
  onCancel: () => void;
}) {
  const { t } = useTranslation();
  const approving = decision === "approve";

  return (
    <ConfirmDialog
      title={approving ? t("dialogApproveTitle") : t("dialogRejectTitle")}
      // Name and email together, in the monospace the table row showed them in:
      // the name alone is not identifying on a queue that can hold two
      // applicants who share one.
      subject={`${application.fullName} · ${application.email}`}
      consequence={
        approving ? (
          <>
            {t("approveConsequencePrefix")}
            <b className="applications__name">{application.fullName}</b>
            {t("approveConsequenceSuffix")}
          </>
        ) : (
          <>
            {t("rejectConsequencePrefix")}
            <b className="applications__name">{application.fullName}</b>
            {t("rejectConsequenceSuffix")}
          </>
        )
      }
      confirmLabel={approving ? t("approve") : t("reject")}
      tone={approving ? "approve" : "danger"}
      busy={busy}
      error={error ?? undefined}
      onConfirm={onConfirm}
      onCancel={onCancel}
    />
  );
}
