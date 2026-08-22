/** Shared `Ad`/`Coworker`/`AuthUser` builders for this folder's test suites. */
import type { Ad, AuthUser, Coworker } from "@lacasa/api-client";

export function makeAd(overrides: Partial<Ad> = {}): Ad {
  return {
    id: "ad-1001",
    agentId: "agent-javlon",
    coworkerId: null,
    photos: [],
    media: [],
    lat: null,
    lng: null,
    tour3dLink: null,
    title: "Bright 3-room apartment in Chilonzor",
    district: "Chilonzor",
    rooms: 3,
    area: 65,
    stage: "1",
    price: 78000,
    priceType: "usd",
    category: "sale",
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

export function makeUser(overrides: Partial<AuthUser> = {}): AuthUser {
  return {
    id: "agent-javlon",
    fullName: "Javlon Rustamov",
    email: "javlon@lacasa.uz",
    phoneNumber: null,
    role: "agent",
    avatar: null,
    ...overrides,
  };
}
