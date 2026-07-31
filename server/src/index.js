import "dotenv/config";
import express from "express";
import cors from "cors";
import { prisma } from "./lib/prisma.js";
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
import statisticsRouter from "./routes/statistics.js";
import { scheduleIgTokenRefresh } from "./lib/igTokenRefresh.js";
import { llmConfigured } from "./lib/llm.js";

const app = express();

app.use(cors({ origin: process.env.CORS_ORIGIN?.split(",") ?? true }));
app.use(express.json({ limit: "1mb" }));

app.get("/api/health", async (_req, res) => {
  try {
    await prisma.$queryRaw`SELECT 1`;
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
app.use("/api/statistics", statisticsRouter);

// Route modules still to come: /api/contact (docs/05-migration-plan.md Phase E)

app.use((err, _req, res, _next) => {
  console.error(err);
  res.status(500).json({ error: { code: "internal", message: "Internal server error" } });
});

scheduleIgTokenRefresh();

if (!llmConfigured) {
  console.warn(
    "[warn] ANTHROPIC_API_KEY is not set — extension-assisted cross-posting will fail at the caption/field-mapping step.",
  );
}

const port = Number(process.env.PORT ?? 4200);
app.listen(port, () => console.log(`API listening on http://localhost:${port}`));
