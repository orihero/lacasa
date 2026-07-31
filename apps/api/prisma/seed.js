import { PrismaClient } from "@prisma/client";
import bcrypt from "bcryptjs";

const prisma = new PrismaClient();

// Adjust labels to match what the ad form should offer (old Firestore
// `nearbyList` doc was maintained by hand).
const NEARBY_PLACES = [
  "Maktab",
  "Bog'cha",
  "Metro",
  "Supermarket",
  "Shifoxona",
  "Park",
  "Avtoturargoh",
];

async function main() {
  await prisma.currencyRate.upsert({
    where: { code: "USD" },
    update: {},
    create: { code: "USD", rate: 12900 },
  });

  for (const [position, label] of NEARBY_PLACES.entries()) {
    await prisma.nearbyPlaceOption.upsert({
      where: { label },
      update: { position },
      create: { label, position },
    });
  }

  await prisma.user.upsert({
    where: { email: "agent@lacasa.dev" },
    update: {},
    create: {
      fullName: "Dev Agent",
      email: "agent@lacasa.dev",
      passwordHash: await bcrypt.hash("password123", 10),
      role: "AGENT",
      phoneNumber: "+998900000000",
    },
  });

  console.log("Seed complete: currency rate, nearby places, agent@lacasa.dev / password123");
}

main()
  .catch((e) => {
    console.error(e);
    process.exit(1);
  })
  .finally(() => prisma.$disconnect());
