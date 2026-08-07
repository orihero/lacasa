import { describe, expect, it, vi } from "vitest";
import { createFakePrisma } from "../helpers/testApp.js";
import * as savedAdService from "../../src/services/savedAdService.js";

function makeAd(overrides = {}) {
  return {
    id: "ad-1",
    title: "Sunny flat",
    city: "Tashkent",
    district: "Yunusabad",
    address: null,
    reference: null,
    type: "RESIDENTIAL",
    category: "SALE",
    repairment: null,
    rooms: 3,
    area: 80,
    storey: 4,
    floors: 9,
    furniture: null,
    hashtags: null,
    price: 120000,
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

describe("listSavedAds", () => {
  // Ordering itself is the database's job via this orderBy, so what a unit
  // test can pin is that the clause is asked for. That it actually comes back
  // newest-first is proved against real Postgres in
  // test/routes/savedAds.integration.test.js.
  it("scopes the query to the user and asks for newest saves first", async () => {
    const findMany = vi.fn().mockResolvedValue([{ ad: makeAd() }]);
    const prisma = createFakePrisma({ savedAd: { findMany } });

    await savedAdService.listSavedAds({ prisma }, "user-1");

    expect(findMany).toHaveBeenCalledWith({
      where: { userId: "user-1" },
      include: { ad: { include: { photos: true } } },
      orderBy: { createdAt: "desc" },
    });
  });

  it("serializes each row as the listing itself, marked saved", async () => {
    const findMany = vi.fn().mockResolvedValue([{ ad: makeAd() }, { ad: makeAd({ id: "ad-2" }) }]);
    const prisma = createFakePrisma({ savedAd: { findMany } });

    const ads = await savedAdService.listSavedAds({ prisma }, "user-1");

    expect(ads.map((a) => a.id)).toEqual(["ad-1", "ad-2"]);
    expect(ads[0].title).toBe("Sunny flat");
    expect(ads.every((a) => a.saved === true)).toBe(true);
  });

  // A sold ad stays in the list — saving is deliberately not stage-filtered
  // (docs/04), so nothing here may quietly drop it.
  it("keeps a sold ad in the list", async () => {
    const findMany = vi.fn().mockResolvedValue([{ ad: makeAd({ stage: "SOLD", active: false }) }]);
    const prisma = createFakePrisma({ savedAd: { findMany } });

    const ads = await savedAdService.listSavedAds({ prisma }, "user-1");

    expect(ads).toHaveLength(1);
    expect(ads[0].stage).toBe("2");
  });
});

describe("saveAd", () => {
  it("upserts on the (userId, adId) compound key so a repeat save is not an error", async () => {
    const upsert = vi.fn().mockResolvedValue({ id: "saved-1" });
    const prisma = createFakePrisma({ savedAd: { upsert } });

    expect(await savedAdService.saveAd({ prisma }, "user-1", "ad-1")).toBe(true);
    expect(upsert).toHaveBeenCalledWith({
      where: { userId_adId: { userId: "user-1", adId: "ad-1" } },
      create: { userId: "user-1", adId: "ad-1" },
      update: {},
    });
  });

  it("reports a missing ad (FK violation) rather than throwing, so the route can 404", async () => {
    const upsert = vi.fn().mockRejectedValue(Object.assign(new Error("FK"), { code: "P2003" }));
    const prisma = createFakePrisma({ savedAd: { upsert } });

    expect(await savedAdService.saveAd({ prisma }, "user-1", "ad-1")).toBe(false);
  });

  it("rethrows anything that is not a missing-ad FK violation", async () => {
    const upsert = vi.fn().mockRejectedValue(Object.assign(new Error("db down"), { code: "P1001" }));
    const prisma = createFakePrisma({ savedAd: { upsert } });

    await expect(savedAdService.saveAd({ prisma }, "user-1", "ad-1")).rejects.toThrow("db down");
  });
});

describe("unsaveAd", () => {
  // deleteMany rather than delete: the whole point is that removing a
  // favourite nobody had does not raise.
  it("deletes by (userId, adId) and does not care whether a row matched", async () => {
    const deleteMany = vi.fn().mockResolvedValue({ count: 0 });
    const prisma = createFakePrisma({ savedAd: { deleteMany } });

    await expect(savedAdService.unsaveAd({ prisma }, "user-1", "ad-1")).resolves.toBeUndefined();
    expect(deleteMany).toHaveBeenCalledWith({ where: { userId: "user-1", adId: "ad-1" } });
  });
});
