import { Router } from "express";
import { prisma } from "../lib/prisma.js";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import { effectiveAgentId } from "../middleware/roles.js";
import { serializeAd, parseAdInput } from "../lib/adsSerializer.js";
import { minio, BUCKET, objectKeyFromUrl } from "../lib/minio.js";
import { AD_TYPE, AD_CATEGORY, REPAIRMENT, FURNITURE } from "../lib/enums.js";

const router = Router();

const AD_INCLUDE = { photos: true };

function buildAdFilters(query) {
  const where = {};
  if (query.agentId) where.agentId = query.agentId;
  if (query.city) where.city = query.city;
  if (query.district) where.district = query.district;
  if (query.category && AD_CATEGORY[query.category]) where.category = AD_CATEGORY[query.category];
  if (query.type && AD_TYPE[query.type]) where.type = AD_TYPE[query.type];
  if (query.rooms) where.rooms = Number(query.rooms);
  if (query.repairment && REPAIRMENT[query.repairment]) where.repairment = REPAIRMENT[query.repairment];
  if (query.storey) where.storey = Number(query.storey);
  if (query.furniture && FURNITURE[query.furniture]) where.furniture = FURNITURE[query.furniture];
  if (query.areaMin || query.areaMax) {
    where.area = {};
    if (query.areaMin) where.area.gte = Number(query.areaMin);
    if (query.areaMax) where.area.lte = Number(query.areaMax);
  }
  if (query.priceMin || query.priceMax) {
    where.price = {};
    if (query.priceMin) where.price.gte = Number(query.priceMin);
    if (query.priceMax) where.price.lte = Number(query.priceMax);
  }
  return where;
}

router.get("/", async (req, res, next) => {
  try {
    const ads = await prisma.ad.findMany({
      where: { ...buildAdFilters(req.query), stage: "ACTIVE" },
      include: AD_INCLUDE,
      orderBy: { createdAt: "desc" },
    });
    res.json(ads.map(serializeAd));
  } catch (e) {
    next(e);
  }
});

router.get("/:id", async (req, res, next) => {
  try {
    const ad = await prisma.ad.findUnique({ where: { id: req.params.id }, include: AD_INCLUDE });
    if (!ad) {
      return res.status(404).json({ error: { code: "not_found", message: "Ad not found" } });
    }
    res.json(serializeAd(ad));
  } catch (e) {
    next(e);
  }
});

router.post("/", requireAuth, loadCurrentUser, async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    if (!agentId) {
      return res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    }

    const data = parseAdInput(req.body);
    const photos = Array.isArray(req.body.photos) ? req.body.photos : [];

    const ad = await prisma.ad.create({
      data: {
        ...data,
        priceType: data.priceType ?? "UZS",
        stage: data.stage ?? "ACTIVE",
        agentId,
        coworkerId: req.currentUser.role === "COWORKER" ? req.currentUser.id : null,
        photos: {
          create: photos.map((url, position) => ({ url, objectKey: objectKeyFromUrl(url), position })),
        },
      },
      include: AD_INCLUDE,
    });

    await prisma.activityEvent.create({
      data: {
        type: "AD_CREATED",
        agentId,
        coworkerId: req.currentUser.role === "COWORKER" ? req.currentUser.id : null,
        adId: ad.id,
      },
    });

    res.status(201).json(serializeAd(ad));
  } catch (e) {
    next(e);
  }
});

router.patch("/:id", requireAuth, loadCurrentUser, async (req, res, next) => {
  try {
    const agentId = effectiveAgentId(req.currentUser);
    const existing = await prisma.ad.findFirst({ where: { id: req.params.id, agentId } });
    if (!existing) {
      return res.status(404).json({ error: { code: "not_found", message: "Ad not found" } });
    }

    const data = parseAdInput(req.body);
    const photosProvided = Array.isArray(req.body.photos);

    const ad = await prisma.ad.update({
      where: { id: req.params.id },
      data: {
        ...data,
        ...(photosProvided
          ? {
              photos: {
                deleteMany: {},
                create: req.body.photos.map((url, position) => ({
                  url,
                  objectKey: objectKeyFromUrl(url),
                  position,
                })),
              },
            }
          : {}),
      },
      include: AD_INCLUDE,
    });

    // Faithful to the original behavior (AdsEdit.tsx): any edit logs either
    // AD_SOLD (stage -> sold) or AD_DRAFT_UPDATED, never a distinct
    // "ad reactivated" event — see docs/03-data-model.md's statistics mapping.
    await prisma.activityEvent.create({
      data: {
        type: data.stage === "SOLD" ? "AD_SOLD" : "AD_DRAFT_UPDATED",
        agentId,
        coworkerId: req.currentUser.role === "COWORKER" ? req.currentUser.id : null,
        adId: ad.id,
      },
    });

    res.json(serializeAd(ad));
  } catch (e) {
    next(e);
  }
});

router.delete("/:id", requireAuth, loadCurrentUser, async (req, res, next) => {
  try {
    if (req.currentUser.role !== "AGENT") {
      return res.status(403).json({ error: { code: "forbidden", message: "Only the owning agent can delete an ad" } });
    }
    const existing = await prisma.ad.findFirst({
      where: { id: req.params.id, agentId: req.currentUser.id },
      include: AD_INCLUDE,
    });
    if (!existing) {
      return res.status(404).json({ error: { code: "not_found", message: "Ad not found" } });
    }

    await prisma.ad.delete({ where: { id: req.params.id } });

    await Promise.all(
      existing.photos.map((p) => minio.removeObject(BUCKET, p.objectKey).catch(() => {})),
    );

    res.status(204).end();
  } catch (e) {
    next(e);
  }
});

export { buildAdFilters, AD_INCLUDE };
export default router;
