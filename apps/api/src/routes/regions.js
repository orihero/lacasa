// The region/district vocabulary for Uzbekistan (14 regions, 203 districts).
// The source of truth is @lacasa/domain's regions.json -- imported here, not
// copied. Two copies of a 203-row list drift the moment one side gets a
// district renamed, and nobody remembers to touch both.
//
// @lacasa/domain/data/regions.ts documents why this data was previously
// build-time-import-only (docs/10 §5 Decision 2/3: it's static, so a round
// trip buys JS consumers nothing). That reasoning still holds for
// apps/web and apps/api itself, which keep importing it directly. This
// route exists for a caller that reasoning didn't cover: apps/mobile_flutter
// is Dart and cannot `import` an npm package at build time, so it needs the
// same vocabulary served over HTTP instead. See the updated doc comment on
// the domain package for the full decision record.
//
// Public, unauthenticated -- same trust level as GET /api/ads. The payload
// is static reference data with no user-specific content, so there's
// nothing here worth gating behind requireAuth.
import { Router } from "express";
import regionsData from "@lacasa/domain/data/regions";

const router = Router();

// One day of caching plus a strong "immutable-ish" hint: this data changes
// on a code deploy (a new build of @lacasa/domain), never on its own, so a
// stale client copy is never wrong mid-day. Not literally `immutable`
// because Cache-Control: immutable has patchy proxy/CDN support and
// max-age=86400 + conditional revalidation gets the same practical result
// (a 304 with no body) without depending on that support.
const CACHE_CONTROL = "public, max-age=86400";

router.get("/", (req, res) => {
  res.set("Cache-Control", CACHE_CONTROL);

  const { regionId } = req.query;

  if (regionId === undefined) {
    // res.json() runs the body through Express's built-in weak ETag
    // (etag package) and, because the request carries a matching
    // If-None-Match, response.send() answers 304 with no body on its own --
    // no manual conditional-GET handling needed here. Verified against a
    // live request rather than assumed; see the integration test.
    return res.json({ regions: regionsData.regions, districts: regionsData.districts });
  }

  // Cascading city -> district pickers already hold the full region list
  // (that's what populates the first dropdown) and only need the second
  // dropdown's options once a region is chosen. Filtering both arrays down
  // to the one region -- rather than trimming just `districts` and leaving
  // `districts` -- keeps the response shape identical in both cases, so the
  // client can use one parser for both.
  //
  // An unknown or non-numeric regionId is not an error: it's a filter that
  // matched nothing, same as a search with no results, so this answers 200
  // with empty arrays rather than 400/404. That also means a client can
  // pass through whatever the region selector gave it without pre-validating.
  const id = Number(regionId);
  const matchedRegions = regionsData.regions.filter((r) => r.id === id);
  const matchedDistricts = regionsData.districts.filter((d) => d.region_id === id);

  res.json({ regions: matchedRegions, districts: matchedDistricts });
});

export default router;
