import { describe, expect, it } from "vitest";
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
