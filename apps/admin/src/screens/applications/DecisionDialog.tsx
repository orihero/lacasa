/**
 * DecisionDialog — the confirmation an admin passes through before approving
 * or rejecting a realtor application.
 *
 * The two consequence sentences live here, in one file, rather than at the two
 * call sites: they are the only place this app states in words what the button
 * is about to do to somebody else's account, and a copy of each that can drift
 * from the other is a copy that will eventually describe the wrong outcome.
 * Both name the applicant explicitly — ConfirmDialog's own header explains why
 * (an admin confirming the wrong row on autopilot is the failure this whole
 * dialog exists to prevent), and this screen is the sharpest case of it, since
 * approving hands a stranger the ability to publish listings under the La Casa
 * name.
 *
 * TONE IS NOT SYMMETRIC, deliberately. Reject is the `danger` (magenta)
 * variant and Approve is the green `approve` one, even though approving is by
 * far the more consequential of the two — because tone on this surface encodes
 * REVERSIBILITY, not weight (see ui/Button.tsx). A rejected application cannot
 * be un-rejected from this UI: the endpoint only accepts a PENDING row, so the
 * 409 guard that protects against a double decision also means there is no
 * second chance. Approving is the grant, and green is the colour of a grant.
 */
import type { AdminApplicationRow } from "@lacasa/api-client";
import { ConfirmDialog } from "@/ui/ConfirmDialog";
import type { ApplicationDecision } from "@/data/useApplications";

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
  /** A failed decision, in the API's own words. Null for the 409, which the
   * screen answers with a banner and a refetch instead — see ApplicationsScreen. */
  error?: string | null;
  onConfirm: () => void;
  onCancel: () => void;
}) {
  const approving = decision === "approve";

  return (
    <ConfirmDialog
      title={approving ? "Approve realtor application" : "Reject realtor application"}
      // Name and email together, in the monospace the table row showed them
      // in: the name alone is not identifying on a queue that can hold two
      // applicants with the same one.
      subject={`${application.fullName} · ${application.email}`}
      consequence={
        approving ? (
          <>
            Approving grants <b className="font-semibold text-ink">{application.fullName}</b> agent
            access to the platform. Their role changes from Buyer to Agent and they can publish
            listings immediately. This is the only path to an agent account, and it cannot be
            silently undone — demoting them later leaves their listings behind.
          </>
        ) : (
          <>
            Rejecting turns down{" "}
            <b className="font-semibold text-ink">{application.fullName}</b>&rsquo;s application.
            Their account stays a buyer, with no agent access and no way to publish. The decision is
            recorded against their profile and cannot be reversed from here.
          </>
        )
      }
      confirmLabel={approving ? "Approve" : "Reject"}
      tone={approving ? "approve" : "danger"}
      busy={busy}
      error={error ?? undefined}
      onConfirm={onConfirm}
      onCancel={onCancel}
    />
  );
}
