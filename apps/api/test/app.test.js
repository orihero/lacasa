import { describe, expect, it, vi } from "vitest";
import supertest from "supertest";
import { buildTestApp } from "./helpers/testApp.js";

// Proves the app.js / ctx seam actually works: supertest(app) against a
// fully fake req.ctx, no real Postgres/MinIO/Anthropic connection, no
// app.listen() (so no port to collide on), no scheduleIgTokenRefresh()
// timer running in the background. Should leave vitest with no open handle
// to force-exit on.
describe("GET /api/health", () => {
  it("returns 200 with db up when prisma resolves", async () => {
    const app = buildTestApp();
    const res = await supertest(app).get("/api/health");
    expect(res.status).toBe(200);
    expect(res.body).toEqual({ ok: true, db: "up" });
  });

  it("returns 503 when prisma's health query fails", async () => {
    const app = buildTestApp({
      prisma: {
        async $queryRaw() {
          throw new Error("db down");
        },
      },
    });
    const res = await supertest(app).get("/api/health");
    expect(res.status).toBe(503);
    expect(res.body).toEqual({ ok: false, db: "down" });
  });
});

// Regression guard. Express recognises error-handling middleware by arity
// (fn.length === 4), so app.js's handler keeps an unused trailing `_next`.
// Deleting it — which a no-unused-vars warning actively invites — does not
// fail anything loudly: the handler just stops being an error handler, and
// Express's default one answers with an HTML page. Asserting the content type
// alongside the body is what catches that; the status is 500 either way.
describe("unhandled route errors", () => {
  it("answers with the JSON error envelope, not Express's default HTML page", async () => {
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});
    try {
      const app = buildTestApp({
        prisma: {
          ad: {
            async findMany() {
              throw new Error("boom");
            },
          },
        },
      });
      const res = await supertest(app).get("/api/ads");

      expect(res.status).toBe(500);
      expect(res.headers["content-type"]).toMatch(/application\/json/);
      expect(res.body).toEqual({
        error: { code: "internal", message: "Internal server error" },
      });
    } finally {
      errorSpy.mockRestore();
    }
  });
});
