// Demo listings scraped from OLX.uz's public real-estate tree (8 subcategories:
// apartments/houses/commercial/land x sale/rent, plus daily rentals) and mapped
// onto the Ad model. Runs on top of `npm run seed` -- that one owns the
// currency rate, the nearby-place options this script's nearPlaces values must
// match, and agent@lacasa.dev.
//
// Idempotent: every ad carries reference "OLX-<olxId>", and the run deletes any
// ad already holding one of this file's references before recreating it, so
// re-running refreshes rather than duplicates.
//
// Photos stay as remote olxcdn URLs rather than being copied into MinIO --
// AdPhoto.objectKey is required, so it records the CDN path with an "olx/"
// prefix to mark the row as externally hosted. Nothing in the app writes to
// these keys; a later pass can mirror them into the bucket if the demo needs
// to survive OLX rotating its CDN.

import { readFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { dirname, join } from "node:path";
import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();
const here = dirname(fileURLToPath(import.meta.url));

const listings = JSON.parse(
  readFileSync(join(here, "seed-data", "olx-listings.json"), "utf8"),
);

// Three agents so the marketplace's "by agent" surfaces have more than one
// column of data; ads are dealt round-robin.
const AGENTS = [
  {
    email: "agent@lacasa.dev",
    fullName: "Dev Agent",
    phoneNumber: "+998900000000",
    realtorKind: "SOLO",
  },
  {
    email: "dilnoza@lacasa.dev",
    fullName: "Dilnoza Karimova",
    phoneNumber: "+998901234567",
    realtorKind: "AGENCY",
    agencyName: "Toshkent Uy Savdo",
  },
  {
    email: "sardor@lacasa.dev",
    fullName: "Sardor Rahimov",
    phoneNumber: "+998935550101",
    realtorKind: "SOLO",
  },
];

// OLX prices in "у.е." (conventional units) are dollars in practice; the only
// other currency the feed uses is UZS.
const CURRENCY = { UYE: "USD", UZS: "UZS" };

// OLX's near_is labels are a comma-joined list whose own items contain commas
// ("Kasalxona, poliklinika"), so the string can't be split -- match on
// substrings instead and emit the labels prisma/seed.js seeds into
// NearbyPlaceOption, which is what the ad form offers.
const NEARBY = [
  ["Maktab", "Maktab"],
  ["bogʻchasi", "Bog'cha"],
  ["Bekatlar", "Metro"],
  ["Supermarket", "Supermarket"],
  ["Kasalxona", "Shifoxona"],
  ["Park", "Park"],
  ["turargoh", "Avtoturargoh"],
];

const HASHTAGS = {
  apt_sale: "#kvartira #sotiladi",
  apt_rent: "#kvartira #ijara",
  house_sale: "#hovli #sotiladi",
  house_rent: "#hovli #ijara",
  comm_sale: "#tijorat #sotiladi",
  comm_rent: "#tijorat #ijara",
  land_sale: "#yer #sotiladi",
  daily_rent: "#sutkalik #ijara",
};

// Nothing in the OLX feed maps 1:1 onto our Repairment scale, so read it off
// the seller's own words. Order matters: "коробка" (bare shell) wins over a
// "новый" that only describes the building.
const REPAIRMENT_RULES = [
  [/коробка|без ремонта|ta.?mirlanmagan|беловая/i, "NOT_REPAIRED"],
  [/евро|дизайнерск|премиум|новый ремонт|янги ремонт|euro-?\d/i, "EXCELLENT"],
  [/новостройк|yangi qurilgan|после ремонта|янги уй|yangi/i, "GOOD"],
];

function repairmentFor(listing) {
  const haystack = `${listing.title} ${listing.description} ${listing.market ?? ""}`;
  for (const [pattern, value] of REPAIRMENT_RULES) {
    if (pattern.test(haystack)) return value;
  }
  return "NORMAL";
}

function nearPlacesFor(listing) {
  if (!listing.nearIs) return [];
  return NEARBY.filter(([needle]) => listing.nearIs.includes(needle)).map(
    ([, label]) => label,
  );
}

// The "more" label is a comma-join of amenity names that contain no commas of
// their own, so this one is safe to split.
function optionsFor(listing) {
  if (!listing.more) return [];
  return listing.more
    .split(",")
    .map((item) => item.trim())
    .filter(Boolean);
}

function num(value) {
  if (value === null || value === undefined || value === "") return null;
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : null;
}

// A handful of commercial rentals quote $/m² instead of a monthly total, which
// reads as a broken $11 listing in the app. The scrape flags those.
function priceFor(listing) {
  const area = num(listing.areaTotal);
  if (listing.pricePerSqm && area) return listing.price * area;
  return listing.price;
}

function adDataFor(listing, agentId) {
  return {
    title: listing.title,
    city: listing.city,
    district: listing.district,
    address: null,
    reference: `OLX-${listing.olxId}`,
    type: listing.type,
    category: listing.category,
    repairment: repairmentFor(listing),
    rooms: num(listing.rooms),
    area: num(listing.areaTotal),
    storey: num(listing.floor),
    floors: num(listing.floors),
    furniture:
      listing.furnished === "yes"
        ? "WITH"
        : listing.furnished === "no"
          ? "WITHOUT"
          : null,
    hashtags: HASHTAGS[listing.bucket] ?? null,
    price: priceFor(listing),
    priceType: CURRENCY[listing.currency] ?? "UZS",
    stage: "ACTIVE",
    description: listing.description,
    nearPlaces: nearPlacesFor(listing),
    options: optionsFor(listing),
    active: true,
    lat: listing.lat,
    lng: listing.lng,
    agentId,
    // Keep OLX's own publish date so the marketplace's "newest first" ordering
    // has a realistic spread instead of 30 rows sharing one timestamp.
    createdAt: new Date(listing.created),
    photos: {
      create: listing.photos.map((url, position) => ({
        url,
        objectKey: `olx/${url.split("/files/")[1] ?? url}`,
        position,
      })),
    },
  };
}

async function main() {
  const agents = [];
  for (const agent of AGENTS) {
    const { email, ...rest } = agent;
    agents.push(
      await prisma.user.upsert({
        where: { email },
        update: { role: "AGENT", realtorStatus: "APPROVED" },
        create: {
          ...rest,
          email,
          passwordHash: await bcrypt.hash("password123", 10),
          role: "AGENT",
          realtorStatus: "APPROVED",
          realtorAppliedAt: new Date(),
          realtorDecidedAt: new Date(),
        },
      }),
    );
  }

  const references = listings.map((listing) => `OLX-${listing.olxId}`);
  const stale = await prisma.ad.findMany({
    where: { reference: { in: references } },
    select: { id: true },
  });
  const staleIds = stale.map((ad) => ad.id);
  // ActivityEvent.adId is onDelete: SetNull, so dropping the ads alone would
  // leave the AD_CREATED rows behind with a null adId and keep inflating the
  // agent cards' "N listings" on every re-run. Clear them first.
  await prisma.activityEvent.deleteMany({ where: { adId: { in: staleIds } } });
  const { count: removed } = await prisma.ad.deleteMany({
    where: { id: { in: staleIds } },
  });

  for (const [index, listing] of listings.entries()) {
    const agent = agents[index % agents.length];
    const ad = await prisma.ad.create({ data: adDataFor(listing, agent.id) });
    // GET /api/agents derives "N listings" from AD_CREATED events rather than
    // counting the ads table (agentRepository.countAdsByAgentIds), so seeding
    // straight into Prisma has to write the event the ad service normally
    // would -- otherwise every seeded agent reads as "0 listings".
    await prisma.activityEvent.create({
      data: {
        type: "AD_CREATED",
        agentId: agent.id,
        adId: ad.id,
        createdAt: ad.createdAt,
        meta: { source: "olx-seed", olxId: listing.olxId },
      },
    });
  }

  const byBucket = listings.reduce((acc, listing) => {
    acc[listing.bucket] = (acc[listing.bucket] ?? 0) + 1;
    return acc;
  }, {});

  console.log(
    `OLX seed complete: ${listings.length} ads across ${agents.length} agents` +
      (removed ? ` (replaced ${removed} from a previous run)` : ""),
  );
  console.table(byBucket);
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
