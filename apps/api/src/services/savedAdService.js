import { serializeAd } from "../lib/adsSerializer.js";
import * as savedAdRepository from "../repositories/savedAdRepository.js";

// The saved list is a list of listings, so each row serializes as the ad
// itself. `saved: true` is redundant here (everything in this list is saved)
// but keeps one shape for the card component wherever it renders.
function serializeSavedAd(row) {
  return { ...serializeAd(row.ad), saved: true };
}

export async function listSavedAds(ctx, userId) {
  const rows = await savedAdRepository.findManySavedAdsForUser(ctx.prisma, userId);
  return rows.map(serializeSavedAd);
}

// Returns false when adId is well-formed but references no ad — the FK is what
// detects that, so there is no separate existence query to race against.
// Callers turn that into a 404. The route guarantees adId is UUID-shaped
// before we get here, so P2003 (FK violation) is the only "no such ad" code
// Prisma can raise; anything else is a real fault and propagates.
export async function saveAd(ctx, userId, adId) {
  try {
    await savedAdRepository.upsertSavedAd(ctx.prisma, userId, adId);
    return true;
  } catch (e) {
    if (e.code === "P2003") return false;
    throw e;
  }
}

// Always succeeds. Unsaving something not saved leaves the caller in exactly
// the state they asked for, so it is not an error worth reporting.
export async function unsaveAd(ctx, userId, adId) {
  await savedAdRepository.deleteSavedAd(ctx.prisma, userId, adId);
}
