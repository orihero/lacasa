import { describe, expect, it } from "vitest";
import supertest from "supertest";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";
import regionsData from "@lacasa/domain/data/regions";

// GET /api/regions never touches the database (it serves a static import
// from @lacasa/domain), but createApp() still wants a real prisma client to
// construct req.ctx, so this uses the same useIntegrationDb() harness as
// every other *.integration.test.js file rather than a bespoke fake.
const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

describe("GET /api/regions", () => {
  it("returns the full 14-region, 203-district vocabulary with no auth header", async () => {
    const res = await supertest(app).get("/api/regions");

    expect(res.status).toBe(200);
    expect(res.body.regions).toHaveLength(14);
    expect(res.body.districts).toHaveLength(203);
    // Cross-check against the source of truth directly rather than just
    // the counts, so this fails loudly if the route ever serves a stale
    // copy instead of importing @lacasa/domain live.
    expect(res.body.regions).toEqual(regionsData.regions);
    expect(res.body.districts).toEqual(regionsData.districts);
  });

  it("sets a long-lived Cache-Control and an ETag, and honours a conditional request with 304", async () => {
    const first = await supertest(app).get("/api/regions");

    expect(first.status).toBe(200);
    expect(first.headers["cache-control"]).toBe("public, max-age=86400");
    expect(first.headers.etag).toBeTruthy();

    const second = await supertest(app).get("/api/regions").set("If-None-Match", first.headers.etag);

    expect(second.status).toBe(304);
    // A 304 must not repeat the body — that's the whole point of the
    // conditional request saving bandwidth.
    expect(second.text).toBeFalsy();
  });

  it("filters to a single region's districts when ?regionId= is given", async () => {
    const someRegion = regionsData.regions[0];
    const expectedDistricts = regionsData.districts.filter((d) => d.region_id === someRegion.id);

    const res = await supertest(app).get("/api/regions").query({ regionId: someRegion.id });

    expect(res.status).toBe(200);
    expect(res.body.regions).toEqual([someRegion]);
    expect(res.body.districts).toEqual(expectedDistricts);
    expect(res.body.districts.length).toBeGreaterThan(0);
  });

  it("answers 200 with empty arrays for a regionId that matches nothing, rather than erroring", async () => {
    const res = await supertest(app).get("/api/regions").query({ regionId: 999999 });

    expect(res.status).toBe(200);
    expect(res.body.regions).toEqual([]);
    expect(res.body.districts).toEqual([]);
  });
});
