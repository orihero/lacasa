-- AlterEnum
-- Drops REALTING from PublishChannel. The Realting.uz integration was never
-- built and will never be built, so the value is not a reservation for
-- future work any more -- it is a channel every status grid, label map and
-- retry guard in this monorepo had to keep answering for.
--
-- Postgres has no DROP VALUE for an enum type, so the type is recreated and
-- the column re-pointed at the new one. This is the shape `prisma migrate
-- dev` generates for a removed enum value, written out here so the
-- accompanying DELETE can be stated explicitly rather than left to a
-- USING clause that would fail on the first surviving row.
--
-- The DELETE is defensive, not corrective: nothing in this codebase ever
-- wrote a REALTING publication row (no route, no worker, no seed produced
-- one), so this is expected to match zero rows on every environment. It is
-- here because the ALTER COLUMN below cannot cast a row that still holds
-- the removed label, and a migration that fails halfway through on a
-- database nobody predicted is worse than one that states its cleanup.
DELETE FROM "ad_publications" WHERE "channel" = 'REALTING';

ALTER TYPE "PublishChannel" RENAME TO "PublishChannel_old";
CREATE TYPE "PublishChannel" AS ENUM ('TELEGRAM', 'INSTAGRAM', 'YOUTUBE', 'OLX');
ALTER TABLE "ad_publications"
  ALTER COLUMN "channel" TYPE "PublishChannel" USING ("channel"::text::"PublishChannel");
DROP TYPE "PublishChannel_old";
