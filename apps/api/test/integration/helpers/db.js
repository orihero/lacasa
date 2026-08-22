import { PrismaClient } from "@prisma/client";

// Deliberately has no dependency on "vitest" (unlike helpers/lifecycle.js):
// test/integration/globalSetup.js imports this module directly, and vitest
// globalSetup files run in a separate context from test files — importing
// "vitest" there throws "Vitest failed to access its internal state."
// helpers/lifecycle.js wraps this with the vitest-aware afterAll hook for
// test files to use instead.

// Same default as vitest.config.js's TEST_DATABASE_URL — kept here too
// (instead of importing the config file) because vitest.config.js isn't
// meant to be imported by test code, and test/integration/globalSetup.js
// needs this constant before any project's `env` config has been applied.
export const TEST_DATABASE_URL =
  process.env.TEST_DATABASE_URL ?? "postgresql://lacasa:lacasa_dev@localhost:5432/lacasa_test";

// Never relies on ambient DATABASE_URL — always points at the disposable
// test database explicitly, so a mistake in the `env` wiring can't silently
// point an integration test at the real dev database in apps/api/.env.
export function createTestPrismaClient() {
  return new PrismaClient({ datasources: { db: { url: TEST_DATABASE_URL } } });
}

// Truncates every application table (everything except Prisma's own
// migrations bookkeeping table), resetting identity sequences too. Building
// the table list from pg_tables instead of hand-maintaining one means a new
// model never silently escapes cleanup.
export async function truncateAllTables(prisma) {
  const rows = await prisma.$queryRaw`
    SELECT tablename FROM pg_tables
    WHERE schemaname = 'public' AND tablename <> '_prisma_migrations'
  `;
  if (rows.length === 0) return;
  const tableList = rows.map((r) => `"${r.tablename}"`).join(", ");
  await prisma.$executeRawUnsafe(`TRUNCATE TABLE ${tableList} RESTART IDENTITY CASCADE`);
}
