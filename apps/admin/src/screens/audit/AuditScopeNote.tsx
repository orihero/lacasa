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
 * Notice is the accent-yellow (or danger-red) banner, and on this surface
 * yellow means WAITING ON YOU (see lib/labels.ts's tone rules): a permanently
 * yellow banner that never resolves would spend the one signal colour on
 * something no admin can ever act on, and after a week of seeing it here they
 * would stop reading yellow on the applications queue too. This is a neutral
 * note on apps/web's app canvas (`#f5f6fa`) inside the white panel column,
 * with the same hairline (`#dedede`) the list rows take — the visual weight
 * of a table header, which is what a permanent caveat should be.
 *
 * The paragraph is split across three keys rather than a <Trans>: apps/web
 * uses no <Trans> anywhere, and the bolded fragment in the middle of the
 * sentence has to survive translation intact.
 */
import { useTranslation } from "react-i18next";
import { Info } from "@/ui/icons";
import "./audit.scss";

export function AuditScopeNote() {
  const { t } = useTranslation();

  return (
    <div className="audit-scope">
      <span className="audit-scope__icon">
        <Info size={15} aria-hidden="true" />
      </span>
      <div className="audit-scope__text">
        <b className="audit-scope__title">{t("auditScopeTitle")}</b>
        <p className="audit-scope__body">
          {t("auditScopeBodyStart")}
          <b className="audit-scope__emphasis">{t("auditScopeBodyEmphasis")}</b>
          {t("auditScopeBodyEnd")}
        </p>
      </div>
    </div>
  );
}
