import express from "express";
import cors from "cors";
import { config } from "./lib/config.js";
import { createPrismaClient } from "./lib/prisma.js";
import { createMinioClient } from "./lib/minio.js";
import { createLlmClient } from "./lib/llm.js";
import { attachCtx } from "./middleware/ctx.js";
import authRouter from "./routes/auth.js";
import utilsRouter from "./routes/utils.js";
import uploadsRouter from "./routes/uploads.js";
import instagramAuthRouter from "./routes/instagramAuth.js";
import publishRouter from "./routes/publish.js";
import usersRouter from "./routes/users.js";
import agentsRouter from "./routes/agents.js";
import coworkersRouter from "./routes/coworkers.js";
import adsRouter from "./routes/ads.js";
import myAdsRouter from "./routes/myAds.js";
import leadsRouter from "./routes/leads.js";
import savedAdsRouter from "./routes/savedAds.js";
import statisticsRouter from "./routes/statistics.js";
import contactRouter from "./routes/contact.js";

// Builds a fully wired Express app. Takes NO action beyond that: no
// app.listen(), no scheduleIgTokenRefresh() — those are src/server.js's job.
// That split is what makes this importable from a test with plain
// supertest(app): importing this module binds no TCP port and starts no
// timers, so parallel test workers never collide on a port and never fire a
// real 30s Instagram-token-refresh call against the live Graph API.
//
// ctx is the dependency-inversion seam: every route/middleware reads
// req.ctx.{prisma,minio,llm} instead of importing singletons, so a caller
// (test/helpers/testApp.js) can substitute hand-rolled fakes here instead of
// constructing real clients. Anything omitted falls back to a real client.
export function createApp(ctx = {}) {
  const prisma = ctx.prisma ?? createPrismaClient();
  const minio = ctx.minio ?? createMinioClient();
  const llm = ctx.llm ?? createLlmClient();

  if (!llm.configured) {
    console.warn(
      "[warn] ANTHROPIC_API_KEY is not set — extension-assisted cross-posting will fail at the caption/field-mapping step.",
    );
  }

  const app = express();

  app.use(cors({ origin: config.CORS_ORIGIN?.split(",") ?? true }));
  app.use(express.json({ limit: "1mb" }));
  app.use(attachCtx({ prisma, minio, llm }));

  app.get("/api/health", async (req, res) => {
    try {
      await req.ctx.prisma.$queryRaw`SELECT 1`;
      res.json({ ok: true, db: "up" });
    } catch {
      res.status(503).json({ ok: false, db: "down" });
    }
  });

  app.use("/api/auth/instagram", instagramAuthRouter);
  app.use("/api/auth", authRouter);
  app.use("/api/utils", utilsRouter);
  app.use("/api/uploads", uploadsRouter);
  app.use("/api/publish", publishRouter);
  app.use("/api/users", usersRouter);
  app.use("/api/agents", agentsRouter);
  app.use("/api/coworkers", coworkersRouter);
  app.use("/api/my/ads", myAdsRouter);
  app.use("/api/ads", adsRouter);
  app.use("/api/leads", leadsRouter);
  app.use("/api/saved-ads", savedAdsRouter);
  app.use("/api/statistics", statisticsRouter);
  app.use("/api/contact", contactRouter);

  // The `_next` parameter is load-bearing and must stay, unused as it is:
  // Express recognises error-handling middleware by arity alone (fn.length
  // === 4). Drop it and this silently stops being an error handler — errors
  // fall through to Express's default one, which answers text/html instead
  // of the `{ error: { code, message } }` envelope every client parses.
  app.use((err, _req, res, _next) => {
    console.error(err);
    res.status(500).json({ error: { code: "internal", message: "Internal server error" } });
  });

  return app;
}
