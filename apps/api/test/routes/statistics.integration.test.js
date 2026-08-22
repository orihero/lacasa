import { describe, expect, it, beforeAll } from "vitest";
import supertest from "supertest";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";
import { createUser, authHeader } from "../integration/helpers/factories.js";

const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

// No route creates a raw ActivityEvent directly with an arbitrary
// `createdAt` (every real one is stamped `now()` by lib/activity.js as a
// side effect of creating an ad/lead), so bucket-boundary tests need
// millisecond-exact control that only a direct row insert gives us.
function createEvent({ agentId, coworkerId = null, type, createdAt }) {
  return prisma.activityEvent.create({ data: { agentId, coworkerId, type, createdAt } });
}

describe("statistics auth", () => {
  let plainUser;

  beforeAll(async () => {
    plainUser = await createUser(prisma, { role: "USER", email: "stats-plain-user@example.test" });
  });

  it("401s both new endpoints without auth", async () => {
    expect((await supertest(app).get("/api/statistics/ads/series")).status).toBe(401);
    expect((await supertest(app).get("/api/statistics/coworkers/summary")).status).toBe(401);
  });

  it("403s both new endpoints for a role with no agent scope (plain USER)", async () => {
    const series = await supertest(app).get("/api/statistics/ads/series").set("Authorization", authHeader(plainUser));
    expect(series.status).toBe(403);
    expect(series.body.error.code).toBe("forbidden");

    const summary = await supertest(app).get("/api/statistics/coworkers/summary").set("Authorization", authHeader(plainUser));
    expect(summary.status).toBe(403);
    expect(summary.body.error.code).toBe("forbidden");
  });
});

describe("GET /api/statistics/ads/series — hourly buckets, zero-fill, agent scoping", () => {
  let agentA, agentB;

  beforeAll(async () => {
    agentA = await createUser(prisma, { role: "AGENT", email: "stats-series-agent-a@example.test" });
    agentB = await createUser(prisma, { role: "AGENT", email: "stats-series-agent-b@example.test" });

    // Exactly at the range's start and end instants -- must land in bucket 0
    // and bucket 23 respectively, not fall just outside the range.
    await createEvent({ agentId: agentA.id, type: "AD_CREATED", createdAt: new Date("2024-01-01T00:00:00.000Z") });
    await createEvent({ agentId: agentA.id, type: "AD_SOLD", createdAt: new Date("2024-01-01T23:59:59.999Z") });
    // Hour 1 gets nothing -- this is the gap the zero-fill assertion checks.
    await createEvent({ agentId: agentA.id, type: "AD_CREATED", createdAt: new Date("2024-01-01T02:30:00.000Z") });

    // Same instant, but a different agent entirely -- must never appear in agentA's series.
    await createEvent({ agentId: agentB.id, type: "AD_CREATED", createdAt: new Date("2024-01-01T02:30:00.000Z") });
  });

  it("buckets hourly (span <= 1 day), zero-fills gaps, and excludes another agent's events", async () => {
    const res = await supertest(app)
      .get("/api/statistics/ads/series")
      .query({ from: "2024-01-01T00:00:00.000Z", to: "2024-01-01T23:59:59.999Z" })
      .set("Authorization", authHeader(agentA));

    expect(res.status).toBe(200);
    expect(res.body.granularity).toBe("hour");
    expect(res.body.buckets).toHaveLength(24);

    expect(res.body.buckets[0].adCreatedCount).toBe(1); // 00:00:00.000 boundary event
    expect(res.body.buckets[0].adSoldCount).toBe(0);
    expect(res.body.buckets[1].adCreatedCount).toBe(0); // zero-filled gap hour
    expect(res.body.buckets[1].adSoldCount).toBe(0);
    expect(res.body.buckets[2].adCreatedCount).toBe(1); // agentA's own 02:30 event only
    expect(res.body.buckets[23].adSoldCount).toBe(1); // 23:59:59.999 boundary event
  });
});

describe("GET /api/statistics/ads/series — daily buckets and boundary correctness", () => {
  let agent;

  // STATISTICS_TIMEZONE defaults to Asia/Tashkent (UTC+5), so a "day" in
  // this endpoint's terms is a Tashkent calendar day, not a UTC one. Local
  // Feb 1 00:00:00.000 is 2024-01-31T19:00:00.000Z, and local Feb 8
  // 23:59:59.999 is 2024-02-08T18:59:59.999Z -- deliberately *not*
  // 2024-02-01T00:00:00.000Z/2024-02-08T23:59:59.999Z (those are UTC-day
  // boundaries, 5 hours into the *next* Tashkent calendar day at the tail
  // end), which is exactly the defect this test now guards against: before
  // the fix, feeding UTC-day boundaries in here produced a 9th spurious
  // bucket because the range resolved in one zone while the grid/SQL
  // bucketed in another.
  const FEB_1_LOCAL_START = new Date("2024-01-31T19:00:00.000Z");
  const FEB_8_LOCAL_END = new Date("2024-02-08T18:59:59.999Z");

  beforeAll(async () => {
    agent = await createUser(prisma, { role: "AGENT", email: "stats-series-daily-agent@example.test" });
    await createEvent({ agentId: agent.id, type: "AD_CREATED", createdAt: FEB_1_LOCAL_START });
    await createEvent({ agentId: agent.id, type: "AD_SOLD", createdAt: FEB_8_LOCAL_END });
  });

  it("switches to daily buckets once the span exceeds a day, boundary events in the first/last day, no spurious padding bucket", async () => {
    const res = await supertest(app)
      .get("/api/statistics/ads/series")
      .query({ from: FEB_1_LOCAL_START.toISOString(), to: FEB_8_LOCAL_END.toISOString() })
      .set("Authorization", authHeader(agent));

    expect(res.status).toBe(200);
    expect(res.body.granularity).toBe("day");
    // Exactly 8 -- the reported defect padded in a 9th all-zero bucket here
    // by truncating the UTC-anchored range to a UTC calendar day while the
    // events (and this range) sit on Tashkent calendar days.
    expect(res.body.buckets).toHaveLength(8);
    expect(res.body.buckets[0].adCreatedCount).toBe(1);
    expect(res.body.buckets[7].adSoldCount).toBe(1);
  });
});

describe("GET /api/statistics/ads/series — filterType default-zone regression (STATISTICS_TIMEZONE)", () => {
  // Direct reproduction, against the real database, of the two numbers
  // named in the defect report: filterType=thisWeek must come back with
  // exactly 7 buckets for a 7-day week (the reported bug returned 8), and
  // filterType=thisMonth must match the real number of days in the current
  // Tashkent calendar month (the reported bug returned 32 for a 31-day
  // August). Exercises the full route -> service -> real Postgres
  // `date_trunc(... AT TIME ZONE ...) AT TIME ZONE ...` path end to end,
  // rather than a mocked $queryRaw -- this is the level the original
  // "8 buckets for a 7-day week" repro was observed at.
  let agent;

  beforeAll(async () => {
    agent = await createUser(prisma, { role: "AGENT", email: "stats-series-tz-default-agent@example.test" });
  });

  it("filterType=thisWeek is exactly 7 daily buckets", async () => {
    const res = await supertest(app)
      .get("/api/statistics/ads/series")
      .query({ filterType: "thisWeek" })
      .set("Authorization", authHeader(agent));

    expect(res.status).toBe(200);
    expect(res.body.granularity).toBe("day");
    expect(res.body.buckets).toHaveLength(7);
  });

  it("filterType=thisMonth matches the real day count of the current month in Asia/Tashkent", async () => {
    const res = await supertest(app)
      .get("/api/statistics/ads/series")
      .query({ filterType: "thisMonth" })
      .set("Authorization", authHeader(agent));

    expect(res.status).toBe(200);
    expect(res.body.granularity).toBe("day");

    // Independent oracle for "how many days does this month actually have,
    // read in Asia/Tashkent" -- computed fresh here, not by calling back
    // into statisticsService's own helpers, so this can't pass by just
    // restating the implementation.
    const parts = new Intl.DateTimeFormat("en-US", { timeZone: "Asia/Tashkent", year: "numeric", month: "2-digit" })
      .formatToParts(new Date())
      .reduce((acc, p) => {
        if (p.type !== "literal") acc[p.type] = Number(p.value);
        return acc;
      }, {});
    const daysInMonth = new Date(Date.UTC(parts.year, parts.month, 0)).getUTCDate();

    expect(res.body.buckets).toHaveLength(daysInMonth);
  });
});

describe("GET /api/statistics/ads/series — validation", () => {
  let agent;

  beforeAll(async () => {
    agent = await createUser(prisma, { role: "AGENT", email: "stats-series-validation-agent@example.test" });
  });

  it("400s when from is after to", async () => {
    const res = await supertest(app)
      .get("/api/statistics/ads/series")
      .query({ from: "2024-01-02T00:00:00.000Z", to: "2024-01-01T00:00:00.000Z" })
      .set("Authorization", authHeader(agent));
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });

  // The reported DoS: both dates individually parse as valid ISO
  // timestamps, so nothing before the bucket-count cap rejects this
  // request -- end to end through the real route, this must still 400
  // rather than build the ~2.96M-element grid the unmocked repro produced.
  // The "and it happens before touching the DB" half of this is asserted
  // at the unit level (statisticsService.test.js) against a mocked
  // $queryRaw, since that's the only layer that can observe "no DB round
  // trip" directly.
  it("400s a request that would exceed MAX_SERIES_BUCKETS, naming the limit", async () => {
    const res = await supertest(app)
      .get("/api/statistics/ads/series")
      .query({ from: "0001-01-01T00:00:00.000Z", to: "9999-01-01T00:00:00.000Z" })
      .set("Authorization", authHeader(agent));
    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
    expect(res.body.error.message).toMatch(/744/);
  });
});

// The scalar endpoint shares `dateRangeFor` with /ads/series, and that
// sharing is the stated reason the function was never forked when the
// series endpoint was added. Nothing verified it end to end, though: every
// test above drives the series route, so a change that kept the (heavily
// covered) series path correct while breaking the scalar route's date
// filtering would have shipped silently. These two tests close that hole at
// the level the shared-ness actually matters -- the real route, against the
// real database, through the real STATISTICS_TIMEZONE plumbing.
describe("GET /api/statistics/ads — the scalar endpoint sharing dateRangeFor", () => {
  let agent, startOfTodayTashkent;

  // Independent oracle for "the UTC instant at which today began in
  // Asia/Tashkent", derived from Intl rather than by calling back into
  // statisticsService's own zone helpers -- restating the implementation
  // would make this test pass for the wrong reason. Deliberately does not
  // hardcode +5: the zone's offset is read from Intl at the instant under
  // test, so this keeps working if the zone database ever changes under us.
  function zoneOffsetMs(timeZone, at) {
    const parts = new Intl.DateTimeFormat("en-US", {
      timeZone,
      hour12: false,
      year: "numeric",
      month: "2-digit",
      day: "2-digit",
      hour: "2-digit",
      minute: "2-digit",
      second: "2-digit",
    })
      .formatToParts(at)
      .reduce((acc, p) => {
        if (p.type !== "literal") acc[p.type] = Number(p.value);
        return acc;
      }, {});
    const wallClockAsUtc = Date.UTC(parts.year, parts.month - 1, parts.day, parts.hour % 24, parts.minute, parts.second);
    return wallClockAsUtc - Math.floor(at.getTime() / 1000) * 1000;
  }

  beforeAll(async () => {
    agent = await createUser(prisma, { role: "AGENT", email: "stats-scalar-agent@example.test" });

    const now = new Date();
    const offset = zoneOffsetMs("Asia/Tashkent", now);
    const local = new Date(now.getTime() + offset);
    startOfTodayTashkent = new Date(
      Date.UTC(local.getUTCFullYear(), local.getUTCMonth(), local.getUTCDate()) - offset,
    );

    // The pair that pins the boundary: one event exactly at local midnight
    // (inside "today") and one 1ms before it (outside). Under the pre-fix
    // UTC-vs-local split these two straddled the wrong line entirely.
    await createEvent({ agentId: agent.id, type: "AD_CREATED", createdAt: startOfTodayTashkent });
    await createEvent({
      agentId: agent.id,
      type: "AD_CREATED",
      createdAt: new Date(startOfTodayTashkent.getTime() - 1),
    });
    await createEvent({ agentId: agent.id, type: "AD_SOLD", createdAt: startOfTodayTashkent });
  });

  it("filterType=today counts from Tashkent-local midnight, excluding the event 1ms before it", async () => {
    const res = await supertest(app)
      .get("/api/statistics/ads")
      .query({ filterType: "today" })
      .set("Authorization", authHeader(agent));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ adsNewCount: 1, adsSoldCount: 1 });
  });

  it("no filterType leaves the range unbounded, picking up the event before midnight too", async () => {
    const res = await supertest(app).get("/api/statistics/ads").set("Authorization", authHeader(agent));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({ adsNewCount: 2, adsSoldCount: 1 });
  });
});

describe("GET /api/statistics/coworkers/summary", () => {
  let agentA, agentB, coworkerA1, coworkerA2, coworkerB1;

  beforeAll(async () => {
    agentA = await createUser(prisma, { role: "AGENT", email: "stats-summary-agent-a@example.test" });
    agentB = await createUser(prisma, { role: "AGENT", email: "stats-summary-agent-b@example.test" });
    coworkerA1 = await createUser(prisma, { role: "COWORKER", agentId: agentA.id, email: "stats-summary-coworker-a1@example.test" });
    coworkerA2 = await createUser(prisma, { role: "COWORKER", agentId: agentA.id, email: "stats-summary-coworker-a2@example.test" });
    coworkerB1 = await createUser(prisma, { role: "COWORKER", agentId: agentB.id, email: "stats-summary-coworker-b1@example.test" });

    // coworkerA1: 2 ads created, 1 sold, 1 lead created.
    await createEvent({ agentId: agentA.id, coworkerId: coworkerA1.id, type: "AD_CREATED", createdAt: new Date("2024-03-01T00:00:00Z") });
    await createEvent({ agentId: agentA.id, coworkerId: coworkerA1.id, type: "AD_CREATED", createdAt: new Date("2024-03-02T00:00:00Z") });
    await createEvent({ agentId: agentA.id, coworkerId: coworkerA1.id, type: "AD_SOLD", createdAt: new Date("2024-03-03T00:00:00Z") });
    await createEvent({ agentId: agentA.id, coworkerId: coworkerA1.id, type: "LEAD_CREATED", createdAt: new Date("2024-03-04T00:00:00Z") });

    // coworkerA2 has no events at all — must still show up, zeroed.

    // coworkerB1 belongs to a different agent entirely — must never leak into agentA's summary.
    await createEvent({ agentId: agentB.id, coworkerId: coworkerB1.id, type: "AD_CREATED", createdAt: new Date("2024-03-01T00:00:00Z") });
  });

  it("returns one row per coworker with per-coworker aggregates, including an idle coworker at zero", async () => {
    const res = await supertest(app).get("/api/statistics/coworkers/summary").set("Authorization", authHeader(agentA));
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(2);

    const a1 = res.body.find((r) => r.coworkerId === coworkerA1.id);
    expect(a1.adsCreatedCount).toBe(2);
    expect(a1.adsSoldCount).toBe(1);
    expect(a1.leadsCreatedCount).toBe(1);
    expect(a1.lastActiveAt.seconds).toBe(Math.floor(new Date("2024-03-04T00:00:00Z").getTime() / 1000));

    const a2 = res.body.find((r) => r.coworkerId === coworkerA2.id);
    expect(a2).toEqual({
      coworkerId: coworkerA2.id,
      adsCreatedCount: 0,
      adsSoldCount: 0,
      leadsCreatedCount: 0,
      lastActiveAt: null,
    });

    expect(res.body.some((r) => r.coworkerId === coworkerB1.id)).toBe(false);
  });

  it("a coworker caller sees the same agent-scoped summary as their agent", async () => {
    const res = await supertest(app).get("/api/statistics/coworkers/summary").set("Authorization", authHeader(coworkerA1));
    expect(res.status).toBe(200);
    expect(res.body).toHaveLength(2);
    expect(res.body.every((r) => r.coworkerId === coworkerA1.id || r.coworkerId === coworkerA2.id)).toBe(true);
  });
});
