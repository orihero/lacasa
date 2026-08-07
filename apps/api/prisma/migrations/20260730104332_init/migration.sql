-- CreateEnum
CREATE TYPE "UserRole" AS ENUM ('USER', 'AGENT', 'COWORKER');

-- CreateEnum
CREATE TYPE "AdType" AS ENUM ('RESIDENTIAL', 'NONRESIDENTIAL');

-- CreateEnum
CREATE TYPE "AdCategory" AS ENUM ('RENT', 'SALE');

-- CreateEnum
CREATE TYPE "Repairment" AS ENUM ('NOT_REPAIRED', 'NORMAL', 'GOOD', 'EXCELLENT');

-- CreateEnum
CREATE TYPE "Furniture" AS ENUM ('WITH', 'WITHOUT');

-- CreateEnum
CREATE TYPE "AdStage" AS ENUM ('ACTIVE', 'SOLD', 'DRAFT');

-- CreateEnum
CREATE TYPE "CurrencyCode" AS ENUM ('UZS', 'USD');

-- CreateEnum
CREATE TYPE "LeadStatus" AS ENUM ('NEW', 'COULD_NOT_CONNECT', 'NEED_TO_CALL_BACK', 'REJECTED', 'ACCEPTED');

-- CreateEnum
CREATE TYPE "EventType" AS ENUM ('AD_CREATED', 'AD_SOLD', 'AD_DRAFT_UPDATED', 'LEAD_CREATED', 'LEAD_STATUS_CHANGED');

-- CreateTable
CREATE TABLE "users" (
    "id" UUID NOT NULL,
    "full_name" TEXT NOT NULL,
    "email" TEXT NOT NULL,
    "password_hash" TEXT NOT NULL,
    "role" "UserRole" NOT NULL DEFAULT 'USER',
    "phone_number" TEXT,
    "avatar_url" TEXT,
    "tg_chat_ids" BIGINT[],
    "agent_id" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "users_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "agent_ig_tokens" (
    "id" UUID NOT NULL,
    "agent_id" UUID NOT NULL,
    "access_token" TEXT NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "agent_ig_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ads" (
    "id" UUID NOT NULL,
    "title" TEXT NOT NULL,
    "city" TEXT NOT NULL,
    "district" TEXT NOT NULL,
    "address" TEXT,
    "reference" TEXT,
    "type" "AdType" NOT NULL,
    "category" "AdCategory" NOT NULL,
    "repairment" "Repairment",
    "rooms" INTEGER,
    "area" DECIMAL(10,2),
    "storey" INTEGER,
    "floors" INTEGER,
    "furniture" "Furniture",
    "hashtags" TEXT,
    "price" DECIMAL(14,2) NOT NULL,
    "price_type" "CurrencyCode" NOT NULL,
    "stage" "AdStage" NOT NULL DEFAULT 'ACTIVE',
    "description" TEXT,
    "near_places" TEXT[],
    "options" JSONB NOT NULL DEFAULT '[]',
    "active" BOOLEAN NOT NULL DEFAULT true,
    "agent_id" UUID NOT NULL,
    "coworker_id" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "ads_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "ad_photos" (
    "id" UUID NOT NULL,
    "ad_id" UUID NOT NULL,
    "object_key" TEXT NOT NULL,
    "url" TEXT NOT NULL,
    "position" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "ad_photos_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "leads" (
    "id" UUID NOT NULL,
    "full_name" TEXT NOT NULL,
    "phone" TEXT NOT NULL,
    "email" TEXT,
    "budget" DECIMAL(14,2),
    "comment" TEXT,
    "conversation_comment" TEXT,
    "status" "LeadStatus" NOT NULL DEFAULT 'NEW',
    "source" TEXT,
    "callback_date" TIMESTAMPTZ,
    "active" BOOLEAN NOT NULL DEFAULT true,
    "agent_id" UUID NOT NULL,
    "coworker_id" UUID,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "leads_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "activity_events" (
    "id" UUID NOT NULL,
    "type" "EventType" NOT NULL,
    "agent_id" UUID NOT NULL,
    "coworker_id" UUID,
    "ad_id" UUID,
    "lead_id" UUID,
    "meta" JSONB,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "activity_events_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "currency_rates" (
    "id" UUID NOT NULL,
    "code" "CurrencyCode" NOT NULL,
    "rate" DECIMAL(14,2) NOT NULL,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "currency_rates_pkey" PRIMARY KEY ("id")
);

-- CreateTable
CREATE TABLE "nearby_place_options" (
    "id" UUID NOT NULL,
    "label" TEXT NOT NULL,
    "position" INTEGER NOT NULL DEFAULT 0,

    CONSTRAINT "nearby_place_options_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE UNIQUE INDEX "users_email_key" ON "users"("email");

-- CreateIndex
CREATE INDEX "users_agent_id_idx" ON "users"("agent_id");

-- CreateIndex
CREATE INDEX "users_role_idx" ON "users"("role");

-- CreateIndex
CREATE INDEX "agent_ig_tokens_agent_id_idx" ON "agent_ig_tokens"("agent_id");

-- CreateIndex
CREATE INDEX "ads_agent_id_stage_idx" ON "ads"("agent_id", "stage");

-- CreateIndex
CREATE INDEX "ads_stage_active_idx" ON "ads"("stage", "active");

-- CreateIndex
CREATE INDEX "ad_photos_ad_id_idx" ON "ad_photos"("ad_id");

-- CreateIndex
CREATE INDEX "leads_agent_id_idx" ON "leads"("agent_id");

-- CreateIndex
CREATE INDEX "leads_coworker_id_idx" ON "leads"("coworker_id");

-- CreateIndex
CREATE INDEX "activity_events_agent_id_created_at_idx" ON "activity_events"("agent_id", "created_at");

-- CreateIndex
CREATE INDEX "activity_events_type_idx" ON "activity_events"("type");

-- CreateIndex
CREATE UNIQUE INDEX "currency_rates_code_key" ON "currency_rates"("code");

-- CreateIndex
CREATE UNIQUE INDEX "nearby_place_options_label_key" ON "nearby_place_options"("label");

-- AddForeignKey
ALTER TABLE "users" ADD CONSTRAINT "users_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "agent_ig_tokens" ADD CONSTRAINT "agent_ig_tokens_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ads" ADD CONSTRAINT "ads_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ads" ADD CONSTRAINT "ads_coworker_id_fkey" FOREIGN KEY ("coworker_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "ad_photos" ADD CONSTRAINT "ad_photos_ad_id_fkey" FOREIGN KEY ("ad_id") REFERENCES "ads"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "leads" ADD CONSTRAINT "leads_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "leads" ADD CONSTRAINT "leads_coworker_id_fkey" FOREIGN KEY ("coworker_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_events" ADD CONSTRAINT "activity_events_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_events" ADD CONSTRAINT "activity_events_coworker_id_fkey" FOREIGN KEY ("coworker_id") REFERENCES "users"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_events" ADD CONSTRAINT "activity_events_ad_id_fkey" FOREIGN KEY ("ad_id") REFERENCES "ads"("id") ON DELETE SET NULL ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "activity_events" ADD CONSTRAINT "activity_events_lead_id_fkey" FOREIGN KEY ("lead_id") REFERENCES "leads"("id") ON DELETE SET NULL ON UPDATE CASCADE;
