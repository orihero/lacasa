// Prisma calls only — no business logic, no HTTP concerns. Every function
// takes `prisma` (i.e. `ctx.prisma`) as its first argument so it stays
// testable against the fake ctx in test/helpers/testApp.js without a real
// database.

export function countActivityEvents(prisma, { agentId, type, range }) {
  return prisma.activityEvent.count({ where: { agentId, type, ...(range ? { createdAt: range } : {}) } });
}

export function findActivityEventsForAgent(prisma, agentId) {
  return prisma.activityEvent.findMany({ where: { agentId } });
}

// One raw grouped query per event type (never a query-per-bucket loop):
// Prisma's `groupBy` can group by a column but has no way to group by a
// truncated *part* of a timestamp column, so a bucketed time series has no
// query-builder path — `$queryRaw` + `date_trunc` is the only way to ask
// Postgres to do the bucketing instead of pulling every row over the wire
// and bucketing in Node.
//
// Every value that comes from the request (`agentId`, `start`, `end`) is
// passed through Prisma's tagged-template parameter binding below, never
// string-interpolated into the SQL text — that's what keeps this safe from
// injection despite being a raw query. `unit` never comes from the request
// either (statisticsService.js#granularityFor picks it from the resolved
// date range, not from a query string), but it still goes through the same
// tagged-template binding rather than being special-cased, so there is only
// one code path to reason about instead of "bound normally, except when it
// isn't."
//
// `"created_at" AT TIME ZONE ${timeZone}` (and the matching `AT TIME ZONE`
// wrapped back around the whole `date_trunc`) is deliberate, not decorative:
// createdAt is a Timestamptz (a UTC instant), but *which* calendar day/hour
// that instant falls in depends on whatever timezone is doing the looking —
// Postgres's session `TimeZone` GUC if we let `date_trunc` default, or the
// Node process's local zone if we computed the grid in JS the naive way.
// Those two are not guaranteed to agree (on this dev box, Postgres's
// session timezone is GMT while the API process runs in Asia/Tashkent), and
// in production they could each be configured differently again.
//
// The fix is to stop asking either ambient zone and instead name one
// explicitly: `timeZone` is `config.STATISTICS_TIMEZONE`
// (statisticsService.js), passed in by the caller rather than read from
// config here, so this file never has to import config itself and the same
// value only has to be resolved once per request. The double conversion is
// the standard idiom for zone-aware truncation: `created_at AT TIME ZONE
// timeZone` first turns the timestamptz into a *naive* timestamp holding
// the wall-clock reading in that zone (timestamptz -> local), `date_trunc`
// then truncates that wall-clock reading to the start of its hour/day, and
// the second `AT TIME ZONE timeZone` reinterprets those truncated wall-clock
// numbers as being in that same zone and converts back to a real instant
// (local -> timestamptz). Verified directly against this dev box's Postgres
// (`date_trunc('day', now() AT TIME ZONE 'Asia/Tashkent') AT TIME ZONE
// 'Asia/Tashkent'` on 2026-08-11 06:51 UTC returned 2026-08-10 19:00:00+00
// — exactly local midnight Aug 11 in Tashkent, expressed as the UTC instant
// it is) rather than assumed from the idiom alone.
//
// `timeZone` never comes from the request (it's config, not a query
// param), but it's bound through the same tagged-template parameter
// binding as `agentId`/`start`/`end` below rather than string-interpolated
// — verified directly (`PREPARE ... AS ... AT TIME ZONE $1`) that Postgres
// accepts a bound parameter as the right-hand operand of `AT TIME ZONE` —
// so there's one code path to reason about instead of "bound normally,
// except when it isn't."
//
// Truncating the JS-side zero-fill grid with the matching zone-aware
// truncation in statisticsService.js#truncateToZone is what guarantees the
// SQL grouping and the JS bucket list are always describing the same
// instants, regardless of either process's local/session configuration.
export async function bucketedEventCounts(prisma, { agentId, type, start, end, unit, timeZone }) {
  return prisma.$queryRaw`
    SELECT date_trunc(${unit}, "created_at" AT TIME ZONE ${timeZone}) AT TIME ZONE ${timeZone} AS bucket,
           COUNT(*)::int AS count
    FROM "activity_events"
    WHERE "agent_id" = ${agentId}::uuid
      AND "type" = ${type}::"EventType"
      AND "created_at" >= ${start}
      AND "created_at" <= ${end}
    GROUP BY bucket
    ORDER BY bucket
  `;
}

export function findCoworkersForAgent(prisma, agentId) {
  return prisma.user.findMany({ where: { agentId, role: "COWORKER" }, select: { id: true } });
}

// One groupBy for however many coworkers an agent has, rather than a query
// per coworker. `type: { in: types }` keeps this to exactly the three event
// types the summary reports on (AD_CREATED / AD_SOLD / LEAD_CREATED) so an
// unrelated event type (e.g. a future OLX_CROSSPOST_* addition) can't
// silently start counting toward "deals closed".
export function coworkerEventCountsByType(prisma, agentId, types) {
  return prisma.activityEvent.groupBy({
    by: ["coworkerId", "type"],
    where: { agentId, coworkerId: { not: null }, type: { in: types } },
    _count: { _all: true },
  });
}

// Separate groupBy (not folded into the one above) because "last active"
// is a max over *every* event type, not just the three counted ones — a
// coworker whose only recent action was an OLX crosspost should still show
// as recently active even though that event type isn't one of the counts.
export function coworkerLastActiveAt(prisma, agentId) {
  return prisma.activityEvent.groupBy({
    by: ["coworkerId"],
    where: { agentId, coworkerId: { not: null } },
    _max: { createdAt: true },
  });
}
