import { nodePreset } from "@lacasa/config-vitest/node";

// Integration tests hit a real, disposable Postgres database instead of the
// fake ctx.prisma the unit tests use — see test/integration/helpers/db.js.
// Defaults to the native-Postgres test database documented in README.md's
// "Option A — native" setup; CI (which runs docker-compose.yml instead)
// overrides this via TEST_DATABASE_URL.
const TEST_DATABASE_URL =
  process.env.TEST_DATABASE_URL ?? "postgresql://lacasa:lacasa_dev@localhost:5432/lacasa_test";

export default nodePreset({
  test: {
    // NonProjectOption — must live at the root, applies to every project.
    // The integration project's tests all share one Postgres database and
    // truncate it between *files* (see test/integration/helpers/db.js), so
    // two files must never execute concurrently against it.
    fileParallelism: false,
    projects: [
      {
        extends: true,
        test: {
          name: "unit",
          // src/**/*.test.js preserves the pre-existing default include
          // pattern's reach into src/__tests__/smoke.test.js — narrowing to
          // test/**/*.test.js alone would silently drop it from `npm run test`.
          include: ["test/**/*.test.js", "src/**/*.test.js"],
          exclude: ["test/routes/**/*.integration.test.js"],
        },
      },
      {
        extends: true,
        test: {
          name: "integration",
          include: ["test/routes/**/*.integration.test.js"],
          // Assigned to process.env before any test file (or the app.js /
          // config.js chain it imports) runs, so the real PrismaClient
          // created in test/integration/helpers/db.js — and anything else
          // that happens to read process.env.DATABASE_URL — resolves to
          // the disposable test database, never the dev one in apps/api/.env.
          env: { DATABASE_URL: TEST_DATABASE_URL, TEST_DATABASE_URL },
          globalSetup: ["./test/integration/globalSetup.js"],
          testTimeout: 20000,
          hookTimeout: 30000,
        },
      },
    ],
  },
});
