/**
 * AuditTypeFilter — the event type filter, as a plain native Select.
 *
 * NOT a segmented control, and not family/prefix tabs. The original mockup
 * offered five families (All / Auth / Moderation / Billing / System), none of
 * which exist, and a family filter cannot be built honestly on top of this
 * endpoint anyway: GET /api/admin/audit takes ONE exact `type`, not a prefix,
 * so an "all ad.* events" segment could only be faked by discarding rows from
 * a cursor-paginated page after it arrived — which would silently under-report
 * (the next matching row could be three pages down) on the screen whose only
 * job is to be complete about what it shows. Eleven exact values in a select
 * is the whole vocabulary the server can actually filter on.
 *
 * A native `<select>` is also the house control: apps/web's filter bar is
 * "native selects, no MUI Autocomplete" (web-design-contract.md §8.4), which
 * is what `@/ui/Field`'s `Select` renders.
 *
 * Options come from lib/labels' AUDIT_TYPE_KEYS, the list that is checked
 * against schema.prisma's `EventType` by lib/labels.test.ts, so a twelfth
 * event type cannot land server-side and quietly go unfilterable here.
 */
import type { AdminAuditEventType } from "@lacasa/api-client";
import { useTranslation } from "react-i18next";
import { Select } from "@/ui/Field";
import { AUDIT_TYPE_KEYS, auditTypeLabel } from "@/lib/labels";
import "./audit.scss";

/** The `<option>` value standing in for "no filter" — `undefined` has no DOM spelling. */
const ANY = "";

export function AuditTypeFilter({
  value,
  onChange,
}: {
  value: AdminAuditEventType | undefined;
  onChange: (value: AdminAuditEventType | undefined) => void;
}) {
  const { t } = useTranslation();

  return (
    <Select
      aria-label={t("eventTypeAriaLabel")}
      className="audit-type-filter"
      value={value ?? ANY}
      onChange={(event) => {
        const next = event.target.value;
        onChange(next === ANY ? undefined : (next as AdminAuditEventType));
      }}
    >
      <option value={ANY}>{t("allEventTypes")}</option>
      {AUDIT_TYPE_KEYS.map((key) => (
        <option key={key} value={key}>
          {auditTypeLabel(t, key)}
        </option>
      ))}
    </Select>
  );
}
