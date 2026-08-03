-- CreateEnum
CREATE TYPE "AdMediaType" AS ENUM ('PHOTO', 'VIDEO');

-- AlterTable
-- DEFAULT 'PHOTO' makes this additive rather than breaking: every existing
-- ad_photos row (all of which are photos today — nothing in the current
-- upload path ever created a video row) backfills to 'PHOTO' as part of the
-- same statement that adds the column, no separate UPDATE needed.
ALTER TABLE "ad_photos" ADD COLUMN     "media_type" "AdMediaType" NOT NULL DEFAULT 'PHOTO';
