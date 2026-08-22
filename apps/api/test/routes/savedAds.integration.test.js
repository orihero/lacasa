import { describe, expect, it, beforeAll } from "vitest";
import supertest from "supertest";
import { createApp } from "../../src/app.js";
import { createFakeMinio, createFakeLlm } from "../helpers/testApp.js";
import { useIntegrationDb } from "../integration/helpers/lifecycle.js";
import { createUser, authHeader } from "../integration/helpers/factories.js";

const prisma = useIntegrationDb();
const app = createApp({ prisma, minio: createFakeMinio(), llm: createFakeLlm() });

const MISSING_ID = "00000000-0000-0000-0000-000000000000";

let agent;
let coworker;
let buyer;
let otherBuyer;
// Its own buyer so the multi-ad cases below cannot be disturbed by, or
// disturb, the save/unsave sequence above — tables truncate only between
// files, so everything in here shares one database.
let listBuyer;
let ad;

beforeAll(async () => {
  agent = await createUser(prisma, { role: "AGENT", email: "agent-saved@example.test" });
  coworker = await createUser(prisma, {
    role: "COWORKER",
    email: "coworker-saved@example.test",
    agentId: agent.id,
  });
  buyer = await createUser(prisma, { email: "buyer-saved@example.test" });
  otherBuyer = await createUser(prisma, { email: "buyer2-saved@example.test" });
  listBuyer = await createUser(prisma, { email: "buyer3-saved@example.test" });

  // Through the real endpoint rather than prisma.ad.create, so the fixture
  // cannot drift from what parseAdInput actually requires.
  const created = await supertest(app)
    .post("/api/ads")
    .set("Authorization", authHeader(agent))
    .send({
      title: "Saveable flat",
      city: "Tashkent",
      district: "Yunusabad",
      type: "residential",
      category: "sale",
      price: 120000,
    });
  ad = created.body;
});

describe("saved-ads auth and role gate", () => {
  it("requires auth on all three routes", async () => {
    expect((await supertest(app).get("/api/saved-ads")).status).toBe(401);
    expect((await supertest(app).post(`/api/saved-ads/${ad.id}`)).status).toBe(401);
    expect((await supertest(app).delete(`/api/saved-ads/${ad.id}`)).status).toBe(401);
  });

  // The heart is a buyer control (mockups/SCREENS.md §17). Enforced server-side,
  // not left to the client hiding the button.
  it("refuses saving and unsaving for an agent", async () => {
    const saved = await supertest(app)
      .post(`/api/saved-ads/${ad.id}`)
      .set("Authorization", authHeader(agent));
    expect(saved.status).toBe(403);
    expect(saved.body.error.code).toBe("forbidden");

    const unsaved = await supertest(app)
      .delete(`/api/saved-ads/${ad.id}`)
      .set("Authorization", authHeader(agent));
    expect(unsaved.status).toBe(403);
  });

  it("refuses saving and unsaving for a coworker too", async () => {
    const saved = await supertest(app)
      .post(`/api/saved-ads/${ad.id}`)
      .set("Authorization", authHeader(coworker));
    expect(saved.status).toBe(403);

    const unsaved = await supertest(app)
      .delete(`/api/saved-ads/${ad.id}`)
      .set("Authorization", authHeader(coworker));
    expect(unsaved.status).toBe(403);
  });

  it("still lets an agent read the (always empty) list rather than 403ing a page render", async () => {
    const res = await supertest(app).get("/api/saved-ads").set("Authorization", authHeader(agent));
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });
});

describe("saving and unsaving as a buyer", () => {
  it("saves an ad and returns it from the list", async () => {
    const res = await supertest(app)
      .post(`/api/saved-ads/${ad.id}`)
      .set("Authorization", authHeader(buyer));
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true });

    const list = await supertest(app).get("/api/saved-ads").set("Authorization", authHeader(buyer));
    expect(list.status).toBe(200);
    expect(list.body).toHaveLength(1);
    expect(list.body[0].id).toBe(ad.id);
    expect(list.body[0].title).toBe("Saveable flat");
    expect(list.body[0].saved).toBe(true);
  });

  it("treats a repeat save as the same fact — same response, still one row", async () => {
    const again = await supertest(app)
      .post(`/api/saved-ads/${ad.id}`)
      .set("Authorization", authHeader(buyer));
    expect(again.status).toBe(200);
    expect(again.body).toEqual({ ok: true });

    expect(await prisma.savedAd.count({ where: { userId: buyer.id, adId: ad.id } })).toBe(1);
  });

  it("keeps one buyer's saves out of another's list", async () => {
    const res = await supertest(app).get("/api/saved-ads").set("Authorization", authHeader(otherBuyer));
    expect(res.status).toBe(200);
    expect(res.body).toEqual([]);
  });

  it("unsaves, and a repeat unsave still succeeds", async () => {
    const res = await supertest(app)
      .delete(`/api/saved-ads/${ad.id}`)
      .set("Authorization", authHeader(buyer));
    expect(res.status).toBe(204);

    const list = await supertest(app).get("/api/saved-ads").set("Authorization", authHeader(buyer));
    expect(list.body).toEqual([]);

    const again = await supertest(app)
      .delete(`/api/saved-ads/${ad.id}`)
      .set("Authorization", authHeader(buyer));
    expect(again.status).toBe(204);
  });
});

describe("saved-ads with an id that matches no ad", () => {
  it("404s saving a well-formed but unknown id", async () => {
    const res = await supertest(app)
      .post(`/api/saved-ads/${MISSING_ID}`)
      .set("Authorization", authHeader(buyer));
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe("not_found");
  });

  // Regression guard: a non-UUID makes Prisma raise a different code than the
  // FK violation, which without the route's shape check surfaces as a 500.
  it("404s rather than 500s on a malformed id", async () => {
    const res = await supertest(app)
      .post("/api/saved-ads/not-a-uuid")
      .set("Authorization", authHeader(buyer));
    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe("not_found");
  });

  it("still 204s unsaving a malformed id — it can never have been saved", async () => {
    const res = await supertest(app)
      .delete("/api/saved-ads/not-a-uuid")
      .set("Authorization", authHeader(buyer));
    expect(res.status).toBe(204);
  });
});

describe("the saved list itself", () => {
  let older;
  let newer;

  beforeAll(async () => {
    const first = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send({
        title: "Saved earlier",
        city: "Tashkent",
        district: "Yunusabad",
        type: "residential",
        category: "sale",
        price: 100000,
      });
    older = first.body;

    const second = await supertest(app)
      .post("/api/ads")
      .set("Authorization", authHeader(agent))
      .send({
        title: "Saved later",
        city: "Tashkent",
        district: "Chilanzar",
        type: "residential",
        category: "sale",
        price: 200000,
      });
    newer = second.body;

    // Sold, not active — the list must still carry it. See below.
    await supertest(app)
      .patch(`/api/ads/${older.id}`)
      .set("Authorization", authHeader(agent))
      .send({ stage: "2" });

    for (const id of [older.id, newer.id]) {
      const res = await supertest(app)
        .post(`/api/saved-ads/${id}`)
        .set("Authorization", authHeader(listBuyer));
      expect(res.status).toBe(200);
    }

    // Pinned rather than relying on two inserts landing microseconds apart,
    // which would make the ordering assertion a coin flip.
    await prisma.savedAd.updateMany({
      where: { userId: listBuyer.id, adId: older.id },
      data: { createdAt: new Date("2026-01-01T00:00:00Z") },
    });
  });

  it("returns saves newest first", async () => {
    const res = await supertest(app).get("/api/saved-ads").set("Authorization", authHeader(listBuyer));

    expect(res.status).toBe(200);
    expect(res.body.map((a) => a.title)).toEqual(["Saved later", "Saved earlier"]);
  });

  // docs/04 states saving is deliberately not restricted by ad stage, matching
  // GET /ads/:id. Without this, adding a stage filter to the repository would
  // break that contract with the suite still green.
  it("keeps a sold ad both savable and listed", async () => {
    const res = await supertest(app).get("/api/saved-ads").set("Authorization", authHeader(listBuyer));

    const sold = res.body.find((a) => a.id === older.id);
    expect(sold).toBeDefined();
    expect(sold.stage).toBe("2");
    expect(sold.saved).toBe(true);
  });
});
