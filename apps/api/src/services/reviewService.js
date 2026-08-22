import { z } from "zod";
import * as agentRepository from "../repositories/agentRepository.js";
import { httpError } from "../lib/httpError.js";

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 50;

// rating's 1..5 range is also a DB CHECK constraint (see the AgentReview
// model comment in schema.prisma) -- that's the last line of defense
// against any writer that bypasses this service, not a replacement for
// this check, which is what turns a bad value into a normal
// `{ error: { code: "validation" } }` envelope instead of a raw Postgres
// constraint-violation the client can't parse.
const reviewInputSchema = z.object({
  rating: z.number().int().min(1).max(5),
  comment: z.string().max(2000).optional().nullable(),
});

// Public identity only -- fullName + avatar, the same restriction
// agentService's serializeAgent already applies to the *subject* of a
// card. A review's author is a buyer or another agent, and neither their
// email nor phone number has any business leaving the server on a public,
// unauthenticated GET.
function serializeAuthor(author) {
  return { id: author.id, fullName: author.fullName, avatar: author.avatarUrl };
}

// createdAt as `{ seconds }`, matching every other timestamp on the wire
// (adsSerializer.js#serializeAd, leadService.js, statisticsService.js's
// `toSeconds`, notificationService.js) -- the old Firestore Timestamp shape
// the Dart client's wire_timestamp.dart still models. A bare `review.createdAt`
// Date would JSON.stringify to a raw ISO-8601 string instead, a different
// shape from every other endpoint's `createdAt` field.
function serializeReview(review) {
  return {
    id: review.id,
    rating: review.rating,
    comment: review.comment,
    createdAt: { seconds: Math.floor(new Date(review.createdAt).getTime() / 1000) },
    author: serializeAuthor(review.author),
  };
}

// Newest first, `?limit=&cursor=`. `cursor` is the last review id from the
// previous page (opaque to the client -- it's just a uuid, not encoded).
// Fetches one row past the requested page size so "was that the last page"
// can be answered from this single query instead of a second COUNT(*).
export async function listReviews(ctx, agentId, { limit, cursor } = {}) {
  const take = Math.min(Math.max(1, Number(limit) || DEFAULT_LIMIT), MAX_LIMIT);
  const rows = await agentRepository.findReviewsForAgent(ctx.prisma, agentId, { take: take + 1, cursor });
  const hasMore = rows.length > take;
  const page = hasMore ? rows.slice(0, take) : rows;
  return {
    reviews: page.map(serializeReview),
    nextCursor: hasMore ? page[page.length - 1].id : null,
  };
}

// Upserts on (agentId, authorId): posting twice edits the existing review
// rather than stacking a second one next to it.
//
// Check order is deliberate: body shape first (cheapest, no DB round trip),
// then the self-review comparison (also free -- both ids are already in
// hand), and only then the agent-exists lookup, which is the one check that
// actually needs the database. A malformed rating or a self-review never
// pays for a query it doesn't need.
export async function createOrUpdateReview(ctx, agentId, authorId, body) {
  const parsed = reviewInputSchema.safeParse(body);
  if (!parsed.success) {
    throw httpError(400, "validation", parsed.error.issues[0].message);
  }

  if (agentId === authorId) {
    throw httpError(403, "forbidden", "You may not review yourself");
  }

  const agent = await agentRepository.findAgentById(ctx.prisma, agentId);
  if (!agent) {
    throw httpError(404, "not_found", "Agent not found");
  }

  const review = await agentRepository.upsertReview(ctx.prisma, {
    agentId,
    authorId,
    rating: parsed.data.rating,
    comment: parsed.data.comment ?? null,
  });
  return serializeReview(review);
}

// Always succeeds, like savedAdService.js#unsaveAd -- removing a review that
// was never posted (or already removed) leaves the caller in exactly the
// state they asked for.
export async function deleteOwnReview(ctx, agentId, authorId) {
  await agentRepository.deleteReview(ctx.prisma, agentId, authorId);
}
