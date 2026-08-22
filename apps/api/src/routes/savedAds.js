import { Router } from "express";
import { requireAuth, loadCurrentUser } from "../middleware/auth.js";
import * as savedAdService from "../services/savedAdService.js";

const router = Router();

// A malformed :adId can never match a row, but handing a non-UUID string to a
// uuid column makes Prisma raise a *different* error code than the FK
// violation saveAd translates into a 404 — which would surface as a 500. It is
// cheaper and steadier to reject the shape here than to enumerate Prisma's
// error taxonomy.
const UUID_RE = /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i;

// Favourites belong to buyers: the heart is hidden for agents and coworkers
// (mockups/SCREENS.md §17), and that is enforced here rather than trusted to
// the client. Written as "not a plain USER" so a role added later is denied by
// default rather than silently allowed.
function refuseNonBuyer(req, res) {
  if (req.currentUser.role !== "USER") {
    res.status(403).json({ error: { code: "forbidden", message: "Not allowed for this role" } });
    return true;
  }
  return false;
}

router.use(requireAuth, loadCurrentUser);

// Readable by any authenticated role. An agent's list is simply always empty,
// which is less surprising than a 403 on a page that just wants to render.
router.get("/", async (req, res, next) => {
  try {
    res.json(await savedAdService.listSavedAds(req.ctx, req.currentUser.id));
  } catch (e) {
    next(e);
  }
});

router.post("/:adId", async (req, res, next) => {
  try {
    if (refuseNonBuyer(req, res)) return;
    if (!UUID_RE.test(req.params.adId)) {
      return res.status(404).json({ error: { code: "not_found", message: "Ad not found" } });
    }
    const saved = await savedAdService.saveAd(req.ctx, req.currentUser.id, req.params.adId);
    if (!saved) {
      return res.status(404).json({ error: { code: "not_found", message: "Ad not found" } });
    }
    // 200 rather than 201: the upsert makes a repeat save the same fact, so
    // the second call must answer exactly like the first.
    res.json({ ok: true });
  } catch (e) {
    next(e);
  }
});

router.delete("/:adId", async (req, res, next) => {
  try {
    if (refuseNonBuyer(req, res)) return;
    // A malformed id cannot have been saved, so the caller is already in the
    // state they asked for — same 204 as any other unsave.
    if (UUID_RE.test(req.params.adId)) {
      await savedAdService.unsaveAd(req.ctx, req.currentUser.id, req.params.adId);
    }
    res.status(204).end();
  } catch (e) {
    next(e);
  }
});

export default router;
