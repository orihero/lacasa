import { describe, expect, it, vi } from "vitest";
import { createFakePrisma } from "../helpers/testApp.js";
import * as agentService from "../../src/services/agentService.js";

function makeAgent(overrides = {}) {
  return {
    id: "agent-1",
    fullName: "Javlon Rustamov",
    email: "javlon@example.test",
    phoneNumber: "+998901234567",
    avatarUrl: null,
    address: null,
    passwordHash: "never-serialized",
    role: "AGENT",
    ...overrides,
  };
}

// No ratings anywhere unless a test overrides it — matches an agent with
// zero AgentReview rows, the common case most tests below aren't about.
function noRatings() {
  return vi.fn().mockResolvedValue([]);
}

describe("listAgents", () => {
  it("counts every agent's ads in one grouped query, defaulting agents with none to 0", async () => {
    const findMany = vi.fn().mockResolvedValue([makeAgent(), makeAgent({ id: "agent-2" })]);
    const groupBy = vi.fn().mockResolvedValue([{ agentId: "agent-1", _count: { _all: 7 } }]);
    const prisma = createFakePrisma({
      user: { findMany },
      activityEvent: { groupBy },
      agentReview: { groupBy: noRatings() },
    });

    const agents = await agentService.listAgents({ prisma });

    expect(groupBy).toHaveBeenCalledTimes(1);
    expect(groupBy).toHaveBeenCalledWith({
      by: ["agentId"],
      where: { type: "AD_CREATED", agentId: { in: ["agent-1", "agent-2"] } },
      _count: { _all: true },
    });
    expect(agents.map((a) => a.adsCount)).toEqual([7, 0]);
  });

  it("aggregates every agent's rating in a single groupBy — no per-card query", async () => {
    const findMany = vi.fn().mockResolvedValue([makeAgent(), makeAgent({ id: "agent-2" })]);
    const ratingGroupBy = vi.fn().mockResolvedValue([{ agentId: "agent-1", _avg: { rating: 4.3333 }, _count: { _all: 3 } }]);
    const prisma = createFakePrisma({
      user: { findMany },
      activityEvent: { groupBy: noRatings() },
      agentReview: { groupBy: ratingGroupBy },
    });

    const agents = await agentService.listAgents({ prisma });

    expect(ratingGroupBy).toHaveBeenCalledTimes(1);
    expect(ratingGroupBy).toHaveBeenCalledWith({
      by: ["agentId"],
      where: { agentId: { in: ["agent-1", "agent-2"] } },
      _avg: { rating: true },
      _count: { _all: true },
    });
    const [agent1, agent2] = agents;
    expect(agent1.ratingAverage).toBe(4.3); // rounded to one decimal
    expect(agent1.ratingCount).toBe(3);
    // Zero reviews must read as absent, never a zero-star rating.
    expect(agent2.ratingAverage).toBeNull();
    expect(agent2.ratingCount).toBe(0);
  });

  it("never serializes the password hash onto the public card", async () => {
    const findMany = vi.fn().mockResolvedValue([makeAgent()]);
    const groupBy = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({
      user: { findMany },
      activityEvent: { groupBy },
      agentReview: { groupBy: noRatings() },
    });

    const [agent] = await agentService.listAgents({ prisma });

    expect(agent).not.toHaveProperty("passwordHash");
    expect(agent).not.toHaveProperty("role");
  });
});

describe("getAgent", () => {
  it("returns the card with both ad counts and the rating aggregate", async () => {
    const findFirst = vi.fn().mockResolvedValue(makeAgent());
    const groupBy = vi.fn().mockResolvedValue([{ agentId: "agent-1", _count: { _all: 24 } }]);
    const adGroupBy = vi.fn().mockResolvedValue([
      { stage: "ACTIVE", _count: { _all: 15 } },
      { stage: "SOLD", _count: { _all: 9 } },
    ]);
    const ratingGroupBy = vi.fn().mockResolvedValue([{ agentId: "agent-1", _avg: { rating: 5 }, _count: { _all: 2 } }]);
    const prisma = createFakePrisma({
      user: { findFirst },
      activityEvent: { groupBy },
      ad: { groupBy: adGroupBy },
      agentReview: { groupBy: ratingGroupBy },
    });

    const agent = await agentService.getAgent({ prisma }, "agent-1");

    expect(findFirst).toHaveBeenCalledWith({ where: { id: "agent-1", role: "AGENT" } });
    expect(adGroupBy).toHaveBeenCalledWith({
      by: ["stage"],
      where: { agentId: "agent-1" },
      _count: { _all: true },
    });
    expect(ratingGroupBy).toHaveBeenCalledWith({
      by: ["agentId"],
      where: { agentId: { in: ["agent-1"] } },
      _avg: { rating: true },
      _count: { _all: true },
    });
    expect(agent).toEqual({
      id: "agent-1",
      fullName: "Javlon Rustamov",
      email: "javlon@example.test",
      phoneNumber: "+998901234567",
      avatar: null,
      address: null,
      adsCount: 24,
      ratingAverage: 5,
      ratingCount: 2,
      dealsClosedCount: 9,
    });
  });

  it("reports 0 rather than undefined for an agent with no ads and nothing sold", async () => {
    const prisma = createFakePrisma({
      user: { findFirst: vi.fn().mockResolvedValue(makeAgent()) },
      activityEvent: { groupBy: vi.fn().mockResolvedValue([]) },
      ad: { groupBy: vi.fn().mockResolvedValue([]) },
      agentReview: { groupBy: noRatings() },
    });

    const agent = await agentService.getAgent({ prisma }, "agent-1");

    expect(agent.adsCount).toBe(0);
    expect(agent.dealsClosedCount).toBe(0);
  });

  // The honesty rule this project holds to (see CLAUDE.md): a fake trust
  // signal is worse than none, so zero reviews must come out as `null`,
  // never `0` / `0.0` — a number there would render as a real (if bad)
  // rating instead of "No reviews yet".
  it("reports ratingAverage: null and ratingCount: 0 for an agent with zero reviews — never 0.0", async () => {
    const prisma = createFakePrisma({
      user: { findFirst: vi.fn().mockResolvedValue(makeAgent()) },
      activityEvent: { groupBy: vi.fn().mockResolvedValue([]) },
      ad: { groupBy: vi.fn().mockResolvedValue([]) },
      agentReview: { groupBy: noRatings() },
    });

    const agent = await agentService.getAgent({ prisma }, "agent-1");

    expect(agent.ratingAverage).toBeNull();
    expect(agent.ratingCount).toBe(0);
  });

  it("exposes the agent's address on the card", async () => {
    const prisma = createFakePrisma({
      user: { findFirst: vi.fn().mockResolvedValue(makeAgent({ address: "12 Amir Temur, Tashkent" })) },
      activityEvent: { groupBy: vi.fn().mockResolvedValue([]) },
      ad: { groupBy: vi.fn().mockResolvedValue([]) },
      agentReview: { groupBy: noRatings() },
    });

    const agent = await agentService.getAgent({ prisma }, "agent-1");

    expect(agent.address).toBe("12 Amir Temur, Tashkent");
  });

  // createFakePrisma throws on any un-stubbed call, so leaving the count
  // queries unstubbed is itself the assertion that none of them run.
  it("returns null without running any count/rating query when no agent matches", async () => {
    const prisma = createFakePrisma({ user: { findFirst: vi.fn().mockResolvedValue(null) } });

    expect(await agentService.getAgent({ prisma }, "nope")).toBeNull();
  });
});
