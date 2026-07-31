import { execSync } from "node:child_process";
import { TEST_DATABASE_URL, createTestPrismaClient, truncateAllTables } from "./helpers/db.js";

// Runs once before every test in the "integration" vitest project (see
// vitest.config.js) — never per file, never per test.
//
// 1. `prisma migrate deploy` against the disposable test database, so the
//    integration suite always runs against the current schema without ever
//    touching `prisma migrate dev`'s shadow-database/drift machinery (that's
//    a `migrate dev` thing; `deploy` just applies committed migrations —
//    safe to run repeatedly, including against a database that already has
//    them applied).
// 2. A defensive truncate of every table, in case a previous run crashed
//    mid-suite and left rows behind — every individual test file also
//    truncates in its own afterAll (test/integration/helpers/db.js), but
//    this guarantees the very first file starts from an empty database too.
export default async function setup() {
  try {
    execSync("npx prisma migrate deploy", {
      cwd: process.cwd(),
      env: { ...process.env, DATABASE_URL: TEST_DATABASE_URL },
      stdio: "pipe",
    });
  } catch (e) {
    const output = [e.stdout?.toString(), e.stderr?.toString()].filter(Boolean).join("\n");
    throw new Error(
      `prisma migrate deploy failed against TEST_DATABASE_URL=${TEST_DATABASE_URL} — is the local Postgres reachable and does the database exist?\n${output}`,
    );
  }

  const prisma = createTestPrismaClient();
  try {
    await truncateAllTables(prisma);
  } finally {
    await prisma.$disconnect();
  }
}
