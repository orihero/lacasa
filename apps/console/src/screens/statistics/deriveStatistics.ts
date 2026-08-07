/**
 * src/screens/statistics/deriveStatistics — the two small derivations the
 * Statistics screen's stat tiles need beyond what `GET /statistics/ads` and
 * `GET /statistics/coworkers` return verbatim (src/data/useStatistics.ts):
 *
 *  - "N need a callback today", under the Active leads tile — reuses
 *    `isCallbackDueOrOverdue` from `@/lib/leadHelpers` (the exact rule
 *    the Leads table's own callback warn-tag uses) rather than a second,
 *    slightly-different "is this due" definition living here.
 *  - "N active this week", under the Coworkers tile — a coworker counts once
 *    if *any* of their CoworkerStatisticEvent rows fall in the last 7 days,
 *    from the same `useCoworkerStatistics()` list src/data/useCoworkers.ts's
 *    `deriveCoworkerMetrics` already reads for "last active".
 *
 * What this module deliberately does NOT compute: a "+12 vs last month"
 * delta for Ads created/sold. `GET /statistics/ads` takes one `filterType`
 * ('today'|'thisWeek'|'thisMonth'|'all') and returns a single count for it —
 * there is no previous-period figure to diff against, and no "lastMonth"
 * filter value either. PLAN.md §3.1's delta copy is aspirational, not
 * something this API can back; StatisticsScreen renders the real counts and
 * omits the delta entirely rather than inventing one (PLAN.md §4).
 */
import type { CoworkerStatisticEvent, Lead } from '@lacasa/api-client';
import { toValidDate } from '@lacasa/domain';
import { isCallbackDueOrOverdue } from '@/lib/leadHelpers';

export function countCallbacksDueToday(leads: readonly Lead[], now: Date = new Date()): number {
  return leads.filter((lead) => isCallbackDueOrOverdue(lead.callbackDate, now)).length;
}

const WEEK_MS = 7 * 24 * 60 * 60 * 1000;

/** Distinct coworkers with at least one event in the trailing 7 days —
 * never a fabricated "recently active" guess when `events` is empty. */
export function countCoworkersActiveThisWeek(
  events: readonly CoworkerStatisticEvent[],
  now: Date = new Date(),
): number {
  const since = now.getTime() - WEEK_MS;
  const activeCoworkerIds = new Set<string>();
  for (const event of events) {
    const eventDate = toValidDate(event.createdAt);
    if (eventDate && eventDate.getTime() >= since) {
      activeCoworkerIds.add(event.coworkerId);
    }
  }
  return activeCoworkerIds.size;
}
