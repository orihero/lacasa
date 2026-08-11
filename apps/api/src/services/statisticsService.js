import { EVENT_STAGE } from "../lib/enums.js";
import * as statisticsRepository from "../repositories/statisticsRepository.js";
import { httpError } from "../lib/httpError.js";
import { config } from "../lib/config.js";

const toSeconds = (date) => ({ seconds: Math.floor(new Date(date).getTime() / 1000) });

// ---- timezone-aware calendar math ------------------------------------------
//
// Everything below reads calendar fields (year/month/day/hour) off a real
// instant, or builds a real instant back out of calendar fields, always
// through an explicit IANA zone (`config.STATISTICS_TIMEZONE`) via `Intl`.
// Deliberately never `Date#getDate`/`getHours`/`setHours` etc: those read
// and write the *host process's* local zone, which is exactly the bug this
// file used to have (see the two-different-zones defect this replaces —
// dateRangeFor anchored to Node's local zone while the SQL bucketed in UTC).
// Using `Intl` with an explicit zone name means the result depends on
// config, not on where the process happens to be deployed or what its `TZ`
// env var says — see statisticsRepository.js#bucketedEventCounts's comment
// for the matching SQL-side half of this.

// The Y/M/D/H/M/S calendar fields `date` falls on when read in `timeZone`.
// Note this is a real timezone conversion (DST-aware if the zone observes
// DST, correct for a fractional-hour offset like UTC+5:30 too), not a
// fixed-offset shim — see config.js's STATISTICS_TIMEZONE comment for why a
// fixed Asia/Tashkent default is nonetheless exact for this product.
function zonedParts(date, timeZone) {
  const parts = new Intl.DateTimeFormat("en-US", {
    timeZone,
    hourCycle: "h23",
    year: "numeric",
    month: "2-digit",
    day: "2-digit",
    hour: "2-digit",
    minute: "2-digit",
    second: "2-digit",
  }).formatToParts(date);
  const out = {};
  for (const p of parts) if (p.type !== "literal") out[p.type] = Number(p.value);
  return out;
}

// The UTC offset (in minutes, local-minus-UTC) `timeZone` is in effect at
// `date`. Used only as the refinement step in `zonedTimeToUtc` below — see
// its comment for why one offset lookup is enough here.
function offsetMinutesAt(date, timeZone) {
  const p = zonedParts(date, timeZone);
  const asIfUTC = Date.UTC(p.year, p.month - 1, p.day, p.hour, p.minute, p.second);
  return Math.round((asIfUTC - date.getTime()) / 60000);
}

// The inverse of `zonedParts`: given calendar fields meant as a wall-clock
// time *in* `timeZone`, returns the real UTC instant they name. Standard
// two-pass trick for converting local time -> UTC without a bundled tz
// database: (1) naively reinterpret the wall-clock numbers as if they were
// already UTC to get a same-day guess instant, (2) look up the zone's real
// offset near that guess and subtract it. Two passes only matter across a
// DST transition (the offset just before vs. just after can differ); since
// STATISTICS_TIMEZONE defaults to Asia/Tashkent, which has run a constant
// UTC+5 with no DST since 1992, a single pass is already exact today. Kept
// as the general two-pass form (rather than a hardcoded +5:00) so this
// keeps working correctly if the zone is ever repointed at a DST-observing
// one — ordinary env config change, not a code change.
function zonedTimeToUtc(year, month, day, hour, minute, second, millisecond, timeZone) {
  const naiveUtc = Date.UTC(year, month - 1, day, hour, minute, second, millisecond);
  const offset = offsetMinutesAt(new Date(naiveUtc), timeZone);
  return new Date(naiveUtc - offset * 60000);
}

// today/thisWeek/thisMonth, anchored to STATISTICS_TIMEZONE's calendar
// (defaulting to Asia/Tashkent — see config.js). Reused as-is (never
// forked) by both the scalar /ads endpoint and the bucketed series below,
// so the two can never quietly drift apart on what "today" means; fixing
// this in place (rather than forking a second copy) is what keeps that
// true. The response *shape* of both endpoints is unchanged by this fix —
// only the instants "today"/"thisWeek"/"thisMonth" resolve to change,
// becoming correct regardless of the deploying host's local zone instead
// of happening to be right only when the process runs in Asia/Tashkent.
export function dateRangeFor(filterType, timeZone = config.STATISTICS_TIMEZONE) {
  const now = new Date();
  const { year, month, day } = zonedParts(now, timeZone);
  switch (filterType) {
    case "today": {
      const start = zonedTimeToUtc(year, month, day, 0, 0, 0, 0, timeZone);
      const end = zonedTimeToUtc(year, month, day, 23, 59, 59, 999, timeZone);
      return [start, end];
    }
    case "thisWeek": {
      // Day-of-week is pure calendar arithmetic on the local Y/M/D — it
      // never depends on a time-of-day or a zone, so building a throwaway
      // UTC-only Date from those three numbers and reading getUTCDay() back
      // off it is safe (and lets Date's own month/day overflow handling
      // carry a week across a month or year boundary for free).
      const dow = new Date(Date.UTC(year, month - 1, day)).getUTCDay();
      const weekStart = new Date(Date.UTC(year, month - 1, day - dow));
      const weekEnd = new Date(Date.UTC(year, month - 1, day - dow + 6));
      const start = zonedTimeToUtc(
        weekStart.getUTCFullYear(), weekStart.getUTCMonth() + 1, weekStart.getUTCDate(),
        0, 0, 0, 0, timeZone,
      );
      const end = zonedTimeToUtc(
        weekEnd.getUTCFullYear(), weekEnd.getUTCMonth() + 1, weekEnd.getUTCDate(),
        23, 59, 59, 999, timeZone,
      );
      return [start, end];
    }
    case "thisMonth": {
      const start = zonedTimeToUtc(year, month, 1, 0, 0, 0, 0, timeZone);
      // Day 0 of "next month" (0-indexed month math handles the year
      // rollover from December for free) is the last calendar day of this
      // month — the standard JS last-day-of-month trick.
      const lastDay = new Date(Date.UTC(year, month, 0)).getUTCDate();
      const end = zonedTimeToUtc(year, month, lastDay, 23, 59, 59, 999, timeZone);
      return [start, end];
    }
    default:
      return [null, null];
  }
}

// ---- GET /api/statistics/ads (unchanged HTTP contract) --------------------

export async function getAdsCounts(ctx, agentId, filterType) {
  const [start, end] = dateRangeFor(filterType);
  const range = start && end ? { gte: start, lte: end } : undefined;

  const [adsNewCount, adsSoldCount] = await Promise.all([
    statisticsRepository.countActivityEvents(ctx.prisma, { agentId, type: "AD_CREATED", range }),
    statisticsRepository.countActivityEvents(ctx.prisma, { agentId, type: "AD_SOLD", range }),
  ]);

  return { adsNewCount, adsSoldCount };
}

// ---- GET /api/statistics/coworkers (unchanged HTTP contract) --------------

export async function getCoworkerEvents(ctx, agentId) {
  const events = await statisticsRepository.findActivityEventsForAgent(ctx.prisma, agentId);
  return events.map((e) => ({
    id: e.id,
    agentId: e.agentId,
    coworkerId: e.coworkerId ?? "",
    adId: e.adId ?? "",
    leadId: e.leadId ?? "",
    stage: EVENT_STAGE[e.type],
    createdAt: toSeconds(e.createdAt),
  }));
}

// ---- GET /api/statistics/ads/series ----------------------------------------

const DAY_MS = 24 * 60 * 60 * 1000;

// A caller-supplied bucket count was rejected on purpose: it would let a
// client ask for, say, 5000 buckets over a decade-wide `from`/`to`, forcing
// a date_trunc('minute', ...) scale query over the whole table for a chart
// nobody could read anyway. Instead the bucket width follows the resolved
// range's own span, the same way a human picks a chart resolution: a
// same-day range reads best hour-by-hour (intraday activity is the whole
// point of looking at "today"), anything wider reads best day-by-day (a
// week or a month is naturally read as a daily trend, and 30*24 hourly bars
// would be unreadable). The boundary is "one calendar day's worth of span",
// which is exactly where today's dateRangeFor([start,end]) output (span
// just under 24h) and thisWeek/thisMonth's (span well over it) fall on
// either side.
export function granularityFor(start, end) {
  return end.getTime() - start.getTime() <= DAY_MS ? "hour" : "day";
}

// Truncates to the start of the STATISTICS_TIMEZONE hour/day containing
// `date`, expressed back as a real UTC instant. Deliberately the *same*
// zone the SQL side truncates in (see statisticsRepository.js#bucketedEventCounts's
// comment on the `AT TIME ZONE ... AT TIME ZONE` double conversion) so this
// grid lines up exactly with what the SQL side computed — this is the fix
// for the defect where the range was anchored to local calendar boundaries
// but the grid/SQL bucketed to UTC ones, padding in a spurious leading
// bucket whenever the two disagreed.
function truncateToZone(date, unit, timeZone) {
  const p = zonedParts(date, timeZone);
  return unit === "hour"
    ? zonedTimeToUtc(p.year, p.month, p.day, p.hour, 0, 0, 0, timeZone)
    : zonedTimeToUtc(p.year, p.month, p.day, 0, 0, 0, 0, timeZone);
}

function stepFor(unit) {
  return unit === "hour" ? 60 * 60 * 1000 : DAY_MS;
}

// How many buckets `buildBucketGrid` would produce for [start, end] at
// `unit`, computed in O(1) from the truncated endpoints rather than by
// building the grid. This has to exist as its own function (not just
// `buildBucketGrid(...).length`) so `getAdsSeries` can enforce
// MAX_SERIES_BUCKETS *before* allocating anything — see the constant's
// comment for why the check has to run here.
//
// Stepping by a fixed millisecond increment between two zone-truncated
// endpoints is exact as long as the zone's offset never changes between
// them — true for Asia/Tashkent (no DST since 1992) for any range this
// product would ever request. A DST-observing STATISTICS_TIMEZONE would
// need this (and buildBucketGrid) to re-truncate each step instead of
// adding a fixed offset, so a bucket doesn't end up 1 hour short/long on
// the two days of the year the clocks change.
function bucketCountFor(start, end, unit, timeZone) {
  const step = stepFor(unit);
  const first = truncateToZone(start, unit, timeZone).getTime();
  const last = truncateToZone(end, unit, timeZone).getTime();
  return Math.floor((last - first) / step) + 1;
}

// The full, contiguous list of bucket-start instants covering [start, end],
// truncated to `unit`. This is what makes the response zero-filled: every
// bucket in range exists in the output whether or not any event landed in
// it, so a chart never has to guess whether a gap means "zero" or "no data
// fetched for that slot".
function buildBucketGrid(start, end, unit, timeZone) {
  const step = stepFor(unit);
  const first = truncateToZone(start, unit, timeZone).getTime();
  const last = truncateToZone(end, unit, timeZone).getTime();
  const grid = [];
  for (let t = first; t <= last; t += step) grid.push(t);
  return grid;
}

// The largest bucket count a response will ever build. Chosen from what a
// chart can actually display, not from any storage/perf headroom: a month
// of hourly buckets is 744 (31*24) and a couple of years of daily buckets
// is ~730 (2*365) — the two widest ranges the granularity rule
// (granularityFor) would realistically hand back, since anything wider
// than a day already drops to daily buckets. 744 covers both with room to
// spare. This is what stands between `?from=0001-01-01&to=9999-01-01` (a
// real, reproduced request) and a ~3-million-element in-memory array: both
// dates individually parse as valid ISO timestamps, so nothing upstream of
// this check rejects that request on its own.
export const MAX_SERIES_BUCKETS = 744;

// filterType reuses dateRangeFor's existing vocabulary unchanged. An
// explicit from/to always wins over filterType when both are present (it's
// the more specific ask); when neither resolves to a bounded range —
// filterType absent/invalid *and* no from/to — we default to "today"
// rather than falling back to the scalar endpoint's "no range = all time"
// behavior, because an unbounded bucketed series has no sane bound on
// either the SQL group count or the response body size the way two plain
// COUNT(*)s do.
export function resolveSeriesRange(query, timeZone = config.STATISTICS_TIMEZONE) {
  const { filterType, from, to } = query;
  if (from && to) {
    const start = new Date(from);
    const end = new Date(to);
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
      throw httpError(400, "validation", "from and to must be valid dates");
    }
    if (start > end) {
      throw httpError(400, "validation", "from must not be after to");
    }
    return [start, end];
  }
  const [start, end] = dateRangeFor(filterType, timeZone);
  if (start && end) return [start, end];
  return dateRangeFor("today", timeZone);
}

export async function getAdsSeries(ctx, agentId, query, timeZone = config.STATISTICS_TIMEZONE) {
  const [start, end] = resolveSeriesRange(query, timeZone);
  const unit = granularityFor(start, end);

  // Enforced before building the grid and before either DB query — a
  // post-hoc check on `grid.length` would already have paid for the
  // allocation (and, if placed after the queries, the DB round trip) the
  // cap exists to avoid. Naming the actual limit lets a client narrow its
  // own request instead of guessing.
  const bucketCount = bucketCountFor(start, end, unit, timeZone);
  if (bucketCount > MAX_SERIES_BUCKETS) {
    throw httpError(
      400,
      "validation",
      `Requested range spans ${bucketCount} ${unit} buckets, over the ${MAX_SERIES_BUCKETS}-bucket maximum ` +
        "(about a month of hourly buckets or two years of daily buckets). Narrow the from/to range.",
    );
  }

  const grid = buildBucketGrid(start, end, unit, timeZone);

  const [createdRows, soldRows] = await Promise.all([
    statisticsRepository.bucketedEventCounts(ctx.prisma, { agentId, type: "AD_CREATED", start, end, unit, timeZone }),
    statisticsRepository.bucketedEventCounts(ctx.prisma, { agentId, type: "AD_SOLD", start, end, unit, timeZone }),
  ]);

  const createdByBucket = new Map(createdRows.map((r) => [new Date(r.bucket).getTime(), r.count]));
  const soldByBucket = new Map(soldRows.map((r) => [new Date(r.bucket).getTime(), r.count]));

  return {
    granularity: unit,
    from: toSeconds(start),
    to: toSeconds(end),
    buckets: grid.map((t) => ({
      bucketStart: toSeconds(t),
      adCreatedCount: createdByBucket.get(t) ?? 0,
      adSoldCount: soldByBucket.get(t) ?? 0,
    })),
  };
}

// ---- GET /api/statistics/coworkers/summary ---------------------------------

const SUMMARY_EVENT_TYPES = ["AD_CREATED", "AD_SOLD", "LEAD_CREATED"];

// One row per coworker of the effective agent, even one with zero activity
// (an idle coworker is a real fact worth showing as 0, not omitting) —
// which is why this starts from the coworker list, not from whatever rows
// happen to exist in the groupBy results.
export async function getCoworkerSummary(ctx, agentId) {
  const [coworkers, counts, lastActive] = await Promise.all([
    statisticsRepository.findCoworkersForAgent(ctx.prisma, agentId),
    statisticsRepository.coworkerEventCountsByType(ctx.prisma, agentId, SUMMARY_EVENT_TYPES),
    statisticsRepository.coworkerLastActiveAt(ctx.prisma, agentId),
  ]);

  const countKey = (coworkerId, type) => `${coworkerId}:${type}`;
  const countByTypeMap = new Map(counts.map((c) => [countKey(c.coworkerId, c.type), c._count._all]));
  const lastActiveMap = new Map(lastActive.map((r) => [r.coworkerId, r._max.createdAt]));

  return coworkers.map((c) => {
    const lastActiveAt = lastActiveMap.get(c.id);
    return {
      coworkerId: c.id,
      adsCreatedCount: countByTypeMap.get(countKey(c.id, "AD_CREATED")) ?? 0,
      adsSoldCount: countByTypeMap.get(countKey(c.id, "AD_SOLD")) ?? 0,
      leadsCreatedCount: countByTypeMap.get(countKey(c.id, "LEAD_CREATED")) ?? 0,
      // No fallback to a fabricated "never" value — a coworker who has
      // genuinely never triggered a tracked event gets `null`, and the
      // client is responsible for rendering that as "no activity yet"
      // rather than us inventing a timestamp.
      lastActiveAt: lastActiveAt ? toSeconds(lastActiveAt) : null,
    };
  });
}
