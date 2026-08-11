-- AlterTable
ALTER TABLE "users" ADD COLUMN     "address" TEXT;

-- CreateTable
CREATE TABLE "agent_reviews" (
    "id" UUID NOT NULL,
    "agent_id" UUID NOT NULL,
    "author_id" UUID NOT NULL,
    "rating" INTEGER NOT NULL,
    "comment" TEXT,
    "created_at" TIMESTAMPTZ NOT NULL DEFAULT CURRENT_TIMESTAMP,
    "updated_at" TIMESTAMPTZ NOT NULL,

    -- Prisma's schema language has no range-constraint syntax, so this is
    -- the only place the 1..5 rule is enforced at the DB layer. It stays
    -- as a last line of defense even though reviewService.js also checks
    -- it -- any writer that bypasses the service (a script, a future
    -- migration, a bug) still can't put a value outside the range on disk.
    CONSTRAINT "agent_reviews_rating_check" CHECK ("rating" BETWEEN 1 AND 5),
    CONSTRAINT "agent_reviews_pkey" PRIMARY KEY ("id")
);

-- CreateIndex. Serves both reads this model has: the aggregate ("all
-- reviews for one agent") and the list ("...ordered by newest first").
CREATE INDEX "agent_reviews_agent_id_created_at_idx" ON "agent_reviews"("agent_id", "created_at");

-- CreateIndex. One review per (author, agent) -- an average that ten posts
-- from the same account could swing wouldn't mean anything, so a re-review
-- edits the existing row instead of adding another.
CREATE UNIQUE INDEX "agent_reviews_agent_id_author_id_key" ON "agent_reviews"("agent_id", "author_id");

-- AddForeignKey
ALTER TABLE "agent_reviews" ADD CONSTRAINT "agent_reviews_agent_id_fkey" FOREIGN KEY ("agent_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- AddForeignKey
ALTER TABLE "agent_reviews" ADD CONSTRAINT "agent_reviews_author_id_fkey" FOREIGN KEY ("author_id") REFERENCES "users"("id") ON DELETE CASCADE ON UPDATE CASCADE;

-- No backfill: reviews did not exist in any form before this table, and
-- `address` has no prior source column to carry over -- both start empty.
