import { describe, expect, it } from "vitest";
import { serializeAd, parseAdInput } from "../../src/lib/adsSerializer.js";

function makeAd(overrides = {}) {
  return {
    id: "ad-1",
    title: "Nice flat",
    city: "Tashkent",
    district: "Yunusabad",
    address: null,
    reference: null,
    type: "RESIDENTIAL",
    category: "SALE",
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

// docs/10 §3: AdPhoto.mediaType reaches clients via a new `media` array,
// while `photos` keeps its pre-existing flat string[]-of-URLs contract so
// every current consumer (AdsAdd/AdsEdit/Slider/HCard/Card/AdsList, plus the
// OLX/Instagram crosspost payloads) keeps working unchanged.
describe("serializeAd photos/media", () => {
  it("keeps photos as a flat, position-ordered string[] when every row is a photo", () => {
    const ad = makeAd({
      photos: [
        { url: "http://x/2.jpg", position: 1, mediaType: "PHOTO" },
        { url: "http://x/1.jpg", position: 0, mediaType: "PHOTO" },
      ],
    });

    const serialized = serializeAd(ad);

    expect(serialized.photos).toEqual(["http://x/1.jpg", "http://x/2.jpg"]);
  });

  it("excludes VIDEO rows from photos but includes them in media, both position-ordered", () => {
    const ad = makeAd({
      photos: [
        { url: "http://x/clip.mp4", position: 1, mediaType: "VIDEO" },
        { url: "http://x/1.jpg", position: 0, mediaType: "PHOTO" },
      ],
    });

    const serialized = serializeAd(ad);

    expect(serialized.photos).toEqual(["http://x/1.jpg"]);
    expect(serialized.media).toEqual([
      { url: "http://x/1.jpg", mediaType: "photo", position: 0 },
      { url: "http://x/clip.mp4", mediaType: "video", position: 1 },
    ]);
  });

  it("returns empty arrays for both when the ad has no photos", () => {
    const serialized = serializeAd(makeAd({ photos: [] }));

    expect(serialized.photos).toEqual([]);
    expect(serialized.media).toEqual([]);
  });
});

// docs/10 §3: listing-detail map pin.
describe("serializeAd lat/lng", () => {
  it("null-guards Decimal->Number the same way as area, never Number(null) -> 0", () => {
    const serialized = serializeAd(makeAd({ lat: null, lng: null }));

    expect(serialized.lat).toBeNull();
    expect(serialized.lng).toBeNull();
  });

  it("converts a set Decimal pin to a plain number, distinguishable from (0, 0)", () => {
    const serialized = serializeAd(makeAd({ lat: "0", lng: "0" }));

    expect(serialized.lat).toBe(0);
    expect(serialized.lng).toBe(0);
    expect(serialized.lat).not.toBeNull();
  });

  it("round-trips a realistic pin", () => {
    const serialized = serializeAd(makeAd({ lat: "41.311081", lng: "69.240562" }));

    expect(serialized.lat).toBe(41.311081);
    expect(serialized.lng).toBe(69.240562);
  });
});

describe("parseAdInput lat/lng coercion", () => {
  it("coerces numeric strings, same pattern as area", () => {
    expect(parseAdInput({ lat: "41.3", lng: "69.2" })).toMatchObject({ lat: 41.3, lng: 69.2 });
  });

  it("coerces empty string to null (clear), not 0", () => {
    expect(parseAdInput({ lat: "", lng: "" })).toEqual({ lat: null, lng: null });
  });

  it("leaves lat/lng out of the result entirely when absent from the body (PATCH-partial safe)", () => {
    expect(parseAdInput({ title: "x" })).not.toHaveProperty("lat");
    expect(parseAdInput({ title: "x" })).not.toHaveProperty("lng");
  });
});
