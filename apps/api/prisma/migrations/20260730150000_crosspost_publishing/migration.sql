-- CreateEnum
CREATE TYPE "PublishChannel" AS ENUM ('TELEGRAM', 'INSTAGRAM', 'YOUTUBE', 'OLX', 'REALTING');

-- CreateEnum
CREATE TYPE "PublishStatus" AS ENUM ('PENDING', 'DRAFTED_AWAITING_REVIEW', 'PUBLISHED', 'FAILED');

-- AlterEnum
ALTER TYPE "EventType" ADD VALUE 'OLX_CROSSPOST_STARTED';
ALTER TYPE "EventType" ADD VALUE 'OLX_CROSSPOST_COMPLETED';
ALTER TYPE "EventType" ADD VALUE 'OLX_CROSSPOST_ABORTED';
ALTER TYPE "EventType" ADD VALUE 'IG_ASSIST_STARTED';
ALTER TYPE "EventType" ADD VALUE 'IG_ASSIST_COMPLETED';
ALTER TYPE "EventType" ADD VALUE 'IG_ASSIST_ABORTED';

-- AlterTable (agent_ig_tokens is empty pre-migration, so the NOT NULL add is safe)
ALTER TABLE "agent_ig_tokens" ADD COLUMN     "expires_at" TIMESTAMPTZ,
ADD COLUMN     "ig_user_id" TEXT NOT NULL,
ADD COLUMN     "ig_username" TEXT,
ADD COLUMN     "refreshed_at" TIMESTAMPTZ;

-- AlterTable
ALTER TABLE "users" ADD COLUMN     "ig_assist_consent_at" TIMESTAMPTZ;

-- CreateTable
CREATE TABLE "ad_publications" (
    "id" UUID NOT NULL,
    "ad_id" TEXT NOT NULL,
    "channel" "PublishChannel" NOT NULL,
    "status" "PublishStatus" NOT NULL DEFAULT 'PENDING',
    "external_id" TEXT,
    "external_url" TEXT,
    "payload" JSONB DEFAULT '{}',
    "attempts" INTEGER NOT NULL DEFAULT 0,
    "last_attempt_at" TIMESTAMPTZ,
    "published_at" TIMESTAMPTZ,
    "error_message" TEXT,
    "requested_by_id" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "ad_publications_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "ad_publications_channel_status_idx" ON "ad_publications"("channel", "status");

-- CreateIndex
CREATE UNIQUE INDEX "ad_publications_ad_id_channel_key" ON "ad_publications"("ad_id", "channel");

-- CreateIndex
CREATE INDEX "agent_ig_tokens_expires_at_idx" ON "agent_ig_tokens"("expires_at");

-- CreateIndex
CREATE UNIQUE INDEX "agent_ig_tokens_agent_id_ig_user_id_key" ON "agent_ig_tokens"("agent_id", "ig_user_id");

-- AddForeignKey
ALTER TABLE "ad_publications" ADD CONSTRAINT "ad_publications_requested_by_id_fkey" FOREIGN KEY ("requested_by_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;
