import { afterAll } from "vitest";
import { createTestPrismaClient, truncateAllTables } from "./db.js";

// Call once at the top of every test/routes/*.integration.test.js file.
// Returns a real PrismaClient connected to the disposable test database and
// registers the between-*files* cleanup: once this file's tests are done,
// truncate every table and release the connection. fileParallelism is off
// for the "integration" project (vitest.config.js), so the next file always
// starts from an empty database — tests *within* one file share state and
// must therefore use distinct emails/ids rather than relying on isolation.
//
// Kept out of helpers/db.js on purpose: this imports "vitest" for afterAll,
// and test/integration/globalSetup.js (which imports helpers/db.js
// directly, and runs in a separate context from test files) can't import
// "vitest" without vitest throwing "failed to access its internal state".
export function useIntegrationDb() {
  const prisma = createTestPrismaClient();
  afterAll(async () => {
    await truncateAllTables(prisma);
    await prisma.$disconnect();
  });
  return prisma;
}
