import { describe, expect, it, vi } from "vitest";
import { createFakeMinio, createFakePrisma } from "../helpers/testApp.js";
import * as adService from "../../src/services/adService.js";

function makeAd(overrides = {}) {
  return {
    id: "ad-1",
    title: "Nice flat",
    city: "Tashkent",
    district: "Yunusabad",
    address: null,
    reference: null,
    type: "SALE",
    category: "APARTMENT",
    repairment: null,
    rooms: 3,
    area: "80",
    storey: 4,
    floors: 9,
    furniture: null,
    hashtags: null,
    price: "100000",
    priceType: "UZS",
    stage: "ACTIVE",
    description: null,
    nearPlaces: [],
    options: [],
    active: true,
    lat: null,
    lng: null,
    agentId: "agent-1",
    coworkerId: null,
    photos: [],
    createdAt: new Date("2026-01-01T00:00:00Z"),
    updatedAt: new Date("2026-01-01T00:00:00Z"),
    ...overrides,
  };
}

describe("buildAdFilters", () => {
  it("only sets filters present in the query, coercing numeric ranges", () => {
    const where = adService.buildAdFilters({
      city: "Tashkent",
      areaMin: "50",
      areaMax: "100",
      priceMin: "1000",
      rooms: "3",
    });
    expect(where).toEqual({
      city: "Tashkent",
      rooms: 3,
      area: { gte: 50, lte: 100 },
      price: { gte: 1000 },
    });
  });

  it("ignores enum filter keys that don't map to a known enum value", () => {
    const where = adService.buildAdFilters({ category: "not-a-real-category" });
    expect(where).toEqual({});
  });

  it("maps a valid stage form-value ('1'/'2'/'3', never the raw Postgres enum name) and ignores an invalid one", () => {
    expect(adService.buildAdFilters({ stage: "2" })).toEqual({ stage: "SOLD" });
    expect(adService.buildAdFilters({ stage: "bogus" })).toEqual({});
  });
});

describe("listAds", () => {
  it("scopes to ACTIVE ads when no agentId is given (public listing)", async () => {
    const findMany = vi.fn().mockResolvedValue([makeAd()]);
    const prisma = createFakePrisma({ ad: { findMany } });
    const ctx = { prisma };

    const ads = await adService.listAds(ctx, { city: "Tashkent" });

    expect(findMany).toHaveBeenCalledWith({
      where: { city: "Tashkent", stage: "ACTIVE" },
      include: { photos: true },
      orderBy: { createdAt: "desc" },
    });
    expect(ads).toHaveLength(1);
    expect(ads[0].id).toBe("ad-1");
  });

  it("scopes to the given agentId and applies a custom orderBy (myAds.js usage)", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ ad: { findMany } });
    const ctx = { prisma };

    await adService.listAds(ctx, {}, { agentId: "agent-1", orderBy: { price: "desc" } });

    expect(findMany).toHaveBeenCalledWith({
      where: { agentId: "agent-1" },
      include: { photos: true },
      orderBy: { price: "desc" },
    });
  });

  it("lets an agentId-scoped caller filter by stage (the CRM filter sheet) without the public-feed ACTIVE override kicking in", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ ad: { findMany } });

    await adService.listAds({ prisma }, { stage: "3" }, { agentId: "agent-1" });

    expect(findMany).toHaveBeenCalledWith(
      expect.objectContaining({ where: { agentId: "agent-1", stage: "DRAFT" } }),
    );
  });

  it("a stray ?stage= on the public feed (no agentId) can never leak a non-ACTIVE ad", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ ad: { findMany } });

    await adService.listAds({ prisma }, { stage: "3" });

    expect(findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { stage: "ACTIVE" } }));
  });

  it("falls back to the default sort (createdAt desc) when `sort` is unrecognised, instead of erroring or passing the raw value to Prisma", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ ad: { findMany } });

    await adService.listAds({ prisma }, { sort: "'; drop table ads; --" });

    expect(findMany).toHaveBeenCalledWith(expect.objectContaining({ orderBy: { createdAt: "desc" } }));
  });

  it("still accepts the legacy highestPrice/lowestPrice sort values apps/web and apps/console already send to /my/ads", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ ad: { findMany } });

    await adService.listAds({ prisma }, { sort: "highestPrice" }, { agentId: "agent-1" });
    expect(findMany).toHaveBeenLastCalledWith(expect.objectContaining({ orderBy: { price: "desc" } }));

    await adService.listAds({ prisma }, { sort: "lowestPrice" }, { agentId: "agent-1" });
    expect(findMany).toHaveBeenLastCalledWith(expect.objectContaining({ orderBy: { price: "asc" } }));
  });

  it("maps the new areaAsc/areaDesc sort values onto the area column", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ ad: { findMany } });

    await adService.listAds({ prisma }, { sort: "areaAsc" });
    expect(findMany).toHaveBeenLastCalledWith(expect.objectContaining({ orderBy: { area: "asc" } }));

    await adService.listAds({ prisma }, { sort: "areaDesc" });
    expect(findMany).toHaveBeenLastCalledWith(expect.objectContaining({ orderBy: { area: "desc" } }));
  });

  it("filters case-insensitively across title/description/address/district/city when q is given, trimmed", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ ad: { findMany } });

    await adService.listAds({ prisma }, { q: "  Sunny  " });

    expect(findMany).toHaveBeenCalledWith(
      expect.objectContaining({
        where: expect.objectContaining({
          OR: [
            { title: { contains: "Sunny", mode: "insensitive" } },
            { description: { contains: "Sunny", mode: "insensitive" } },
            { address: { contains: "Sunny", mode: "insensitive" } },
            { district: { contains: "Sunny", mode: "insensitive" } },
            { city: { contains: "Sunny", mode: "insensitive" } },
          ],
        }),
      }),
    );
  });

  it("ignores a blank/whitespace-only q instead of matching everything", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ ad: { findMany } });

    await adService.listAds({ prisma }, { q: "   " });

    expect(findMany).toHaveBeenCalledWith(expect.objectContaining({ where: { stage: "ACTIVE" } }));
  });

  it("stays a bare array when no paging param is present -- legacy callers (apps/web, apps/console, apps/mobile_flutter) see no change", async () => {
    const findMany = vi.fn().mockResolvedValue([makeAd()]);
    const prisma = createFakePrisma({ ad: { findMany } });

    const result = await adService.listAds({ prisma }, {});

    expect(Array.isArray(result)).toBe(true);
    expect(result).toHaveLength(1);
    expect(findMany.mock.calls[0][0].take).toBeUndefined();
  });

  it("returns the { items, nextCursor } envelope once `limit` is present, and caps limit at 100", async () => {
    const rows = Array.from({ length: 101 }, (_, i) => makeAd({ id: `ad-${i}` }));
    const findMany = vi.fn().mockResolvedValue(rows); // simulates take: 101 finding a full 101st "is there more" row
    const prisma = createFakePrisma({ ad: { findMany } });

    const result = await adService.listAds({ prisma }, { limit: "500" }); // over MAX_LIMIT

    expect(findMany).toHaveBeenCalledWith(expect.objectContaining({ take: 101 }));
    expect(result.items).toHaveLength(100);
    expect(result.nextCursor).toEqual(expect.any(String));
  });

  it("returns nextCursor: null once the result set is shorter than `limit` (last page)", async () => {
    const findMany = vi.fn().mockResolvedValue([makeAd()]);
    const prisma = createFakePrisma({ ad: { findMany } });

    const result = await adService.listAds({ prisma }, { limit: "20" });

    expect(result.items).toHaveLength(1);
    expect(result.nextCursor).toBeNull();
  });

  it("also pages via ?cursor= or ?paged=true alone, without ?limit=, defaulting limit to 20", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ ad: { findMany } });

    await adService.listAds({ prisma }, { paged: "true" });
    expect(findMany.mock.calls[0][0].take).toBe(21);
  });

  it("keyset-cursors on (sort field, id), AND-ing the seek condition onto the existing filters rather than clobbering them", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ ad: { findMany } });
    const cursorRow = makeAd({ id: "ad-cursor", createdAt: new Date("2026-02-01T00:00:00Z") });
    const cursor = Buffer.from(
      JSON.stringify({ v: cursorRow.createdAt.toISOString(), id: cursorRow.id }),
    ).toString("base64url");

    await adService.listAds({ prisma }, { city: "Tashkent", limit: "10", cursor });

    const { where, orderBy } = findMany.mock.calls[0][0];
    expect(orderBy).toEqual([{ createdAt: "desc" }, { id: "desc" }]); // default sort ("newest") + id tiebreaker
    expect(where.AND[0]).toEqual({ city: "Tashkent", stage: "ACTIVE" });
    expect(where.AND[1]).toEqual({
      OR: [{ createdAt: { lt: cursorRow.createdAt } }, { createdAt: cursorRow.createdAt, id: { lt: cursorRow.id } }],
    });
  });

  it("treats an undecodable/forged cursor as 'start from the top' rather than 400ing", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ ad: { findMany } });

    await adService.listAds({ prisma }, { limit: "10", cursor: "not-a-real-cursor" });

    expect(findMany.mock.calls[0][0].where).toEqual({ stage: "ACTIVE" });
  });
});

// ?countOnly=true -- the third response shape, added so the mobile filter
// sheet's live "Apply Filters (N)" preview stops downloading every matching
// row just to read its length. Each of these fails against the pre-change
// service, which had no countOnly branch at all and would have gone on to
// call findMany() (there is no `findMany` stub in these fake prismas, so the
// proxy in createFakePrisma throws "no stub for .findMany()").
describe("listAds ?countOnly=true", () => {
  it("answers { count } from prisma.ad.count and never selects a row", async () => {
    const count = vi.fn().mockResolvedValue(42);
    const prisma = createFakePrisma({ ad: { count } });

    const result = await adService.listAds({ prisma }, { city: "Tashkent", countOnly: "true" });

    expect(result).toEqual({ count: 42 });
    expect(count).toHaveBeenCalledWith({ where: { city: "Tashkent", stage: "ACTIVE" } });
  });

  it("counts the same rows the matching list call would return -- ACTIVE-forced on the public feed", async () => {
    const count = vi.fn().mockResolvedValue(0);
    const prisma = createFakePrisma({ ad: { count } });

    // A stray ?stage= can't widen the count any more than it can widen the
    // list (see the "can never leak a non-ACTIVE ad" case above); if it
    // could, the button would promise results the feed behind it withholds.
    await adService.listAds({ prisma }, { stage: "3", countOnly: "true" });

    expect(count).toHaveBeenCalledWith({ where: { stage: "ACTIVE" } });
  });

  it("counts through the ?q= search too, not around it", async () => {
    const count = vi.fn().mockResolvedValue(3);
    const prisma = createFakePrisma({ ad: { count } });

    await adService.listAds({ prisma }, { q: "Sunny", countOnly: "true" });

    expect(count).toHaveBeenCalledWith({
      where: expect.objectContaining({
        stage: "ACTIVE",
        OR: expect.arrayContaining([{ title: { contains: "Sunny", mode: "insensitive" } }]),
      }),
    });
  });

  it("inherits the agentId scope on /my/ads, where stage stays caller-controlled", async () => {
    const count = vi.fn().mockResolvedValue(5);
    const prisma = createFakePrisma({ ad: { count } });

    await adService.listAds({ prisma }, { stage: "2", countOnly: "true" }, { agentId: "agent-1" });

    expect(count).toHaveBeenCalledWith({ where: { agentId: "agent-1", stage: "SOLD" } });
  });

  it("ignores sort/limit/cursor -- a count is order- and page-independent", async () => {
    const count = vi.fn().mockResolvedValue(7);
    const prisma = createFakePrisma({ ad: { count } });

    const result = await adService.listAds(
      { prisma },
      { countOnly: "true", sort: "priceDesc", limit: "10", cursor: "whatever" },
    );

    // Not the paged envelope, despite ?limit= being present: countOnly is
    // gated before isPagedRequest().
    expect(result).toEqual({ count: 7 });
    expect(count).toHaveBeenCalledWith({ where: { stage: "ACTIVE" } });
  });

  it("only triggers on the literal 'true' -- any other value is an ordinary list request", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const count = vi.fn();
    const prisma = createFakePrisma({ ad: { findMany, count } });

    const result = await adService.listAds({ prisma }, { countOnly: "1" });

    expect(Array.isArray(result)).toBe(true);
    expect(count).not.toHaveBeenCalled();
  });
});

describe("getAd", () => {
  it("returns null when the ad doesn't exist", async () => {
    const prisma = createFakePrisma({ ad: { findUnique: vi.fn().mockResolvedValue(null) } });
    expect(await adService.getAd({ prisma }, "missing")).toBeNull();
  });

  it("serializes the ad when found", async () => {
    const prisma = createFakePrisma({ ad: { findUnique: vi.fn().mockResolvedValue(makeAd()) } });
    const ad = await adService.getAd({ prisma }, "ad-1");
    expect(ad.id).toBe("ad-1");
    expect(ad.price).toBe(100000);
  });
});

describe("createAd", () => {
  it("creates the ad and logs an AD_CREATED activity event tied to the actor", async () => {
    const created = makeAd();
    const create = vi.fn().mockResolvedValue(created);
    const activityCreate = vi.fn().mockResolvedValue({});
    const prisma = createFakePrisma({ ad: { create }, activityEvent: { create: activityCreate } });
    const ctx = { prisma };
    const actor = { agentId: "agent-1", coworkerId: "coworker-1" };

    const ad = await adService.createAd(ctx, { title: "Nice flat", photos: ["http://x/1.jpg"] }, actor);

    expect(create).toHaveBeenCalledTimes(1);
    const createArgs = create.mock.calls[0][0];
    expect(createArgs.data.agentId).toBe("agent-1");
    expect(createArgs.data.coworkerId).toBe("coworker-1");
    expect(createArgs.data.stage).toBe("ACTIVE");
    expect(createArgs.data.priceType).toBe("UZS");
    expect(createArgs.data.photos.create).toEqual([{ url: "http://x/1.jpg", objectKey: "http://x/1.jpg", position: 0 }]);
    expect(createArgs.include).toEqual({ photos: true });

    expect(activityCreate).toHaveBeenCalledWith({
      data: { type: "AD_CREATED", agentId: "agent-1", coworkerId: "coworker-1", adId: created.id },
    });

    expect(ad.id).toBe(created.id);
  });

  it("accepts a full lat/lng pair", async () => {
    const created = makeAd({ lat: "41.311081", lng: "69.240562" });
    const create = vi.fn().mockResolvedValue(created);
    const prisma = createFakePrisma({ ad: { create }, activityEvent: { create: vi.fn().mockResolvedValue({}) } });
    const actor = { agentId: "agent-1", coworkerId: null };

    const ad = await adService.createAd(
      { prisma },
      { title: "Pinned", lat: "41.311081", lng: "69.240562" },
      actor,
    );

    expect(create.mock.calls[0][0].data.lat).toBe(41.311081);
    expect(create.mock.calls[0][0].data.lng).toBe(69.240562);
    expect(ad.lat).toBe(41.311081);
    expect(ad.lng).toBe(69.240562);
  });

  it("rejects lat set without lng", async () => {
    const prisma = createFakePrisma({});
    const actor = { agentId: "agent-1", coworkerId: null };

    await expect(adService.createAd({ prisma }, { title: "Half pin", lat: "41.3" }, actor)).rejects.toMatchObject({
      status: 400,
      code: "validation",
    });
  });

  it("rejects a latitude out of range", async () => {
    const prisma = createFakePrisma({});
    const actor = { agentId: "agent-1", coworkerId: null };

    await expect(
      adService.createAd({ prisma }, { title: "Bad lat", lat: "91", lng: "10" }, actor),
    ).rejects.toMatchObject({ status: 400, code: "validation" });
  });

  it("allows omitting lat/lng entirely (both stay null)", async () => {
    const created = makeAd();
    const create = vi.fn().mockResolvedValue(created);
    const prisma = createFakePrisma({ ad: { create }, activityEvent: { create: vi.fn().mockResolvedValue({}) } });
    const actor = { agentId: "agent-1", coworkerId: null };

    await expect(adService.createAd({ prisma }, { title: "No pin" }, actor)).resolves.toBeDefined();
  });
});

describe("updateAd", () => {
  it("returns null when no ad matches id + agentId (404 case)", async () => {
    const prisma = createFakePrisma({ ad: { findFirst: vi.fn().mockResolvedValue(null) } });
    const result = await adService.updateAd({ prisma }, "ad-1", "agent-1", {}, { agentId: "agent-1", coworkerId: null });
    expect(result).toBeNull();
  });

  it("logs AD_SOLD when the update sets stage to SOLD", async () => {
    const existing = makeAd();
    const updated = makeAd({ stage: "SOLD" });
    const findFirst = vi.fn().mockResolvedValue(existing);
    const update = vi.fn().mockResolvedValue(updated);
    const activityCreate = vi.fn().mockResolvedValue({});
    const prisma = createFakePrisma({ ad: { findFirst, update }, activityEvent: { create: activityCreate } });

    await adService.updateAd({ prisma }, "ad-1", "agent-1", { stage: "2" }, { agentId: "agent-1", coworkerId: null });

    expect(activityCreate).toHaveBeenCalledWith({
      data: { type: "AD_SOLD", agentId: "agent-1", coworkerId: null, adId: updated.id },
    });
  });

  it("logs AD_DRAFT_UPDATED for any non-sold edit, even one that changes nothing meaningful", async () => {
    const existing = makeAd();
    const updated = makeAd();
    const prisma = createFakePrisma({
      ad: { findFirst: vi.fn().mockResolvedValue(existing), update: vi.fn().mockResolvedValue(updated) },
      activityEvent: { create: vi.fn().mockResolvedValue({}) },
    });

    await adService.updateAd({ prisma }, "ad-1", "agent-1", { title: "same" }, { agentId: "agent-1", coworkerId: null });

    expect(prisma.activityEvent.create).toHaveBeenCalledWith(
      expect.objectContaining({ data: expect.objectContaining({ type: "AD_DRAFT_UPDATED" }) }),
    );
  });

  it("allows setting lat/lng together on an ad that had neither", async () => {
    const existing = makeAd();
    const updated = makeAd({ lat: "41.3", lng: "69.2" });
    const update = vi.fn().mockResolvedValue(updated);
    const prisma = createFakePrisma({
      ad: { findFirst: vi.fn().mockResolvedValue(existing), update },
      activityEvent: { create: vi.fn().mockResolvedValue({}) },
    });

    const ad = await adService.updateAd(
      { prisma },
      "ad-1",
      "agent-1",
      { lat: "41.3", lng: "69.2" },
      { agentId: "agent-1", coworkerId: null },
    );

    expect(update.mock.calls[0][0].data.lat).toBe(41.3);
    expect(update.mock.calls[0][0].data.lng).toBe(69.2);
    expect(ad.lat).toBe(41.3);
  });

  it("rejects clearing only lng on an ad that already has both lat and lng set", async () => {
    const existing = makeAd({ lat: "41.3", lng: "69.2" });
    const prisma = createFakePrisma({ ad: { findFirst: vi.fn().mockResolvedValue(existing) } });

    await expect(
      adService.updateAd({ prisma }, "ad-1", "agent-1", { lng: "" }, { agentId: "agent-1", coworkerId: null }),
    ).rejects.toMatchObject({ status: 400, code: "validation" });
  });

  it("allows clearing both lat and lng together", async () => {
    const existing = makeAd({ lat: "41.3", lng: "69.2" });
    const updated = makeAd();
    const update = vi.fn().mockResolvedValue(updated);
    const prisma = createFakePrisma({
      ad: { findFirst: vi.fn().mockResolvedValue(existing), update },
      activityEvent: { create: vi.fn().mockResolvedValue({}) },
    });

    await expect(
      adService.updateAd(
        { prisma },
        "ad-1",
        "agent-1",
        { lat: "", lng: "" },
        { agentId: "agent-1", coworkerId: null },
      ),
    ).resolves.toBeDefined();
  });

  it("leaves an existing valid pin alone when the PATCH doesn't touch lat/lng", async () => {
    const existing = makeAd({ lat: "41.3", lng: "69.2" });
    const updated = makeAd({ lat: "41.3", lng: "69.2", title: "renamed" });
    const update = vi.fn().mockResolvedValue(updated);
    const prisma = createFakePrisma({
      ad: { findFirst: vi.fn().mockResolvedValue(existing), update },
      activityEvent: { create: vi.fn().mockResolvedValue({}) },
    });

    await expect(
      adService.updateAd(
        { prisma },
        "ad-1",
        "agent-1",
        { title: "renamed" },
        { agentId: "agent-1", coworkerId: null },
      ),
    ).resolves.toBeDefined();
  });

  it("replaces photos wholesale only when photos is provided in the body", async () => {
    const existing = makeAd();
    const update = vi.fn().mockResolvedValue(makeAd());
    const prisma = createFakePrisma({
      ad: { findFirst: vi.fn().mockResolvedValue(existing), update },
      activityEvent: { create: vi.fn().mockResolvedValue({}) },
    });

    await adService.updateAd({ prisma }, "ad-1", "agent-1", { photos: ["http://x/2.jpg"] }, { agentId: "agent-1", coworkerId: null });

    const { data } = update.mock.calls[0][0];
    expect(data.photos).toEqual({
      deleteMany: {},
      create: [{ url: "http://x/2.jpg", objectKey: "http://x/2.jpg", position: 0 }],
    });
  });
});

describe("deleteAd", () => {
  it("returns null when no ad matches (404 case)", async () => {
    const prisma = createFakePrisma({ ad: { findFirst: vi.fn().mockResolvedValue(null) } });
    expect(await adService.deleteAd({ prisma, minio: createFakeMinio() }, "ad-1", "agent-1")).toBeNull();
  });

  it("deletes the row and best-effort removes every photo object from minio", async () => {
    const existing = makeAd({ photos: [{ objectKey: "ads/1.jpg" }, { objectKey: "ads/2.jpg" }] });
    const del = vi.fn().mockResolvedValue({});
    const removeObject = vi.fn().mockResolvedValue(undefined);
    const prisma = createFakePrisma({ ad: { findFirst: vi.fn().mockResolvedValue(existing), delete: del } });

    const result = await adService.deleteAd({ prisma, minio: createFakeMinio({ removeObject }) }, "ad-1", "agent-1");

    expect(result).toBe(true);
    expect(del).toHaveBeenCalledWith({ where: { id: "ad-1" } });
    expect(removeObject).toHaveBeenCalledTimes(2);
  });

  it("does not throw if minio.removeObject rejects for a photo", async () => {
    const existing = makeAd({ photos: [{ objectKey: "ads/1.jpg" }] });
    const prisma = createFakePrisma({
      ad: { findFirst: vi.fn().mockResolvedValue(existing), delete: vi.fn().mockResolvedValue({}) },
    });
    const minio = createFakeMinio({ removeObject: vi.fn().mockRejectedValue(new Error("gone")) });

    await expect(adService.deleteAd({ prisma, minio }, "ad-1", "agent-1")).resolves.toBe(true);
  });
});

describe("stageCounts", () => {
  it("maps groupBy rows onto the legacy stage1/stage2/stage3 shape", async () => {
    const groupBy = vi.fn().mockResolvedValue([
      { stage: "ACTIVE", _count: { _all: 5 } },
      { stage: "SOLD", _count: { _all: 2 } },
    ]);
    const prisma = createFakePrisma({ ad: { groupBy } });

    const counts = await adService.stageCounts({ prisma }, "agent-1");

    expect(counts).toEqual({ stage1: 5, stage2: 2, stage3: 0 });
  });
});
