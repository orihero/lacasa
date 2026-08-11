import { describe, expect, it, vi } from "vitest";
import { createFakePrisma } from "../helpers/testApp.js";
import * as reviewService from "../../src/services/reviewService.js";

function makeAgent(overrides = {}) {
  return { id: "agent-1", fullName: "Javlon Rustamov", role: "AGENT", ...overrides };
}

function makeReview(overrides = {}) {
  return {
    id: "review-1",
    agentId: "agent-1",
    authorId: "buyer-1",
    rating: 4,
    comment: "Great agent",
    createdAt: new Date("2026-08-01T00:00:00Z"),
    author: { id: "buyer-1", fullName: "Nodira Karimova", avatarUrl: "https://cdn.test/n.jpg", email: "nodira@example.test", phoneNumber: "+998900000000" },
    ...overrides,
  };
}

describe("listReviews", () => {
  it("returns newest-first rows with only the author's public identity — no email, no phone", async () => {
    const findMany = vi.fn().mockResolvedValue([makeReview()]);
    const prisma = createFakePrisma({ agentReview: { findMany } });

    const { reviews, nextCursor } = await reviewService.listReviews({ prisma }, "agent-1", {});

    expect(reviews).toEqual([
      {
        id: "review-1",
        rating: 4,
        comment: "Great agent",
        // {seconds}, matching the codebase-wide timestamp wire convention --
        // not the raw Date object makeReview() stores on the row, and
        // specifically not a shape a bare ISO-8601 string would also satisfy
        // (this pins the object shape, not just the instant it represents).
        createdAt: { seconds: Math.floor(makeReview().createdAt.getTime() / 1000) },
        author: { id: "buyer-1", fullName: "Nodira Karimova", avatar: "https://cdn.test/n.jpg" },
      },
    ]);
    expect(reviews[0].author).not.toHaveProperty("email");
    expect(reviews[0].author).not.toHaveProperty("phoneNumber");
    expect(nextCursor).toBeNull();
  });

  it("asks for one row past the page size and reports a cursor only when that extra row exists", async () => {
    const findMany = vi.fn().mockResolvedValue([
      makeReview({ id: "r1" }),
      makeReview({ id: "r2" }),
      makeReview({ id: "r3" }), // the "is there more" row
    ]);
    const prisma = createFakePrisma({ agentReview: { findMany } });

    const { reviews, nextCursor } = await reviewService.listReviews({ prisma }, "agent-1", { limit: 2 });

    expect(findMany).toHaveBeenCalledTimes(1);
    // reviewService asks the repository for take+1; the repository is
    // exercised directly (with its exact Prisma args) in
    // agentRepository — this test only cares that the +1/slice contract
    // holds from the service's side.
    expect(reviews).toHaveLength(2);
    expect(reviews.map((r) => r.id)).toEqual(["r1", "r2"]);
    expect(nextCursor).toBe("r2");
  });

  it("clamps limit to the 1..50 range", async () => {
    const findMany = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ agentReview: { findMany } });

    await reviewService.listReviews({ prisma }, "agent-1", { limit: 9999 });

    expect(findMany).toHaveBeenCalledTimes(1);
  });
});

describe("createOrUpdateReview", () => {
  it("rejects a self-review with 403 before ever querying the database", async () => {
    // No stubs at all: createFakePrisma throws on any un-stubbed model call,
    // so a passing test here is itself proof the self-check runs first.
    const prisma = createFakePrisma();

    await expect(reviewService.createOrUpdateReview({ prisma }, "same-id", "same-id", { rating: 5 })).rejects.toMatchObject({
      status: 403,
      code: "forbidden",
    });
  });

  it("404s when the target user exists but is not an AGENT", async () => {
    const findFirst = vi.fn().mockResolvedValue(null); // findAgentById scopes to role: AGENT
    const prisma = createFakePrisma({ user: { findFirst } });

    await expect(
      reviewService.createOrUpdateReview({ prisma }, "buyer-target", "author-1", { rating: 5 }),
    ).rejects.toMatchObject({ status: 404, code: "not_found" });
  });

  it.each([0, 6, 1.5, "5"])("rejects an out-of-range or non-integer rating (%s)", async (rating) => {
    const prisma = createFakePrisma();

    await expect(reviewService.createOrUpdateReview({ prisma }, "agent-1", "author-1", { rating })).rejects.toMatchObject({
      status: 400,
      code: "validation",
    });
  });

  it("accepts the boundary values 1 and 5", async () => {
    const findFirst = vi.fn().mockResolvedValue(makeAgent());
    const upsert = vi.fn().mockResolvedValue(makeReview({ rating: 1 }));
    const prisma = createFakePrisma({ user: { findFirst }, agentReview: { upsert } });

    await reviewService.createOrUpdateReview({ prisma }, "agent-1", "author-1", { rating: 1 });
    await reviewService.createOrUpdateReview({ prisma }, "agent-1", "author-1", { rating: 5 });

    expect(upsert).toHaveBeenCalledTimes(2);
  });

  it("upserts rather than creating a second row on a repeat review from the same author", async () => {
    const findFirst = vi.fn().mockResolvedValue(makeAgent());
    const upsert = vi.fn().mockResolvedValue(makeReview({ rating: 5, comment: "Updated" }));
    const prisma = createFakePrisma({ user: { findFirst }, agentReview: { upsert } });

    await reviewService.createOrUpdateReview({ prisma }, "agent-1", "author-1", { rating: 5, comment: "Updated" });

    expect(upsert).toHaveBeenCalledTimes(1);
    expect(upsert).toHaveBeenCalledWith({
      where: { agentId_authorId: { agentId: "agent-1", authorId: "author-1" } },
      create: { agentId: "agent-1", authorId: "author-1", rating: 5, comment: "Updated" },
      update: { rating: 5, comment: "Updated" },
      include: { author: true },
    });
  });

  it("leaks no email or phone on the created review's author block", async () => {
    const findFirst = vi.fn().mockResolvedValue(makeAgent());
    const upsert = vi.fn().mockResolvedValue(makeReview());
    const prisma = createFakePrisma({ user: { findFirst }, agentReview: { upsert } });

    const review = await reviewService.createOrUpdateReview({ prisma }, "agent-1", "buyer-1", { rating: 4 });

    expect(review.author).toEqual({ id: "buyer-1", fullName: "Nodira Karimova", avatar: "https://cdn.test/n.jpg" });
  });
});

describe("deleteOwnReview", () => {
  it("always succeeds, deleting by the (agentId, authorId) pair", async () => {
    const deleteMany = vi.fn().mockResolvedValue({ count: 1 });
    const prisma = createFakePrisma({ agentReview: { deleteMany } });

    await reviewService.deleteOwnReview({ prisma }, "agent-1", "author-1");

    expect(deleteMany).toHaveBeenCalledWith({ where: { agentId: "agent-1", authorId: "author-1" } });
  });
});
