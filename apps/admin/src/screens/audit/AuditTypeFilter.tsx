/**
 * AuditTypeFilter — the event type filter, as a plain Select.
 *
 * NOT the mockup's segmented control. `.seg` there offers five families
 * (All / Auth / Moderation / Billing / System), none of which exist, and a
 * family filter cannot be built honestly on top of this endpoint anyway:
 * GET /api/admin/audit takes ONE exact `type`, not a prefix, so an "all
 * ad.* events" segment could only be faked by discarding rows from a
 * cursor-paginated page after it arrived — which would silently under-report
 * (the next matching row could be three pages down) on the screen whose only
 * job is to be complete about what it shows. Eleven exact values in a select
 * is the whole vocabulary the server can actually filter on.
 *
 * Options come from lib/labels' AUDIT_TYPE_KEYS, the list that is checked
 * against schema.prisma's `EventType` by its own unit test, so a twelfth
 * event type cannot land server-side and quietly go unfilterable here.
 */
import type { AdminAuditEventType } from "@lacasa/api-client";
import { Select } from "@/ui/Field";
import { AUDIT_TYPE_KEYS, AUDIT_TYPE_LABEL } from "@/lib/labels";

/** The `<option>` value standing in for "no filter" — `undefined` has no DOM spelling. */
const ANY = "";

export function AuditTypeFilter({
  value,
  onChange,
}: {
  value: AdminAuditEventType | undefined;
  onChange: (value: AdminAuditEventType | undefined) => void;
}) {
  return (
    <Select
      aria-label="Event type"
      className="w-[215px]"
      value={value ?? ANY}
      onChange={(event) => {
        const next = event.target.value;
        onChange(next === ANY ? undefined : (next as AdminAuditEventType));
      }}
    >
      <option value={ANY}>All event types</option>
      {AUDIT_TYPE_KEYS.map((key) => (
        <option key={key} value={key}>
          {AUDIT_TYPE_LABEL[key]}
        </option>
      ))}
    </Select>
  );
}
