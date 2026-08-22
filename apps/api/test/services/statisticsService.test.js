import { afterEach, describe, expect, it, vi } from "vitest";
import { createFakePrisma } from "../helpers/testApp.js";
import * as statisticsService from "../../src/services/statisticsService.js";

describe("getAdsCounts", () => {
  it("counts AD_CREATED and AD_SOLD scoped to the agent, unranged when filterType is absent", async () => {
    const count = vi.fn().mockResolvedValue(3);
    const prisma = createFakePrisma({ activityEvent: { count } });

    const result = await statisticsService.getAdsCounts({ prisma }, "agent-1", undefined);

    expect(result).toEqual({ adsNewCount: 3, adsSoldCount: 3 });
    expect(count).toHaveBeenCalledWith({ where: { agentId: "agent-1", type: "AD_CREATED" } });
    expect(count).toHaveBeenCalledWith({ where: { agentId: "agent-1", type: "AD_SOLD" } });
  });

  it("adds a createdAt range when filterType is a recognized bucket", async () => {
    const count = vi.fn().mockResolvedValue(1);
    const prisma = createFakePrisma({ activityEvent: { count } });

    await statisticsService.getAdsCounts({ prisma }, "agent-1", "today");

    const args = count.mock.calls[0][0];
    expect(args.where.agentId).toBe("agent-1");

    // Asserting only `toBeInstanceOf(Date)` (what this test used to do)
    // would pass against any wrong-but-Date-typed instant — including the
    // local-vs-Tashkent mismatch that produced the 8-buckets-for-a-7-day-week
    // defect. Pin the actual boundary instead: whatever `dateRangeFor`
    // returns must be exactly midnight and exactly the last millisecond of
    // the same day *read in STATISTICS_TIMEZONE*, which is what the scalar
    // endpoint shares with /ads/series and what nothing else at this layer
    // checks.
    const wallClock = (d) =>
      new Intl.DateTimeFormat("en-GB", {
        timeZone: "Asia/Tashkent",
        hour12: false,
        year: "numeric",
        month: "2-digit",
        day: "2-digit",
        hour: "2-digit",
        minute: "2-digit",
        second: "2-digit",
      }).format(d);

    const { gte, lte } = args.where.createdAt;
    expect(wallClock(gte)).toMatch(/, 00:00:00$/);
    expect(wallClock(lte)).toMatch(/, 23:59:59$/);
    expect(lte.getTime() - gte.getTime()).toBe(24 * 60 * 60 * 1000 - 1);
    // Same calendar day on both ends — a range that spanned midnight would
    // still satisfy the two wall-clock assertions above on its own.
    expect(wallClock(gte).split(",")[0]).toBe(wallClock(lte).split(",")[0]);
  });
});

describe("getCoworkerEvents", () => {
  it("serializes raw activity events with the Firestore-shaped createdAt", async () => {
    const findMany = vi.fn().mockResolvedValue([
      {
        id: "evt-1",
        agentId: "agent-1",
        coworkerId: "coworker-1",
        adId: "ad-1",
        leadId: null,
        type: "AD_CREATED",
        createdAt: new Date("2026-01-01T00:00:00Z"),
      },
    ]);
    const prisma = createFakePrisma({ activityEvent: { findMany } });

    const events = await statisticsService.getCoworkerEvents({ prisma }, "agent-1");

    expect(findMany).toHaveBeenCalledWith({ where: { agentId: "agent-1" } });
    expect(events).toEqual([
      {
        id: "evt-1",
        agentId: "agent-1",
        coworkerId: "coworker-1",
        adId: "ad-1",
        leadId: "",
        stage: 1,
        createdAt: { seconds: 1767225600 },
      },
    ]);
  });
});

describe("granularityFor", () => {
  it("picks hourly buckets for a same-day span", () => {
    const start = new Date("2026-08-11T00:00:00.000Z");
    const end = new Date("2026-08-11T23:59:59.999Z");
    expect(statisticsService.granularityFor(start, end)).toBe("hour");
  });

  it("picks daily buckets once the span exceeds a day", () => {
    const start = new Date("2026-08-09T00:00:00.000Z");
    const end = new Date("2026-08-15T23:59:59.999Z");
    expect(statisticsService.granularityFor(start, end)).toBe("day");
  });
});

describe("resolveSeriesRange", () => {
  it("prefers explicit from/to over filterType", () => {
    const [start, end] = statisticsService.resolveSeriesRange({
      filterType: "thisMonth",
      from: "2026-08-01T00:00:00.000Z",
      to: "2026-08-02T00:00:00.000Z",
    });
    expect(start.toISOString()).toBe("2026-08-01T00:00:00.000Z");
    expect(end.toISOString()).toBe("2026-08-02T00:00:00.000Z");
  });

  it("rejects an invalid from/to pair", () => {
    expect(() => statisticsService.resolveSeriesRange({ from: "not-a-date", to: "2026-08-02T00:00:00.000Z" })).toThrow(
      /valid dates/,
    );
  });

  it("rejects from after to", () => {
    expect(() =>
      statisticsService.resolveSeriesRange({ from: "2026-08-03T00:00:00.000Z", to: "2026-08-02T00:00:00.000Z" }),
    ).toThrow(/must not be after/);
  });

  it("falls back to today when neither filterType nor from/to resolve to a bounded range", () => {
    const [start, end] = statisticsService.resolveSeriesRange({});
    const [todayStart, todayEnd] = statisticsService.dateRangeFor("today");
    expect(start.getTime()).toBe(todayStart.getTime());
    expect(end.getTime()).toBe(todayEnd.getTime());
  });
});

describe("getAdsSeries", () => {
  it("zero-fills every bucket in range and merges the two grouped queries by bucket instant", async () => {
    const queryRaw = vi.fn((_strings, ...values) => {
      // Tagged-template substitution order in statisticsRepository.js's SQL
      // is (unit, timeZone, timeZone, agentId, type, start, end) -- `unit`
      // once for date_trunc's first arg, `timeZone` twice (the "AT TIME
      // ZONE ... AT TIME ZONE ..." double conversion), then the WHERE
      // clause's own bindings. Use `type` (index 4) to route each of the
      // two calls (AD_CREATED / AD_SOLD) to its own canned rows, exactly
      // like two real GROUP BY queries would return different rows.
      const type = values[4];
      if (type === "AD_CREATED") {
        return Promise.resolve([
          { bucket: new Date("2026-08-11T00:00:00.000Z"), count: 2 },
          { bucket: new Date("2026-08-11T02:00:00.000Z"), count: 1 },
        ]);
      }
      return Promise.resolve([{ bucket: new Date("2026-08-11T01:00:00.000Z"), count: 4 }]);
    });
    const prisma = createFakePrisma({ $queryRaw: queryRaw });

    const result = await statisticsService.getAdsSeries(
      { prisma },
      "agent-1",
      { from: "2026-08-11T00:00:00.000Z", to: "2026-08-11T02:59:59.999Z" },
    );

    expect(result.granularity).toBe("hour");
    expect(result.buckets).toHaveLength(3);
    expect(result.buckets[0]).toEqual({ bucketStart: { seconds: 1786406400 }, adCreatedCount: 2, adSoldCount: 0 });
    expect(result.buckets[1]).toEqual({ bucketStart: { seconds: 1786410000 }, adCreatedCount: 0, adSoldCount: 4 });
    expect(result.buckets[2]).toEqual({ bucketStart: { seconds: 1786413600 }, adCreatedCount: 1, adSoldCount: 0 });
  });
});

describe("dateRangeFor / getAdsSeries — timezone regression", () => {
  // The original defect: dateRangeFor anchored the range to whatever zone
  // the Node *process* happened to run in (this dev box's Asia/Tashkent),
  // while the SQL side bucketed to UTC -- an 8th spurious bucket for a
  // 7-day week, a 32nd for a 31-day August. The fix routes both halves
  // through the single configured STATISTICS_TIMEZONE via `Intl`, which by
  // construction never reads the process's local zone. Running the same
  // assertion with the process forced into a zone west of UTC, a zone east
  // of UTC, and UTC itself is what actually proves that -- a suite that
  // only ever ran in one CI timezone couldn't tell "fixed" from "happens to
  // pass here", which is exactly how the original bug shipped.
  const originalTz = process.env.TZ;

  afterEach(() => {
    if (originalTz === undefined) delete process.env.TZ;
    else process.env.TZ = originalTz;
    vi.useRealTimers();
  });

  // A fixed instant in the middle of August so "thisMonth" has an
  // unambiguous, hand-checkable answer (August always has 31 days) and
  // "thisWeek" always resolves to a single 7-day span, regardless of which
  // zone "now" happens to be read in.
  const FIXED_NOW = new Date("2026-08-11T12:00:00.000Z");

  async function seriesBucketCount(filterType) {
    const prisma = createFakePrisma({ $queryRaw: vi.fn().mockResolvedValue([]) });
    const result = await statisticsService.getAdsSeries({ prisma }, "agent-1", { filterType });
    return result.buckets.length;
  }

  const PROCESS_ZONES = [
    ["America/Los_Angeles", "west of UTC"],
    ["Asia/Tokyo", "east of UTC"],
    ["UTC", "UTC itself"],
  ];

  it.each(PROCESS_ZONES)("thisWeek is exactly 7 daily buckets with the process in %s (%s)", async (tz) => {
    process.env.TZ = tz;
    vi.useFakeTimers();
    vi.setSystemTime(FIXED_NOW);

    expect(await seriesBucketCount("thisWeek")).toBe(7);
  });

  it.each(PROCESS_ZONES)("thisMonth (August) is exactly 31 daily buckets with the process in %s (%s)", async (tz) => {
    process.env.TZ = tz;
    vi.useFakeTimers();
    vi.setSystemTime(FIXED_NOW);

    expect(await seriesBucketCount("thisMonth")).toBe(31);
  });
});

describe("getAdsSeries — MAX_SERIES_BUCKETS cap (DoS guard)", () => {
  // Both the accepted-boundary and rejected-boundary ranges below are
  // computed at "day" granularity (span > 1 day, see granularityFor) since
  // that's the axis the reported DoS actually exploited: a same-day range
  // is capped at ~25 hourly buckets by granularityFor alone, so only wide
  // multi-day/year ranges can approach MAX_SERIES_BUCKETS.
  it("accepts the largest in-cap range (744 daily buckets) and still reaches the DB", async () => {
    const queryRaw = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ $queryRaw: queryRaw });

    const result = await statisticsService.getAdsSeries(
      { prisma },
      "agent-1",
      { from: "2024-01-01T00:00:00.000Z", to: "2026-01-13T23:59:59.999Z" },
      "UTC",
    );

    expect(result.granularity).toBe("day");
    expect(result.buckets).toHaveLength(statisticsService.MAX_SERIES_BUCKETS);
    expect(queryRaw).toHaveBeenCalled();
  });

  it("rejects one bucket beyond the cap with 400 validation naming the limit, without querying the DB", async () => {
    const queryRaw = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ $queryRaw: queryRaw });

    await expect(
      statisticsService.getAdsSeries(
        { prisma },
        "agent-1",
        { from: "2024-01-01T00:00:00.000Z", to: "2026-01-14T23:59:59.999Z" },
        "UTC",
      ),
    ).rejects.toMatchObject({
      status: 400,
      code: "validation",
      message: expect.stringContaining(String(statisticsService.MAX_SERIES_BUCKETS)),
    });
    expect(queryRaw).not.toHaveBeenCalled();
  });

  it("rejects the reported DoS range (year 1 to year 9999) without querying the DB", async () => {
    const queryRaw = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ $queryRaw: queryRaw });

    await expect(
      statisticsService.getAdsSeries(
        { prisma },
        "agent-1",
        { from: "0001-01-01T00:00:00.000Z", to: "9999-01-01T00:00:00.000Z" },
      ),
    ).rejects.toMatchObject({ status: 400, code: "validation" });
    expect(queryRaw).not.toHaveBeenCalled();
  });
});

describe("getCoworkerSummary", () => {
  it("returns one row per coworker, including a coworker with zero activity, and never mixes coworkers' counts", async () => {
    const findMany = vi.fn().mockResolvedValue([{ id: "coworker-1" }, { id: "coworker-2" }]);
    const groupBy = vi
      .fn()
      // First call: coworkerEventCountsByType
      .mockResolvedValueOnce([
        { coworkerId: "coworker-1", type: "AD_CREATED", _count: { _all: 5 } },
        { coworkerId: "coworker-1", type: "AD_SOLD", _count: { _all: 2 } },
        { coworkerId: "coworker-1", type: "LEAD_CREATED", _count: { _all: 1 } },
      ])
      // Second call: coworkerLastActiveAt
      .mockResolvedValueOnce([{ coworkerId: "coworker-1", _max: { createdAt: new Date("2026-08-01T00:00:00Z") } }]);
    const prisma = createFakePrisma({ user: { findMany }, activityEvent: { groupBy } });

    const summary = await statisticsService.getCoworkerSummary({ prisma }, "agent-1");

    expect(summary).toEqual([
      {
        coworkerId: "coworker-1",
        adsCreatedCount: 5,
        adsSoldCount: 2,
        leadsCreatedCount: 1,
        lastActiveAt: { seconds: Math.floor(new Date("2026-08-01T00:00:00Z").getTime() / 1000) },
      },
      {
        coworkerId: "coworker-2",
        adsCreatedCount: 0,
        adsSoldCount: 0,
        leadsCreatedCount: 0,
        lastActiveAt: null,
      },
    ]);
  });
});
