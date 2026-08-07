-- AlterTable
-- Purely additive; existing ads keep NULL and render the photo carousel as
-- they do today. The http(s)-only rule on this value is enforced at the write
-- boundary (packages/domain's adInputSchema via apps/api/src/routes/ads.js),
-- not here: it protects an <iframe src> on the listing-detail page, which is
-- an application concern rather than a storage one.
ALTER TABLE "ads" ADD COLUMN     "tour_3d_link" TEXT;
