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
    passwordHash: "never-serialized",
    role: "AGENT",
    ...overrides,
  };
}

describe("listAgents", () => {
  it("counts every agent's ads in one grouped query, defaulting agents with none to 0", async () => {
    const findMany = vi.fn().mockResolvedValue([makeAgent(), makeAgent({ id: "agent-2" })]);
    const groupBy = vi.fn().mockResolvedValue([{ agentId: "agent-1", _count: { _all: 7 } }]);
    const prisma = createFakePrisma({ user: { findMany }, activityEvent: { groupBy } });

    const agents = await agentService.listAgents({ prisma });

    expect(groupBy).toHaveBeenCalledTimes(1);
    expect(groupBy).toHaveBeenCalledWith({
      by: ["agentId"],
      where: { type: "AD_CREATED", agentId: { in: ["agent-1", "agent-2"] } },
      _count: { _all: true },
    });
    expect(agents.map((a) => a.adsCount)).toEqual([7, 0]);
  });

  it("never serializes the password hash onto the public card", async () => {
    const findMany = vi.fn().mockResolvedValue([makeAgent()]);
    const groupBy = vi.fn().mockResolvedValue([]);
    const prisma = createFakePrisma({ user: { findMany }, activityEvent: { groupBy } });

    const [agent] = await agentService.listAgents({ prisma });

    expect(agent).not.toHaveProperty("passwordHash");
    expect(agent).not.toHaveProperty("role");
  });
});

describe("getAgent", () => {
  it("returns the card with both counts", async () => {
    const findFirst = vi.fn().mockResolvedValue(makeAgent());
    const groupBy = vi.fn().mockResolvedValue([{ agentId: "agent-1", _count: { _all: 24 } }]);
    const adGroupBy = vi.fn().mockResolvedValue([
      { stage: "ACTIVE", _count: { _all: 15 } },
      { stage: "SOLD", _count: { _all: 9 } },
    ]);
    const prisma = createFakePrisma({
      user: { findFirst },
      activityEvent: { groupBy },
      ad: { groupBy: adGroupBy },
    });

    const agent = await agentService.getAgent({ prisma }, "agent-1");

    expect(findFirst).toHaveBeenCalledWith({ where: { id: "agent-1", role: "AGENT" } });
    expect(adGroupBy).toHaveBeenCalledWith({
      by: ["stage"],
      where: { agentId: "agent-1" },
      _count: { _all: true },
    });
    expect(agent).toEqual({
      id: "agent-1",
      fullName: "Javlon Rustamov",
      email: "javlon@example.test",
      phoneNumber: "+998901234567",
      avatar: null,
      adsCount: 24,
      dealsClosedCount: 9,
    });
  });

  it("reports 0 rather than undefined for an agent with no ads and nothing sold", async () => {
    const prisma = createFakePrisma({
      user: { findFirst: vi.fn().mockResolvedValue(makeAgent()) },
      activityEvent: { groupBy: vi.fn().mockResolvedValue([]) },
      ad: { groupBy: vi.fn().mockResolvedValue([]) },
    });

    const agent = await agentService.getAgent({ prisma }, "agent-1");

    expect(agent.adsCount).toBe(0);
    expect(agent.dealsClosedCount).toBe(0);
  });

  // createFakePrisma throws on any un-stubbed call, so leaving the count
  // queries unstubbed is itself the assertion that neither one runs.
  it("returns null without running either count query when no agent matches", async () => {
    const prisma = createFakePrisma({ user: { findFirst: vi.fn().mockResolvedValue(null) } });

    expect(await agentService.getAgent({ prisma }, "nope")).toBeNull();
  });
});
