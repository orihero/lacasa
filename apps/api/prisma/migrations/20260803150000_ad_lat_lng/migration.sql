-- AlterTable
-- Nullable Decimal(9,6) per docs/10-backend-for-liquid-glass.md §3 (listing-
-- detail map pin). Purely additive: every existing ad keeps NULL for both
-- columns -- no backfill, no geocoding here (that's an explicit separate
-- follow-up). "lat and lng must be set together, or both null" is an
-- application-level rule, not a DB constraint -- see
-- apps/api/src/services/adService.js#validateCoordinates -- because it needs
-- to see the pre-existing row on a partial PATCH, which a CHECK constraint
-- can't do.
ALTER TABLE "ads" ADD COLUMN     "lat" DECIMAL(9,6),
ADD COLUMN     "lng" DECIMAL(9,6);
