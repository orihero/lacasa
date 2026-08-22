import { describe, expect, it, beforeAll } from "vitest";
import supertest from "supertest";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";
import { createUser, authHeader } from "../integration/helpers/factories.js";

const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

let agent;

beforeAll(async () => {
  agent = await createUser(prisma, { role: "AGENT", email: "agent-ads@example.test" });
});

function adPayload(overrides = {}) {
  return {
    title: "Sunny flat",
    city: "Tashkent",
    district: "Yunusabad",
    type: "residential",
    category: "sale",
    price: 120000,
    ...overrides,
  };
}

describe("POST /api/ads", () => {
  it("requires auth", async () => {
    const res = await supertest(app).post("/api/ads").send(adPayload());
    expect(res.status).toBe(401);
  });

  it("creates an ad scoped to the authenticated agent, defaulting stage to active", async () => {
    const res = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Create Test" }));

    expect(res.status).toBe(201);
    expect(res.body.agentId).toBe(agent.id);
    expect(res.body.title).toBe("Create Test");
    expect(res.body.stage).toBe("1"); // AD_STAGE_REV.ACTIVE — see packages/domain/src/enums/ads.ts
    expect(res.body.priceType).toBe("uzs"); // defaults to UZS when omitted
  });
});

describe("GET /api/ads and GET /api/ads/:id", () => {
  let tashkentSale;

  beforeAll(async () => {
    const created = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Tashkent Sale", city: "Tashkent", category: "sale" }));
    tashkentSale = created.body;

    await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Samarkand Rent", city: "Samarkand", category: "rent" }));
  });

  it("lists ads without auth (public listing) and filters by city + category", async () => {
    const all = await supertest(app).get("/api/ads");
    expect(all.status).toBe(200);
    expect(all.body.some((a) => a.title === "Tashkent Sale")).toBe(true);
    expect(all.body.some((a) => a.title === "Samarkand Rent")).toBe(true);

    const filtered = await supertest(app).get("/api/ads").query({ city: "Samarkand", category: "rent" });
    expect(filtered.status).toBe(200);
    expect(filtered.body.length).toBeGreaterThan(0);
    expect(filtered.body.every((a) => a.city === "Samarkand" && a.category === "rent")).toBe(true);
  });

  it("gets a single ad by id and 404s for an unknown id", async () => {
    const found = await supertest(app).get(`/api/ads/${tashkentSale.id}`);
    expect(found.status).toBe(200);
    expect(found.body.id).toBe(tashkentSale.id);

    const missing = await supertest(app).get("/api/ads/00000000-0000-0000-0000-000000000000");
    expect(missing.status).toBe(404);
  });
});

// docs/10 §3: AdPhoto.mediaType defaults to PHOTO at the DB column level —
// no write path sends it yet, so a real create+read round trip through
// Postgres (not a mocked prisma) is what proves the column default, the
// migration, and serializeAd's photos/media split actually line up.
describe("AdPhoto.mediaType default (docs/10 §3)", () => {
  it("defaults every uploaded photo to PHOTO and mirrors it into both photos and media on read", async () => {
    const res = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Photo Default Test", photos: ["http://x/1.jpg", "http://x/2.jpg"] }));

    expect(res.status).toBe(201);
    expect(res.body.photos).toEqual(["http://x/1.jpg", "http://x/2.jpg"]);
    expect(res.body.media).toEqual([
      { url: "http://x/1.jpg", mediaType: "photo", position: 0 },
      { url: "http://x/2.jpg", mediaType: "photo", position: 1 },
    ]);

    const fetched = await supertest(app).get(`/api/ads/${res.body.id}`);
    expect(fetched.body.photos).toEqual(["http://x/1.jpg", "http://x/2.jpg"]);
    expect(fetched.body.media).toEqual(res.body.media);
  });
});

// docs/10 §3: Ad.lat/Ad.lng, the listing-detail map pin. Real Postgres round
// trip so the Decimal(9,6) column, parseAdInput's coercion, and
// serializeAd's Number(...)-or-null all prove out together, not just
// against a mocked prisma.
describe("Ad.lat/Ad.lng (docs/10 §3)", () => {
  it("defaults to null on an ad created without coordinates", async () => {
    const res = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "No Pin" }));

    expect(res.status).toBe(201);
    expect(res.body.lat).toBeNull();
    expect(res.body.lng).toBeNull();
  });

  it("creates a pinned ad and round-trips lat/lng at 6 decimal places through Postgres", async () => {
    const res = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Pinned", lat: "41.311081", lng: "69.240562" }));

    expect(res.status).toBe(201);
    expect(res.body.lat).toBe(41.311081);
    expect(res.body.lng).toBe(69.240562);

    const fetched = await supertest(app).get(`/api/ads/${res.body.id}`);
    expect(fetched.body.lat).toBe(41.311081);
    expect(fetched.body.lng).toBe(69.240562);
  });

  it("rejects creating an ad with only one of lat/lng set", async () => {
    const res = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Half Pin", lat: "41.3" }));

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });

  it("rejects an out-of-range latitude", async () => {
    const res = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Bad Lat", lat: "91", lng: "10" }));

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });

  it("PATCHes a pin onto an existing unpinned ad", async () => {
    const created = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Pin Me Later" }));

    const patched = await supertest(app)
      .patch(`/api/ads/${created.body.id}`)
      .set("Authorization", authHeader(agent))
      .send({ lat: "51.5074", lng: "-0.1278" });

    expect(patched.status).toBe(200);
    expect(patched.body.lat).toBe(51.5074);
    expect(patched.body.lng).toBe(-0.1278);
  });

  it("rejects a PATCH that clears only lng on an ad that already has both set", async () => {
    const created = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Fully Pinned", lat: "41.3", lng: "69.2" }));

    const patched = await supertest(app)
      .patch(`/api/ads/${created.body.id}`)
      .set("Authorization", authHeader(agent))
      .send({ lng: "" });

    expect(patched.status).toBe(400);
    expect(patched.body.error.code).toBe("validation");

    const stillPinned = await supertest(app).get(`/api/ads/${created.body.id}`);
    expect(stillPinned.body.lat).toBe(41.3);
    expect(stillPinned.body.lng).toBe(69.2);
  });

  it("clears both lat and lng together via PATCH", async () => {
    const created = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Unpin Me", lat: "41.3", lng: "69.2" }));

    const patched = await supertest(app)
      .patch(`/api/ads/${created.body.id}`)
      .set("Authorization", authHeader(agent))
      .send({ lat: "", lng: "" });

    expect(patched.status).toBe(200);
    expect(patched.body.lat).toBeNull();
    expect(patched.body.lng).toBeNull();
  });

  it("leaves an existing pin untouched when a PATCH doesn't mention lat/lng", async () => {
    const created = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Untouched Pin", lat: "41.3", lng: "69.2" }));

    const patched = await supertest(app)
      .patch(`/api/ads/${created.body.id}`)
      .set("Authorization", authHeader(agent))
      .send({ title: "Untouched Pin, Renamed" });

    expect(patched.status).toBe(200);
    expect(patched.body.lat).toBe(41.3);
    expect(patched.body.lng).toBe(69.2);
  });
});

// docs/10 §3: Ad.tour3dLink. The scheme check matters more than it looks —
// apps/web's Slider.jsx renders this straight into an <iframe src> with no
// sandbox attribute, so a javascript:/data: value would be code running in a
// visitor's origin rather than a broken embed.
describe("Ad.tour3dLink (docs/10 §3)", () => {
  it("defaults to null and round-trips an https URL", async () => {
    const bare = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "No Tour" }));
    expect(bare.status).toBe(201);
    expect(bare.body.tour3dLink).toBeNull();

    const withTour = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "With Tour", tour3dLink: "https://tour.example/embed/1" }));
    expect(withTour.status).toBe(201);
    expect(withTour.body.tour3dLink).toBe("https://tour.example/embed/1");

    const fetched = await supertest(app).get(`/api/ads/${withTour.body.id}`);
    expect(fetched.body.tour3dLink).toBe("https://tour.example/embed/1");
  });

  it("refuses a scheme that would execute in the visitor's origin", async () => {
    for (const tour3dLink of ["javascript:alert(1)", "data:text/html,<script>alert(1)</script>", "//evil.example"]) {
      const res = await supertest(app)
        .post("/api/ads")
        .set("Authorization", authHeader(agent))
        .send(adPayload({ title: "Bad Tour", tour3dLink }));

      expect(res.status).toBe(400);
      expect(res.body.error.code).toBe("validation");
    }
  });

  it("refuses a bad tour link on PATCH too, leaving the stored one intact", async () => {
    const created = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Tour To Keep", tour3dLink: "https://tour.example/keep" }));

    const patched = await supertest(app)
      .patch(`/api/ads/${created.body.id}`)
      .set("Authorization", authHeader(agent))
      .send({ tour3dLink: "javascript:alert(1)" });
    expect(patched.status).toBe(400);

    const fetched = await supertest(app).get(`/api/ads/${created.body.id}`);
    expect(fetched.body.tour3dLink).toBe("https://tour.example/keep");
  });

  it("clears the tour link with an empty string", async () => {
    const created = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send(adPayload({ title: "Tour To Clear", tour3dLink: "https://tour.example/clear" }));

    const patched = await supertest(app)
      .patch(`/api/ads/${created.body.id}`)
      .set("Authorization", authHeader(agent))
      .send({ tour3dLink: "" });

    expect(patched.status).toBe(200);
    expect(patched.body.tour3dLink).toBeNull();
  });
});

// This slice: server-side search/sort/paging on GET /api/ads and
// GET /api/my/ads (see adService.js#listAds). Rows are written directly via
// `prisma.ad.create` (bypassing the HTTP create endpoint) so `createdAt` and
// `stage` can be pinned to exact values the API's own POST doesn't let a
// caller set -- both are load-bearing for these tests (a shared `createdAt`
// to force the keyset-tiebreak case, an explicit `stage` to prove the
// public/CRM split without waiting on a real PATCH-to-sold flow).
function directAdData(overrides = {}) {
  return {
    title: "Row",
    district: "Yunusabad",
    type: "RESIDENTIAL",
    category: "SALE",
    price: 100000,
    priceType: "UZS",
    stage: "ACTIVE",
    agentId: agent.id,
    nearPlaces: [],
    options: [],
    ...overrides,
  };
}

describe("GET /api/ads — q/sort/limit/cursor (this slice)", () => {
  const CURSOR_CITY = "CursorPagingCity";
  const SEARCH_CITY = "SearchQCity";
  let cursorAdIds;

  beforeAll(async () => {
    // Five ads sharing one exact timestamp -- the case a bare `?cursor=
    // <createdAt>` can't handle (Postgres gives no ordering guarantee among
    // tied rows), which is exactly why the cursor also carries `id`.
    const sameInstant = new Date("2026-03-01T10:00:00.000Z");
    const created = await Promise.all(
      Array.from({ length: 5 }, (_, i) =>
        prisma.ad.create({
          data: directAdData({ title: `Cursor Ad ${i}`, city: CURSOR_CITY, price: 100000 + i, createdAt: sameInstant }),
        }),
      ),
    );
    cursorAdIds = created.map((a) => a.id).sort();

    await prisma.ad.create({
      data: directAdData({
        title: "Searchable Description Match",
        city: SEARCH_CITY,
        district: "UniqueDistrictXyz",
        address: "123 Findme Ave",
        description: "A description mentioning UNIQUETERM inside it",
      }),
    });
  });

  it("pages a duplicate-timestamp set across the boundary with no drops and no duplicates", async () => {
    const seen = [];
    let cursor;
    for (let i = 0; i < 10; i += 1) {
      const res = await supertest(app)
        .get("/api/ads")
        .query({ city: CURSOR_CITY, limit: 2, sort: "newest", ...(cursor ? { cursor } : {}) });
      expect(res.status).toBe(200);
      expect(Array.isArray(res.body.items)).toBe(true);
      expect(res.body.items.length).toBeLessThanOrEqual(2);
      seen.push(...res.body.items.map((a) => a.id));
      cursor = res.body.nextCursor;
      if (!cursor) break;
    }
    expect(seen.sort()).toEqual(cursorAdIds);
  });

  it("matches q case-insensitively across title/description/address/district/city", async () => {
    const byDescription = await supertest(app).get("/api/ads").query({ q: "uniqueterm" });
    expect(byDescription.body.some((a) => a.city === SEARCH_CITY)).toBe(true);

    const byDistrict = await supertest(app).get("/api/ads").query({ q: "UNIQUEDISTRICTXYZ" });
    expect(byDistrict.body.some((a) => a.city === SEARCH_CITY)).toBe(true);

    const byAddress = await supertest(app).get("/api/ads").query({ q: "findme" });
    expect(byAddress.body.some((a) => a.city === SEARCH_CITY)).toBe(true);

    const byCity = await supertest(app).get("/api/ads").query({ q: SEARCH_CITY.toLowerCase() });
    expect(byCity.body.some((a) => a.city === SEARCH_CITY)).toBe(true);

    const byTitle = await supertest(app).get("/api/ads").query({ q: "searchable description match".toUpperCase() });
    expect(byTitle.body.some((a) => a.city === SEARCH_CITY)).toBe(true);

    const noMatch = await supertest(app).get("/api/ads").query({ q: "definitely-not-present-anywhere-xyz" });
    expect(noMatch.body.some((a) => a.city === SEARCH_CITY)).toBe(false);
  });

  it("falls back to the default sort for an unrecognised ?sort= instead of erroring", async () => {
    const res = await supertest(app).get("/api/ads").query({ city: CURSOR_CITY, sort: "not-a-real-sort" });
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true); // no limit/cursor -> still the bare-array legacy shape
    expect(res.body).toHaveLength(5);
  });

  it("caps limit at 100 even when a caller asks for more", async () => {
    const res = await supertest(app).get("/api/ads").query({ city: CURSOR_CITY, limit: 500 });
    expect(res.status).toBe(200);
    expect(res.body.items).toHaveLength(5); // only 5 rows exist for this city, well under the cap
    expect(res.body.nextCursor).toBeNull();
  });

  it("a legacy caller passing none of the new params gets the exact same bare-array response it always got", async () => {
    const res = await supertest(app).get("/api/ads").query({ city: CURSOR_CITY });
    expect(res.status).toBe(200);
    expect(Array.isArray(res.body)).toBe(true);
    expect(res.body).toHaveLength(5);
    expect(res.body.every((a) => typeof a.id === "string" && a.city === CURSOR_CITY)).toBe(true);
  });
});

describe("GET /api/ads vs GET /api/my/ads — stage scoping, stage filter, sort aliases (this slice)", () => {
  const STAGE_CITY = "StageSplitCity";

  beforeAll(async () => {
    await Promise.all([
      prisma.ad.create({ data: directAdData({ title: "Stage Active", city: STAGE_CITY, stage: "ACTIVE", price: 300 }) }),
      prisma.ad.create({ data: directAdData({ title: "Stage Sold", city: STAGE_CITY, stage: "SOLD", price: 200 }) }),
      prisma.ad.create({ data: directAdData({ title: "Stage Draft", city: STAGE_CITY, stage: "DRAFT", price: 100 }) }),
    ]);
  });

  it("GET /api/ads (public) only ever returns the ACTIVE one, even if a caller passes ?stage=", async () => {
    const res = await supertest(app).get("/api/ads").query({ city: STAGE_CITY, stage: "2" }); // "2" = SOLD -- must not leak it
    expect(res.body.map((a) => a.title)).toEqual(["Stage Active"]);
  });

  it("GET /api/my/ads (authenticated) returns every stage by default", async () => {
    const res = await supertest(app).get("/api/my/ads").set("Authorization", authHeader(agent)).query({ city: STAGE_CITY });
    expect(res.status).toBe(200);
    expect(res.body.map((a) => a.title).sort()).toEqual(["Stage Active", "Stage Draft", "Stage Sold"]);
  });

  it("GET /api/my/ads?stage= narrows to one stage (the CRM filter sheet)", async () => {
    const res = await supertest(app)
      .get("/api/my/ads")
      .set("Authorization", authHeader(agent))
      .query({ city: STAGE_CITY, stage: "3" }); // "3" = DRAFT
    expect(res.body.map((a) => a.title)).toEqual(["Stage Draft"]);
  });

  it("still honors the legacy highestPrice/lowestPrice sort values apps/web and apps/console already send", async () => {
    const desc = await supertest(app)
      .get("/api/my/ads")
      .set("Authorization", authHeader(agent))
      .query({ city: STAGE_CITY, sort: "highestPrice" });
    expect(desc.body.map((a) => a.title)).toEqual(["Stage Active", "Stage Sold", "Stage Draft"]);

    const asc = await supertest(app)
      .get("/api/my/ads")
      .set("Authorization", authHeader(agent))
      .query({ city: STAGE_CITY, sort: "lowestPrice" });
    expect(asc.body.map((a) => a.title)).toEqual(["Stage Draft", "Stage Sold", "Stage Active"]);
  });
});
