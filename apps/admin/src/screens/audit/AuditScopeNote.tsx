/**
 * AuditScopeNote — the permanent statement of what this log is NOT.
 *
 * This is the most important element on the screen. `ActivityEvent` records
 * agent and coworker activity against ads and leads, and nothing else: no
 * sign-ins, no admin decisions (nothing under /api/admin writes an event —
 * see adminRepository.findAuditEvents), no system jobs, no severity, no
 * actor type beyond "agent or their coworker". An admin who reads this
 * screen as a complete audit trail will conclude from an empty stream that
 * nothing happened, which is the one failure mode this whole screen has to
 * defend against. So the caveat is not a dismissible toast and not a
 * tooltip — it renders above the table on every state, including the empty
 * and error ones, where the wrong conclusion is easiest to reach.
 *
 * NOT ui/States' `Notice`, deliberately, even though the shape matches.
 * Notice is amber or magenta, and on this surface amber means WAITING ON YOU
 * (see lib/labels.ts's tone rules): a permanently amber banner that never
 * resolves would spend the one signal colour on something no admin can ever
 * act on, and after a week of seeing it here they would stop reading amber
 * on the applications queue too. This is a neutral, sunk-surface note — the
 * same visual weight as a table header, which is what a permanent caveat
 * should be.
 */
import { InfoIcon } from "@/ui/icons";

export function AuditScopeNote() {
  return (
    <div className="mb-3.5 flex items-start gap-2.5 rounded-panel border border-line bg-sunk px-3 py-2.5">
      <InfoIcon size={15} className="mt-px flex-none text-muted" />
      <div className="min-w-0">
        <b className="block text-small font-bold text-ink-2">
          Agent and coworker activity only — not a complete audit trail
        </b>
        <p className="mt-1 text-record leading-relaxed text-muted">
          These are business events an agent or one of their coworkers caused: ads created,
          marked sold or drafted, leads created and moved, and OLX / Instagram crosspost
          sessions. Sign-ins, admin decisions taken in this control room, and background jobs
          are <b className="font-semibold text-ink-2">not recorded anywhere</b> and will never
          appear below. Events carry no severity either: the colour on each row is this app
          reading the event type&apos;s outcome, not a level the server stored.
        </p>
      </div>
    </div>
  );
}
