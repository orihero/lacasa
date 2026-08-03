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
