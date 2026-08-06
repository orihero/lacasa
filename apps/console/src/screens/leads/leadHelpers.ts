/**
 * src/screens/leads/leadHelpers — pure logic pulled out of LeadsScreen so the
 * two rules that actually matter on this screen (which callback an agent
 * cannot afford to miss, and whether a wire-format status string is one of
 * the five real LeadStatus members) are unit-testable without mounting the
 * table.
 */
import { toValidDate, type DateLike, type LeadStatusKey } from '@lacasa/domain';
import { LEAD_STATUS_ORDER } from '@/lib/labels';

/**
 * True when `callbackDate` falls on today's calendar date or earlier — "the
 * one thing an agent must not miss" per the screen brief. A callback later
 * *today* (Aziz Karimov's 15:00, in the seed) still counts as due the moment
 * the day starts, not only once the clock passes 15:00 — an agent planning
 * their day needs to see it from the morning, not have it silently promote
 * to "overdue" mid-afternoon.
 */
export function isCallbackDueOrOverdue(callbackDate: DateLike, now: Date = new Date()): boolean {
  const date = toValidDate(callbackDate);
  if (!date) return false;
  const endOfToday = new Date(now.getFullYear(), now.getMonth(), now.getDate(), 23, 59, 59, 999);
  return date.getTime() <= endOfToday.getTime();
}

/**
 * `Lead.status` is typed as a bare `string` on the wire (@lacasa/api-client's
 * Lead interface, not LeadStatusKey — see leadService.js's serializeLead).
 * Narrows it against the five real statuses rather than trusting the cast, so
 * a status the schema doesn't know about degrades to a read-only display
 * (LeadsScreen) instead of silently mis-coloring it or offering a `<select>`
 * whose options don't include the value it's supposed to show.
 */
export function asLeadStatusKey(status: string): LeadStatusKey | undefined {
  return (LEAD_STATUS_ORDER as readonly string[]).includes(status) ? (status as LeadStatusKey) : undefined;
}
