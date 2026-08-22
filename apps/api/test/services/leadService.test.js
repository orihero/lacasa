import { describe, expect, it, vi } from "vitest";
import { createFakePrisma } from "../helpers/testApp.js";
import * as leadService from "../../src/services/leadService.js";

function makeLead(overrides = {}) {
  return {
    id: "lead-1",
    fullName: "Jane Doe",
    phone: "+998901234567",
    email: null,
    budget: "50000",
    comment: null,
    conversationComment: null,
    status: "NEW",
    source: null,
    callbackDate: null,
    active: true,
    agentId: "agent-1",
    coworkerId: null,
    createdAt: new Date("2026-01-01T00:00:00Z"),
    updatedAt: new Date("2026-01-01T00:00:00Z"),
    ...overrides,
  };
}

describe("listLeads", () => {
  it("lists every lead for the agent scope, newest first", async () => {
    const findMany = vi.fn().mockResolvedValue([makeLead()]);
    const prisma = createFakePrisma({ lead: { findMany } });

    const leads = await leadService.listLeads({ prisma }, "agent-1");

    expect(findMany).toHaveBeenCalledWith({ where: { agentId: "agent-1" }, orderBy: { createdAt: "desc" } });
    expect(leads).toHaveLength(1);
    expect(leads[0].budget).toBe(50000);
  });
});

describe("getLead", () => {
  it("returns null when nothing matches id + agentId", async () => {
    const prisma = createFakePrisma({ lead: { findFirst: vi.fn().mockResolvedValue(null) } });
    expect(await leadService.getLead({ prisma }, "lead-1", "agent-1")).toBeNull();
  });
});

describe("createLead", () => {
  it("creates the lead and logs a LEAD_CREATED activity event tied to the actor", async () => {
    const created = makeLead();
    const create = vi.fn().mockResolvedValue(created);
    const activityCreate = vi.fn().mockResolvedValue({});
    const prisma = createFakePrisma({ lead: { create }, activityEvent: { create: activityCreate } });
    const actor = { agentId: "agent-1", coworkerId: "coworker-1" };

    const lead = await leadService.createLead({ prisma }, { fullName: "Jane Doe", phone: "+998901234567" }, actor);

    const createArgs = create.mock.calls[0][0];
    expect(createArgs.data.agentId).toBe("agent-1");
    expect(createArgs.data.coworkerId).toBe("coworker-1");
    expect(createArgs.data.status).toBe("NEW");
    expect(createArgs.data.active).toBe(true);

    expect(activityCreate).toHaveBeenCalledWith({
      data: { type: "LEAD_CREATED", agentId: "agent-1", coworkerId: "coworker-1", leadId: created.id },
    });
    expect(lead.id).toBe(created.id);
  });
});

describe("updateLead", () => {
  it("returns null when no lead matches id + agentId (404 case)", async () => {
    const prisma = createFakePrisma({ lead: { findFirst: vi.fn().mockResolvedValue(null) } });
    const result = await leadService.updateLead({ prisma }, "lead-1", "agent-1", {}, { agentId: "agent-1", coworkerId: null });
    expect(result).toBeNull();
  });

  it("logs LEAD_STATUS_CHANGED unconditionally, even when status isn't in the body", async () => {
    const existing = makeLead();
    const updated = makeLead({ comment: "called back" });
    const prisma = createFakePrisma({
      lead: { findFirst: vi.fn().mockResolvedValue(existing), update: vi.fn().mockResolvedValue(updated) },
      activityEvent: { create: vi.fn().mockResolvedValue({}) },
    });

    await leadService.updateLead({ prisma }, "lead-1", "agent-1", { comment: "called back" }, { agentId: "agent-1", coworkerId: null });

    expect(prisma.activityEvent.create).toHaveBeenCalledWith({
      data: { type: "LEAD_STATUS_CHANGED", agentId: "agent-1", coworkerId: null, leadId: updated.id },
    });
  });
});

describe("deleteLead", () => {
  it("returns null when no lead matches (404 case)", async () => {
    const prisma = createFakePrisma({ lead: { findFirst: vi.fn().mockResolvedValue(null) } });
    expect(await leadService.deleteLead({ prisma }, "lead-1", "agent-1")).toBeNull();
  });

  it("deletes the row and returns true when found", async () => {
    const del = vi.fn().mockResolvedValue({});
    const prisma = createFakePrisma({ lead: { findFirst: vi.fn().mockResolvedValue(makeLead()), delete: del } });

    const result = await leadService.deleteLead({ prisma }, "lead-1", "agent-1");

    expect(result).toBe(true);
    expect(del).toHaveBeenCalledWith({ where: { id: "lead-1" } });
  });
});
