import { describe, expect, it } from "vitest";
import {
  buildListingSubtitle,
  buildSegOptions,
  deriveChannelBadges,
  deriveStageCounts,
  filterAdsByStage,
  resolveAdAuthor,
  stageKey,
  titleOf,
} from "../deriveMyAds";
import { makeAd, makeCoworker, makeUser } from "./fixtures";

describe("stageKey", () => {
  it("accepts the three real wire keys", () => {
    expect(stageKey("1")).toBe("1");
    expect(stageKey("2")).toBe("2");
    expect(stageKey("3")).toBe("3");
  });

  it("rejects anything else, including the Postgres-side SCREAMING_CASE names", () => {
    expect(stageKey("ACTIVE")).toBeUndefined();
    expect(stageKey(1)).toBeUndefined();
    expect(stageKey(undefined)).toBeUndefined();
    expect(stageKey(null)).toBeUndefined();
  });
});

describe("titleOf", () => {
  it("returns the real title when present", () => {
    expect(titleOf(makeAd({ title: "Family house with garden in Sergeli" }))).toBe(
      "Family house with garden in Sergeli",
    );
  });

  it("falls back to a plain missing-field label rather than blank or fabricated text", () => {
    expect(titleOf(makeAd({ title: undefined }))).toBe("Untitled listing");
    expect(titleOf(makeAd({ title: "   " }))).toBe("Untitled listing");
  });
});

describe("buildListingSubtitle", () => {
  it("joins district, pluralized rooms and area when all three are present", () => {
    expect(buildListingSubtitle(makeAd({ district: "Chilonzor", rooms: 3, area: 65 }))).toBe(
      "Chilonzor · 3 rooms · 65 m²",
    );
  });

  it("singularizes a 1-room ad", () => {
    expect(buildListingSubtitle(makeAd({ district: "Yakkasaroy", rooms: 1, area: 38 }))).toBe(
      "Yakkasaroy · 1 room · 38 m²",
    );
  });

  it("omits whichever parts are missing instead of rendering a placeholder for them", () => {
    expect(buildListingSubtitle(makeAd({ district: "Sergeli", rooms: undefined, area: undefined }))).toBe("Sergeli");
    expect(buildListingSubtitle(makeAd({ district: undefined, rooms: 2, area: undefined }))).toBe("2 rooms");
  });

  it("returns undefined when nothing is available at all", () => {
    expect(
      buildListingSubtitle(makeAd({ district: undefined, rooms: undefined, area: undefined })),
    ).toBeUndefined();
  });

  it("narrows numeric-string wire values (rooms/area can arrive as strings)", () => {
    expect(buildListingSubtitle(makeAd({ district: "Mirobod", rooms: "2", area: "54" }))).toBe(
      "Mirobod · 2 rooms · 54 m²",
    );
  });
});

describe("deriveStageCounts", () => {
  it("counts every stage plus the total, from the fetched list itself", () => {
    const ads = [
      makeAd({ id: "a1", stage: "1" }),
      makeAd({ id: "a2", stage: "1" }),
      makeAd({ id: "a3", stage: "2" }),
      makeAd({ id: "a4", stage: "3" }),
    ];
    expect(deriveStageCounts(ads)).toEqual({ all: 4, "1": 2, "2": 1, "3": 1 });
  });

  it("ignores an ad with an unrecognized stage in the per-stage counts but still counts it in all", () => {
    const ads = [makeAd({ id: "a1", stage: "9" })];
    expect(deriveStageCounts(ads)).toEqual({ all: 1, "1": 0, "2": 0, "3": 0 });
  });

  it("returns all zeros for an empty list", () => {
    expect(deriveStageCounts([])).toEqual({ all: 0, "1": 0, "2": 0, "3": 0 });
  });
});

describe("filterAdsByStage", () => {
  const ads = [makeAd({ id: "a1", stage: "1" }), makeAd({ id: "a2", stage: "2" }), makeAd({ id: "a3", stage: "1" })];

  it("returns every ad for 'all'", () => {
    expect(filterAdsByStage(ads, "all")).toHaveLength(3);
  });

  it("filters down to exactly the requested stage", () => {
    expect(filterAdsByStage(ads, "1").map((ad) => ad.id)).toEqual(["a1", "a3"]);
    expect(filterAdsByStage(ads, "2").map((ad) => ad.id)).toEqual(["a2"]);
    expect(filterAdsByStage(ads, "3")).toEqual([]);
  });
});

describe("buildSegOptions", () => {
  it("labels every option with its live count", () => {
    const options = buildSegOptions({ all: 8, "1": 5, "2": 1, "3": 2 });
    expect(options).toEqual([
      { value: "all", label: "All 8" },
      { value: "1", label: "Active 5" },
      { value: "2", label: "Sold 1" },
      { value: "3", label: "Draft 2" },
    ]);
  });
});

describe("resolveAdAuthor", () => {
  const sardor = makeCoworker({ id: "coworker-sardor", fullName: "Sardor Abdullayev", avatar: "https://x/s.jpg" });
  const javlon = makeUser({ fullName: "Javlon Rustamov", avatar: null });

  it("resolves to the matching coworker when the ad has a coworkerId", () => {
    const ad = makeAd({ coworkerId: "coworker-sardor" });
    expect(resolveAdAuthor(ad, [sardor], javlon)).toEqual({
      name: "Sardor Abdullayev",
      avatar: "https://x/s.jpg",
    });
  });

  it("falls back to the current agent when the ad has no coworkerId", () => {
    const ad = makeAd({ coworkerId: null });
    expect(resolveAdAuthor(ad, [sardor], javlon)).toEqual({ name: "Javlon Rustamov", avatar: null });
  });

  it("returns null (never a guess) when the referenced coworker hasn't loaded/isn't in the roster", () => {
    const ad = makeAd({ coworkerId: "coworker-not-in-list" });
    expect(resolveAdAuthor(ad, [sardor], javlon)).toBeNull();
  });

  it("returns null when there is no coworkerId and no current user yet", () => {
    const ad = makeAd({ coworkerId: null });
    expect(resolveAdAuthor(ad, [sardor], null)).toBeNull();
  });
});

describe("deriveChannelBadges", () => {
  it("shows just the abbreviation for a published channel", () => {
    const badges = deriveChannelBadges([{ channel: "INSTAGRAM", status: "PUBLISHED" }]);
    expect(badges).toEqual([{ key: "INSTAGRAM-0", tone: "ok", label: "IG" }]);
  });

  it("appends the human status for a non-published channel, matching the shared label text", () => {
    const badges = deriveChannelBadges([{ channel: "OLX", status: "FAILED" }]);
    expect(badges).toEqual([{ key: "OLX-0", tone: "err", label: "OLX failed" }]);
  });

  it("handles every real channel/status combination without dropping any entry", () => {
    const badges = deriveChannelBadges([
      { channel: "TELEGRAM", status: "PUBLISHED" },
      { channel: "YOUTUBE", status: "FAILED" },
      { channel: "OLX", status: "DRAFTED_AWAITING_REVIEW" },
    ]);
    expect(badges.map((b) => b.label)).toEqual(["TG", "YT failed", "OLX awaiting review"]);
  });

  it("renders an unrecognized channel/status verbatim in a neutral tone rather than dropping it", () => {
    const badges = deriveChannelBadges([{ channel: "TIKTOK", status: "SCHEDULED" }]);
    expect(badges).toEqual([{ key: "TIKTOK-0", tone: "mute", label: "TIKTOK scheduled" }]);
  });

  it("returns an empty array for no entries", () => {
    expect(deriveChannelBadges([])).toEqual([]);
  });
});
