import { Router } from "express";
import { prisma } from "../lib/prisma.js";

const router = Router();

router.get("/currency", async (_req, res, next) => {
  try {
    const rate = await prisma.currencyRate.findUnique({ where: { code: "USD" } });
    if (!rate) return res.status(404).json({ error: { code: "not_found", message: "No currency rate configured" } });
    res.json({ code: rate.code, rate: Number(rate.rate) });
  } catch (e) {
    next(e);
  }
});

router.get("/nearby-places", async (_req, res, next) => {
  try {
    const options = await prisma.nearbyPlaceOption.findMany({ orderBy: { position: "asc" } });
    res.json(options.map((o) => o.label));
  } catch (e) {
    next(e);
  }
});

export default router;
