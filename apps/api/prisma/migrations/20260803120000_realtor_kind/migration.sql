-- CreateEnum
CREATE TYPE "RealtorKind" AS ENUM ('SOLO', 'AGENCY');

-- CreateEnum
CREATE TYPE "RealtorStatus" AS ENUM ('NONE', 'PENDING', 'APPROVED', 'REJECTED');

-- CreateEnum
CREATE TYPE "TeamSize" AS ENUM ('JUST_ME', 'TWO_TO_FIVE', 'SIX_TO_FIFTEEN', 'SIXTEEN_PLUS');

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "agency_name" TEXT,
ADD COLUMN     "office_phone" TEXT,
ADD COLUMN     "realtor_applied_at" TIMESTAMPTZ,
ADD COLUMN     "realtor_decided_at" TIMESTAMPTZ,
ADD COLUMN     "realtor_kind" "RealtorKind",
ADD COLUMN     "realtor_status" "RealtorStatus" NOT NULL DEFAULT 'NONE',
ADD COLUMN     "team_size" "TeamSize";

-- Backfill. Every agent that exists today predates the solo/agency split and
-- has always been able to add coworkers, so they are grandfathered in as
-- approved agencies rather than silently losing their team. Coworkers keep a
-- null kind: the team facts belong to the agent they hang off.
UPDATE "users"
SET "realtor_kind" = 'AGENCY',
    "realtor_status" = 'APPROVED',
    "realtor_applied_at" = "created_at",
    "realtor_decided_at" = "created_at"
WHERE "role" = 'AGENT';

-- CreateIndex
CREATE INDEX "users_realtor_status_idx" ON "users"("realtor_status");
