import { AD_TYPE, AD_CATEGORY, REPAIRMENT, FURNITURE } from "../lib/enums.js";
import { serializeAd, parseAdInput } from "../lib/adsSerializer.js";
import { BUCKET, objectKeyFromUrl } from "../lib/minio.js";
import { createWithActivityEvent, logActivityEvent } from "../lib/activity.js";
import * as adRepository from "../repositories/adRepository.js";

export function buildAdFilters(query) {
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

function photosCreateData(photos) {
  return (photos ?? []).map((url, position) => ({ url, objectKey: objectKeyFromUrl(url), position }));
}

// Public listing (GET /api/ads, no `agentId` option) is always scoped to
// ACTIVE ads; the caller (myAds.js) supplies `agentId` (+ optional custom
// `orderBy`) to instead list everything a given agent owns, active or not.
export async function listAds(ctx, query, { agentId, orderBy } = {}) {
  const where = buildAdFilters(query);
  if (agentId) {
    where.agentId = agentId;
  } else {
    where.stage = "ACTIVE";
  }
  const ads = await adRepository.findManyAds(ctx.prisma, { where, orderBy: orderBy ?? { createdAt: "desc" } });
  return ads.map(serializeAd);
}

export async function getAd(ctx, id) {
  const ad = await adRepository.findAdById(ctx.prisma, id);
  return ad ? serializeAd(ad) : null;
}

export async function createAd(ctx, body, actor) {
  const data = parseAdInput(body);
  const photos = Array.isArray(body.photos) ? body.photos : [];

  const ad = await createWithActivityEvent(
    ctx,
    "ad",
    "AD_CREATED",
    {
      data: {
        ...data,
        priceType: data.priceType ?? "UZS",
        stage: data.stage ?? "ACTIVE",
        agentId: actor.agentId,
        coworkerId: actor.coworkerId,
        photos: { create: photosCreateData(photos) },
      },
      include: adRepository.AD_INCLUDE,
    },
    actor,
  );

  return serializeAd(ad);
}

// Returns null when no ad matches `id` under `agentId` (caller maps that to
// 404). `actor` drives the activity event, `agentId` scopes the lookup —
// they're the same value for an AGENT, different for a COWORKER acting on
// their agent's ads.
export async function updateAd(ctx, id, agentId, body, actor) {
  const existing = await adRepository.findAdByIdForAgent(ctx.prisma, id, agentId);
  if (!existing) return null;

  const data = parseAdInput(body);
  const photosProvided = Array.isArray(body.photos);

  const ad = await adRepository.updateAd(ctx.prisma, id, {
    ...data,
    ...(photosProvided ? { photos: { deleteMany: {}, create: photosCreateData(body.photos) } } : {}),
  });

  // Faithful to the original behavior (AdsEdit.tsx): any edit logs either
  // AD_SOLD (stage -> sold) or AD_DRAFT_UPDATED, never a distinct
  // "ad reactivated" event — see docs/03-data-model.md's statistics mapping.
  await logActivityEvent(ctx, data.stage === "SOLD" ? "AD_SOLD" : "AD_DRAFT_UPDATED", actor, { adId: ad.id });

  return serializeAd(ad);
}

// Returns null when no ad matches (404), true once deleted. Only an AGENT
// may delete (enforced by the route, which is why `agentId` here is always
// the caller's own id, never a coworker's agent scope).
export async function deleteAd(ctx, id, agentId) {
  const existing = await adRepository.findAdByIdForAgent(ctx.prisma, id, agentId);
  if (!existing) return null;

  await adRepository.deleteAd(ctx.prisma, id);

  await Promise.all(existing.photos.map((p) => ctx.minio.removeObject(BUCKET, p.objectKey).catch(() => {})));

  return true;
}

export async function stageCounts(ctx, agentId) {
  const counts = await adRepository.countAdsByStage(ctx.prisma, agentId);
  const byStage = Object.fromEntries(counts.map((c) => [c.stage, c._count._all]));
  return {
    stage1: byStage.ACTIVE ?? 0,
    stage2: byStage.SOLD ?? 0,
    stage3: byStage.DRAFT ?? 0,
  };
}
