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
