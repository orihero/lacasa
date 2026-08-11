-- CreateEnum
CREATE TYPE "DevicePlatform" AS ENUM ('IOS', 'ANDROID');

-- CreateTable. Server-side plumbing only -- no Flutter code registers a
-- device against this table yet (see prisma/schema.prisma's DeviceToken doc
-- comment and pushService.js). The table exists now so device registration
-- and push delivery can be built incrementally without a later migration
-- blocking either.
CREATE TABLE "device_tokens" (
    "id" UUID NOT NULL,
    "user_id" UUID NOT NULL,
    "token" TEXT NOT NULL,
    "platform" "DevicePlatform" NOT NULL,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    CONSTRAINT "device_tokens_pkey" PRIMARY KEY ("id")
);

-- CreateIndex. Re-registering the same device (an app relaunch resending
-- its current FCM token, or a reinstall reissued the same one) is the same
-- fact, not a second row -- this is what makes POST /api/push/devices
-- idempotent. Mirrors saved_ads' @@unique([userId, adId]).
CREATE UNIQUE INDEX "device_tokens_user_id_token_key" ON "device_tokens"("user_id", "token");

-- CreateIndex. Serves the one read this table has: "every device registered
-- to this user", looked up on every fire-and-forget push send.
CREATE INDEX "device_tokens_user_id_idx" ON "device_tokens"("user_id");

-- AddForeignKey
ALTER TABLE "device_tokens" ADD CONSTRAINT "device_tokens_user_id_fkey" FOREIGN KEY ("user_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- No backfill: device tokens did not exist in any form before this table --
-- every mobile install that registers one going forward starts as a fresh row.
