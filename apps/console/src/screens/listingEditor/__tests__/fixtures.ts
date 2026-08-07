/** Shared `Ad`/`Coworker` builders for this folder's test suites. */
import type { Ad, Coworker } from "@lacasa/api-client";

export function makeAd(overrides: Partial<Ad> = {}): Ad {
  return {
    id: "ad-1001",
    agentId: "agent-javlon",
    coworkerId: "",
    photos: [],
    media: [],
    lat: null,
    lng: null,
    tour3dLink: null,
    title: "Bright 3-room apartment in Chilonzor",
    // Real @lacasa/domain/data/regions vocabulary (the Listing editor's
    // City/District selects are populated from it) rather than the old
    // prototype's "Tashkent"/"Chilonzor" shorthand, which isn't an actual
    // region/district name in that dataset.
    city: "Toshkent shahri",
    district: "Chilonzor tumani",
    type: "residential",
    category: "sale",
    repairment: "good",
    furniture: "withoutFurniture",
    rooms: 3,
    area: 65,
    storey: 4,
    floors: 9,
    price: 78000,
    priceType: "usd",
    stage: "1",
    description: "A bright corner apartment.",
    hashtags: "#chilonzor #3xona",
    active: true,
    reference: "a3f21",
    createdAt: { seconds: 1_722_600_000 },
    updatedAt: { seconds: 1_722_600_000 },
    ...overrides,
  };
}

export function makeCoworker(overrides: Partial<Coworker> = {}): Coworker {
  return {
    id: "coworker-sardor",
    fullName: "Sardor Abdullayev",
    email: "sardor@lacasa.uz",
    phoneNumber: null,
    avatar: null,
    agentId: "agent-javlon",
    ...overrides,
  };
}
