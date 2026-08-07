/**
 * src/lib/leadHelpers — pure `Lead` logic shared across every screen that
 * reads lead status/callback data: Leads (its own table + stage picker),
 * Kanban (column grouping + the gate flow), and Statistics ("N need a
 * callback today"). Originally lived under screens/leads/ when only
 * LeadsScreen used it; moved here once a second and third screen picked up
 * the same cross-directory import (see the Statistics/Kanban integration
 * pass) so the dependency is an explicit shared module, not one screen
 * directory reaching into another's.
 */
import { toValidDate, type DateLike, type LeadStatusKey } from '@lacasa/domain';
import { LEAD_STATUS_ORDER } from './labels';

/**
 * True when `callbackDate` falls on today's calendar date or earlier — "the
 * one thing an agent must not miss" per the Leads screen brief. A callback
 * later *today* (Aziz Karimov's 15:00, in the seed) still counts as due the
 * moment the day starts, not only once the clock passes 15:00 — an agent
 * planning their day needs to see it from the morning, not have it silently
 * promote to "overdue" mid-afternoon.
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
 * (LeadsScreen) or is dropped from the board (Kanban) instead of silently
 * mis-coloring it or offering a `<select>` whose options don't include the
 * value it's supposed to show.
 */
export function asLeadStatusKey(status: string): LeadStatusKey | undefined {
  return (LEAD_STATUS_ORDER as readonly string[]).includes(status) ? (status as LeadStatusKey) : undefined;
}
