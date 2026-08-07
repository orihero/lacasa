-- CreateTable
CREATE TABLE "saved_ads" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "ad_id" UUID NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,

    CONSTRAINT "saved_ads_pkey" PRIMARY KEY ("id")
);

-- CreateIndex
CREATE INDEX "saved_ads_user_id_idx" ON "saved_ads"("user_id");

-- CreateIndex
CREATE INDEX "saved_ads_ad_id_idx" ON "saved_ads"("ad_id");

-- CreateIndex. Column order matches Prisma's generated `userId_adId` compound
-- key, which the upsert in savedAdRepository.js addresses by name.
CREATE UNIQUE INDEX "saved_ads_user_id_ad_id_key" ON "saved_ads"("user_id", "ad_id");

-- AddForeignKey
ALTER TABLE "saved_ads" ADD CONSTRAINT "saved_ads_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "saved_ads" ADD CONSTRAINT "saved_ads_ad_id_fkey" FOREIGN KEY ("ad_id") REFERENCES "ads"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- No backfill: favourites did not exist in any form before this table, so
-- there is nothing to carry over. Every user starts with an empty list.
