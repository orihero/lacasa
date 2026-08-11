import { afterEach, describe, expect, it, vi } from "vitest";
import { createFakePrisma } from "../helpers/testApp.js";
import { logActivityEvent, createWithActivityEvent } from "../../src/lib/activity.js";
import { config } from "../../src/lib/config.js";

// logActivityEvent (and, through it, createWithActivityEvent) now fires
// pushService.js#notifyForActivityEvent as a side effect of every
// ActivityEvent write -- see activity.js's own header comment. These tests
// cover the guarantee that side effect is explicitly documented to uphold:
// no matter how badly the push subsystem fails, the ActivityEvent write
// this function exists for still lands and its result is still returned to
// the caller. notificationService.js/pushService.test.js already cover the
// push copy itself; this file only covers the "can't break the caller" contract.
const ORIGINAL_KEY = config.FCM_SERVER_KEY;
const ORIGINAL_CONFIGURED = config.PUSH_CONFIGURED;

afterEach(() => {
  config.FCM_SERVER_KEY = ORIGINAL_KEY;
  config.PUSH_CONFIGURED = ORIGINAL_CONFIGURED;
  vi.restoreAllMocks();
});

describe("logActivityEvent", () => {
  it("still creates and returns the ActivityEvent row when the push subsystem is fully broken", async () => {
    // Forces notifyForActivityEvent past its "unconfigured, skip silently"
    // no-op and into the code path that actually tries to look up device
    // tokens -- config.FCM_SERVER_KEY is unset in every other test file, so
    // without this the push side effect would never even attempt anything
    // and this test would prove nothing.
    config.FCM_SERVER_KEY = "key";
    config.PUSH_CONFIGURED = true;

    const created = {
      id: "event-1",
      type: "LEAD_CREATED",
      agentId: "agent-1",
      coworkerId: null,
      leadId: "lead-1",
      createdAt: new Date(),
    };
    const prisma = createFakePrisma({
      activityEvent: { create: vi.fn().mockResolvedValue(created) },
      // Everything the push side effect could possibly touch for this event
      // type throws -- the relation lookup notifyForActivityEvent needs to
      // build the LEAD_CREATED copy.
      lead: { findUnique: vi.fn().mockRejectedValue(new Error("db exploded")) },
    });
    const errorSpy = vi.spyOn(console, "error").mockImplementation(() => {});

    const event = await logActivityEvent({ prisma }, "LEAD_CREATED", { agentId: "agent-1", coworkerId: null }, { leadId: "lead-1" });

    expect(event).toEqual(created);
    // The failure happened and was logged -- it just never escaped as a
    // rejection this caller would have had to handle.
    expect(errorSpy).toHaveBeenCalled();
  });

  it("does not attempt any push side effect at all for an event type with no notification kind, and still returns the row", async () => {
    config.FCM_SERVER_KEY = "key";
    config.PUSH_CONFIGURED = true;

    const created = {
      id: "event-1",
      type: "OLX_CROSSPOST_STARTED",
      agentId: "agent-1",
      coworkerId: null,
      leadId: null,
      adId: null,
      createdAt: new Date(),
    };
    const leadFindUnique = vi.fn();
    const prisma = createFakePrisma({
      activityEvent: { create: vi.fn().mockResolvedValue(created) },
      lead: { findUnique: leadFindUnique },
    });

    const event = await logActivityEvent({ prisma }, "OLX_CROSSPOST_STARTED", { agentId: "agent-1", coworkerId: null, meta: { adId: "ad-1", channel: "OLX" } });

    expect(event).toEqual(created);
    expect(leadFindUnique).not.toHaveBeenCalled();
  });
});

describe("createWithActivityEvent", () => {
  it("still creates and returns the model row when the push subsystem is fully broken", async () => {
    config.FCM_SERVER_KEY = "key";
    config.PUSH_CONFIGURED = true;

    const leadRow = { id: "lead-1", fullName: "Jane Buyer" };
    const eventRow = {
      id: "event-1",
      type: "LEAD_CREATED",
      agentId: "agent-1",
      coworkerId: null,
      leadId: "lead-1",
      createdAt: new Date(),
    };
    const prisma = createFakePrisma({
      lead: {
        create: vi.fn().mockResolvedValue(leadRow),
        // notifyForActivityEvent's own best-effort re-fetch of the lead --
        // deliberately broken to prove it can't unwind the create above.
        findUnique: vi.fn().mockRejectedValue(new Error("db exploded")),
      },
      activityEvent: { create: vi.fn().mockResolvedValue(eventRow) },
    });
    vi.spyOn(console, "error").mockImplementation(() => {});

    const row = await createWithActivityEvent(
      { prisma },
      "lead",
      "LEAD_CREATED",
      { data: { fullName: "Jane Buyer" } },
      { agentId: "agent-1", coworkerId: null },
    );

    expect(row).toEqual(leadRow);
  });
});
