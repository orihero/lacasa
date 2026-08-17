import { readFileSync } from "node:fs";
import { describe, expect, it, vi } from "vitest";
import { createFakePrisma } from "../helpers/testApp.js";
import * as adminService from "../../src/services/adminService.js";

// The service layer's own contracts, called directly with a fake ctx —
// everything here is a rule the HTTP layer cannot express: what gets asked of
// Prisma (and how many times), what order the two write paths do things in,
// and what the service does when it is called by something that is not the
// route (a script, a future internal consumer) and therefore has no zod schema
// in front of it. The HTTP surface itself — status codes, validation, the role
// gate — is covered in test/routes/admin.test.js.

const USER_ID = "aaaaaaaa-0000-4000-8000-000000000001";
const OTHER_ID = "bbbbbbbb-0000-4000-8000-000000000002";
const THIRD_ID = "cccccccc-0000-4000-8000-000000000003";

// Interactive transactions must hand the callback a client with the same model
// surface as the root one, which is what real Prisma does and what
// createFakePrisma's own $transaction (it passes a bare $queryRaw-only object)
// does not.
function createAdminPrisma(overrides = {}) {
  const prisma = createFakePrisma({
    ...overrides,
    $transaction: (arg) => (Array.isArray(arg) ? Promise.all(arg) : arg(prisma)),
  });
  return prisma;
}

function makeUser(overrides = {}) {
  return {
    id: USER_ID,
    fullName: "Dilnoza Karimova",
    email: "dilnoza@example.test",
    passwordHash: "$2a$10$notarealbcrypthashbutshapedlikeone",
    role: "USER",
    phoneNumber: "+998901112233",
    avatarUrl: "https://cdn.test/avatar.jpg",
    address: "Amir Temur 1",
    tgChatIds: [],
    realtorKind: "AGENCY",
    realtorStatus: "PENDING",
    agencyName: "La Casa Realty",
    officePhone: "+998712001020",
    teamSize: "TWO_TO_FIVE",
    realtorAppliedAt: new Date("2026-08-01T09:00:00Z"),
    realtorDecidedAt: null,
    agentId: null,
    igAssistConsentAt: null,
    createdAt: new Date("2026-07-30T08:00:00Z"),
    updatedAt: new Date("2026-08-01T09:00:00Z"),
    ...overrides,
  };
}

const ctxOf = (prisma) => ({ prisma });

// ---------------------------------------------------------------------------
// Page sizing, shared by all four list functions

describe("page sizing", () => {
  const listWith = async (args) => {
    const findMany = vi.fn().mockResolvedValue([]);
    await adminService.listApplications(ctxOf(createAdminPrisma({ user: { findMany } })), args);
    return findMany.mock.calls[0][0].take;
  };

  it("defaults to 25 rows, fetching one extra to detect a next page", async () => {
    expect(await listWith({})).toBe(26);
    expect(await listWith(undefined)).toBe(26);
  });

  // The route already answers 400 for anything outside 1..100, so reaching
  // here with an out-of-range value means a non-HTTP caller. Clamping rather
  // than trusting it is what keeps a script from asking Postgres for 100k
  // rows in one statement.
  it.each([
    [500, 101],
    [101, 101],
    [100, 101],
    [0, 26],
    [-5, 2],
    ["abc", 26],
    [null, 26],
  ])("clamps a caller-supplied limit of %s to take %i", async (limit, take) => {
    expect(await listWith({ limit })).toBe(take);
  });
});

describe("keyset paging", () => {
  const usersPrisma = (rows) => {
    const findMany = vi.fn().mockResolvedValue(rows);
    return createAdminPrisma({
      user: { findMany },
      ad: { groupBy: vi.fn().mockResolvedValue([]) },
      lead: { groupBy: vi.fn().mockResolvedValue([]) },
    });
  };

  it("trims the extra row off and names the last kept row as the next cursor", async () => {
    const prisma = usersPrisma([
      makeUser({ id: USER_ID }),
      makeUser({ id: OTHER_ID }),
      makeUser({ id: THIRD_ID }),
    ]);

    const result = await adminService.listUsers(ctxOf(prisma), { limit: 2 });

    expect(result.items.map((u) => u.id)).toEqual([USER_ID, OTHER_ID]);
    expect(result.nextCursor).toBe(OTHER_ID);
  });

  // How a client knows to stop. A cursor pointing at the genuinely-last row
  // would make it request one more empty page forever.
  it("returns a null cursor when no extra row came back", async () => {
    const result = await adminService.listUsers(ctxOf(usersPrisma([makeUser()])), { limit: 2 });

    expect(result.nextCursor).toBeNull();
  });

  it("returns a null cursor for an empty result", async () => {
    const result = await adminService.listUsers(ctxOf(usersPrisma([])), {});

    expect(result).toEqual({ items: [], nextCursor: null });
  });
});

// ---------------------------------------------------------------------------
// getOverview

describe("getOverview", () => {
  const grouped = (field, entries) =>
    entries.map(([value, n]) => ({ [field]: value, _count: { _all: n } }));

  it("reads all six aggregates as one batched transaction, not six round trips", async () => {
    const transaction = vi.fn((statements) => Promise.all(statements));
    const prisma = createFakePrisma({
      $transaction: transaction,
      user: { groupBy: vi.fn().mockResolvedValue([]), findMany: vi.fn().mockResolvedValue([]) },
      ad: { groupBy: vi.fn().mockResolvedValue([]) },
      lead: { groupBy: vi.fn().mockResolvedValue([]) },
      adPublication: { groupBy: vi.fn().mockResolvedValue([]) },
    });

    await adminService.getOverview(ctxOf(prisma));

    expect(transaction).toHaveBeenCalledTimes(1);
    // The dashboard's tiles are one consistent snapshot; six independently
    // timed counts could disagree with each other mid-render.
    expect(transaction.mock.calls[0][0]).toHaveLength(6);
  });

  // Every total is summed from the groups that partition the same table
  // rather than fetched as its own count(), so the parts cannot disagree with
  // the whole no matter what the buckets say.
  it("sums each total from its own groups", async () => {
    const prisma = createFakePrisma({
      user: {
        groupBy: vi.fn(async ({ by }) =>
          by[0] === "role"
            ? grouped("role", [
                ["USER", 11],
                ["AGENT", 4],
              ])
            : grouped("realtorStatus", [["PENDING", 2]]),
        ),
        findMany: vi.fn().mockResolvedValue([]),
      },
      ad: { groupBy: vi.fn().mockResolvedValue(grouped("stage", [["ACTIVE", 3], ["SOLD", 1]])) },
      lead: { groupBy: vi.fn().mockResolvedValue(grouped("status", [["NEW", 6]])) },
      adPublication: { groupBy: vi.fn().mockResolvedValue([]) },
    });

    const overview = await adminService.getOverview(ctxOf(prisma));

    expect(overview.users.total).toBe(15);
    expect(overview.ads.total).toBe(4);
    expect(overview.leads.total).toBe(6);
  });

  it("zero-fills every bucket the enums define but the table has no rows for", async () => {
    const prisma = createFakePrisma({
      user: {
        groupBy: vi.fn().mockResolvedValue([]),
        findMany: vi.fn().mockResolvedValue([]),
      },
      ad: { groupBy: vi.fn().mockResolvedValue([]) },
      lead: { groupBy: vi.fn().mockResolvedValue([]) },
      adPublication: { groupBy: vi.fn().mockResolvedValue([]) },
    });

    const overview = await adminService.getOverview(ctxOf(prisma));

    expect(Object.keys(overview.leads.byStatus)).toEqual([
      "new",
      "could_not_connect",
      "need_to_call_back",
      "rejected",
      "accepted",
    ]);
    expect(Object.keys(overview.publications)).toEqual([
      "published",
      "failed",
      "pending",
      "drafted_awaiting_review",
    ]);
  });

  // A groupBy on an unfiltered table can only return values the Postgres enum
  // allows, so a value outside the map means the map is behind schema.prisma.
  // Ignoring it (rather than adding an untyped key to the payload) keeps the
  // response shape fixed; what must never happen is it being counted into a
  // neighbouring bucket.
  it("ignores a bucket the contract does not name rather than misfiling it", async () => {
    const prisma = createFakePrisma({
      user: {
        groupBy: vi.fn(async ({ by }) =>
          by[0] === "role" ? grouped("role", [["USER", 2], ["SUPERUSER", 9]]) : [],
        ),
        findMany: vi.fn().mockResolvedValue([]),
      },
      ad: { groupBy: vi.fn().mockResolvedValue([]) },
      lead: { groupBy: vi.fn().mockResolvedValue([]) },
      adPublication: { groupBy: vi.fn().mockResolvedValue([]) },
    });

    const overview = await adminService.getOverview(ctxOf(prisma));

    expect(overview.users.buyers).toBe(2);
    expect(overview.users.agents).toBe(0);
    expect(overview.users).not.toHaveProperty("SUPERUSER");
  });

  it("carries only id/name/email/role/createdAt for a recent signup", async () => {
    const prisma = createFakePrisma({
      user: {
        groupBy: vi.fn().mockResolvedValue([]),
        findMany: vi.fn().mockResolvedValue([makeUser({ role: "AGENT" })]),
      },
      ad: { groupBy: vi.fn().mockResolvedValue([]) },
      lead: { groupBy: vi.fn().mockResolvedValue([]) },
      adPublication: { groupBy: vi.fn().mockResolvedValue([]) },
    });

    const overview = await adminService.getOverview(ctxOf(prisma));

    expect(overview.recentSignups).toEqual([
      {
        id: USER_ID,
        fullName: "Dilnoza Karimova",
        email: "dilnoza@example.test",
        role: "agent",
        createdAt: "2026-07-30T08:00:00.000Z",
      },
    ]);
  });
});

// ---------------------------------------------------------------------------
// listApplications

describe("listApplications", () => {
  const applicationsPrisma = (rows) => {
    const findMany = vi.fn().mockResolvedValue(rows);
    return { prisma: createAdminPrisma({ user: { findMany } }), findMany };
  };

  it("defaults to the pending queue when called with no status", async () => {
    const { prisma, findMany } = applicationsPrisma([]);

    await adminService.listApplications(ctxOf(prisma), {});

    expect(findMany.mock.calls[0][0].where).toEqual({ realtorStatus: "PENDING" });
  });

  // The whole review table, and nothing an admin deciding an application has
  // any business seeing — an applicant's Telegram chat ids are not part of
  // the decision.
  it("carries the decision fields only, not the rest of serializeUser", async () => {
    const { prisma } = applicationsPrisma([makeUser({ tgChatIds: [] })]);

    const { items } = await adminService.listApplications(ctxOf(prisma), {});

    expect(Object.keys(items[0]).sort()).toEqual(
      ["createdAt", "email", "fullName", "id", "phoneNumber", "realtor"].sort(),
    );
    expect(items[0].realtor).toEqual({
      kind: "agency",
      status: "pending",
      agencyName: "La Casa Realty",
      officePhone: "+998712001020",
      teamSize: "two_to_five",
      appliedAt: new Date("2026-08-01T09:00:00Z"),
      decidedAt: null,
    });
  });

  // Both halves of an application are written together at signup, so this
  // should not occur — but reporting null is the honest answer for a row that
  // says nothing about its kind, and inventing "solo" would be worse.
  it("reports a null realtor block for a row with no realtorKind", async () => {
    const { prisma } = applicationsPrisma([makeUser({ realtorKind: null })]);

    const { items } = await adminService.listApplications(ctxOf(prisma), {});

    expect(items[0].realtor).toBeNull();
  });
});

// ---------------------------------------------------------------------------
// approveApplication / rejectApplication

describe("deciding an application", () => {
  // Records the order the service touches Prisma in, which is the only way to
  // assert that the row lock is taken *before* the read it is protecting.
  function tracedPrisma(existing) {
    const calls = [];
    const prisma = createAdminPrisma({
      $queryRaw: vi.fn(async () => {
        calls.push("lock");
        return [{ id: existing?.id }];
      }),
      user: {
        findUnique: vi.fn(async () => {
          calls.push("read");
          return existing;
        }),
        update: vi.fn(async ({ data }) => {
          calls.push("write");
          return { ...existing, ...data };
        }),
      },
    });
    return { prisma, calls };
  }

  // Under READ COMMITTED an unlocked re-read proves nothing: two admins
  // clicking Approve at the same moment would both see PENDING and both write
  // a decision, the second silently overwriting the first's realtorDecidedAt.
  it("locks the row before re-reading it, then writes — all in one transaction", async () => {
    const { prisma, calls } = tracedPrisma(makeUser());
    const transaction = vi.spyOn(prisma, "$transaction");

    await adminService.approveApplication(ctxOf(prisma), USER_ID);

    expect(calls).toEqual(["lock", "read", "write"]);
    expect(transaction).toHaveBeenCalledTimes(1);
  });

  it("stamps realtorDecidedAt at decision time on both outcomes", async () => {
    const before = Date.now();
    for (const [decide, status] of [
      [adminService.approveApplication, "APPROVED"],
      [adminService.rejectApplication, "REJECTED"],
    ]) {
      const { prisma } = tracedPrisma(makeUser());
      const { user } = await decide(ctxOf(prisma), USER_ID);

      expect(user.realtor.status).toBe(status.toLowerCase());
      expect(new Date(user.realtor.decidedAt).getTime()).toBeGreaterThanOrEqual(before);
    }
  });

  it("promotes only a buyer, and only on approval", async () => {
    const { prisma: approving } = tracedPrisma(makeUser({ role: "USER" }));
    expect((await adminService.approveApplication(ctxOf(approving), USER_ID)).user.role).toBe("agent");

    const { prisma: rejecting } = tracedPrisma(makeUser({ role: "USER" }));
    expect((await adminService.rejectApplication(ctxOf(rejecting), USER_ID)).user.role).toBe("user");
  });

  it.each(["AGENT", "COWORKER", "ADMIN"])("never rewrites the role of an existing %s", async (role) => {
    const { prisma } = tracedPrisma(makeUser({ role }));

    const { user } = await adminService.approveApplication(ctxOf(prisma), USER_ID);

    expect(user.role).toBe(role.toLowerCase());
  });

  it("throws a 409 not_pending, having written nothing, for an already-decided application", async () => {
    const { prisma, calls } = tracedPrisma(makeUser({ realtorStatus: "APPROVED" }));

    await expect(adminService.approveApplication(ctxOf(prisma), USER_ID)).rejects.toMatchObject({
      status: 409,
      code: "not_pending",
    });
    expect(calls).toEqual(["lock", "read"]);
  });

  it("throws a 404 not_found for an id no row matches", async () => {
    const { prisma } = tracedPrisma(null);

    await expect(adminService.rejectApplication(ctxOf(prisma), USER_ID)).rejects.toMatchObject({
      status: 404,
      code: "not_found",
    });
  });
});

// ---------------------------------------------------------------------------
// listUsers / getUser

describe("listUsers", () => {
  function usersPrisma(rows, { ads = [], leads = [] } = {}) {
    const findMany = vi.fn().mockResolvedValue(rows);
    const adGroupBy = vi.fn().mockResolvedValue(ads);
    const leadGroupBy = vi.fn().mockResolvedValue(leads);
    const prisma = createAdminPrisma({
      user: { findMany },
      ad: { groupBy: adGroupBy },
      lead: { groupBy: leadGroupBy },
    });
    return { prisma, findMany, adGroupBy, leadGroupBy };
  }

  // Two grouped queries for the whole page, never a pair per row — the
  // difference between 2 statements and 200 on a full page.
  it("counts a whole page with one grouped query per relation", async () => {
    const { prisma, adGroupBy, leadGroupBy } = usersPrisma(
      [makeUser({ id: USER_ID }), makeUser({ id: OTHER_ID }), makeUser({ id: THIRD_ID })],
      { ads: [{ agentId: OTHER_ID, _count: { _all: 5 } }] },
    );

    const { items } = await adminService.listUsers(ctxOf(prisma), {});

    expect(adGroupBy).toHaveBeenCalledTimes(1);
    expect(leadGroupBy).toHaveBeenCalledTimes(1);
    expect(adGroupBy.mock.calls[0][0].where).toEqual({ agentId: { in: [USER_ID, OTHER_ID, THIRD_ID] } });
    // A user with no row in the grouped result owns nothing, not "unknown".
    expect(items.map((u) => u.counts)).toEqual([
      { ads: 0, leads: 0 },
      { ads: 5, leads: 0 },
      { ads: 0, leads: 0 },
    ]);
  });

  it("drops an absent filter entirely instead of filtering on null", async () => {
    const { prisma, findMany } = usersPrisma([]);

    await adminService.listUsers(ctxOf(prisma), { q: "" });

    const { where } = findMany.mock.calls[0][0];
    expect(where.role).toBeUndefined();
    expect(where.realtorStatus).toBeUndefined();
    // An empty q is "no search", not a match-everything ILIKE.
    expect(where.OR).toBeUndefined();
  });

  it("keeps the full serializeUser shape and adds createdAt and counts", async () => {
    const { prisma } = usersPrisma([makeUser({ role: "COWORKER", agentId: OTHER_ID })]);

    const { items } = await adminService.listUsers(ctxOf(prisma), {});

    expect(items[0]).toMatchObject({
      id: USER_ID,
      role: "coworker",
      agentId: OTHER_ID,
      avatar: "https://cdn.test/avatar.jpg",
      address: "Amir Temur 1",
      igAccounts: [],
      createdAt: "2026-07-30T08:00:00.000Z",
      counts: { ads: 0, leads: 0 },
    });
  });
});

describe("getUser", () => {
  it("throws a 404 not_found rather than returning an empty user", async () => {
    const prisma = createAdminPrisma({ user: { findUnique: vi.fn().mockResolvedValue(null) } });

    await expect(adminService.getUser(ctxOf(prisma), USER_ID)).rejects.toMatchObject({
      status: 404,
      code: "not_found",
    });
  });
});

// ---------------------------------------------------------------------------
// setUserRole

describe("setUserRole", () => {
  function rolePrisma(existing, { admins = 1 } = {}) {
    const calls = [];
    const update = vi.fn(async ({ data }) => {
      calls.push("write");
      return { ...existing, ...data };
    });
    const prisma = createAdminPrisma({
      $queryRaw: vi.fn(async () => {
        calls.push("lock");
        return [];
      }),
      user: {
        findUnique: vi.fn(async () => existing),
        update,
        count: vi.fn().mockResolvedValue(admins),
      },
      ad: {
        groupBy: vi.fn(async () => {
          calls.push("count-ads");
          return [];
        }),
      },
      lead: { groupBy: vi.fn().mockResolvedValue([]) },
    });
    return { prisma, update, calls };
  }

  const setRole = (prisma, role, { userId = USER_ID, actorId = OTHER_ID } = {}) =>
    adminService.setUserRole(ctxOf(prisma), { userId, role, actorId });

  it("maps the wire key to the Postgres enum value and returns the updated row", async () => {
    const { prisma, update } = rolePrisma(makeUser({ role: "USER" }));

    const { user } = await setRole(prisma, "agent");

    expect(update).toHaveBeenCalledWith({ where: { id: USER_ID }, data: { role: "AGENT" } });
    expect(user.role).toBe("agent");
  });

  // The lock is wider than one row on purpose: two admins demoting each other
  // concurrently would each count the other as "one remaining admin" and both
  // succeed, leaving zero.
  it("locks before deciding, and counts owned records only after the write", async () => {
    const { prisma, calls } = rolePrisma(makeUser({ role: "USER" }));

    await setRole(prisma, "agent");

    expect(calls).toEqual(["lock", "write", "count-ads"]);
  });

  // Both rules fire on this input. self_demotion has to win: it is the more
  // specific explanation, and "promote another admin first" would be useless
  // advice to someone who is about to lock themselves out either way.
  it("reports self_demotion, not last_admin, when the actor is also the last admin", async () => {
    const { prisma, update } = rolePrisma(makeUser({ role: "ADMIN" }), { admins: 0 });

    await expect(setRole(prisma, "user", { actorId: USER_ID })).rejects.toMatchObject({
      status: 400,
      code: "self_demotion",
    });
    expect(update).not.toHaveBeenCalled();
  });

  it("blocks the last admin's demotion by anyone else", async () => {
    const { prisma, update } = rolePrisma(makeUser({ role: "ADMIN" }), { admins: 0 });

    await expect(setRole(prisma, "coworker")).rejects.toMatchObject({
      status: 409,
      code: "last_admin",
    });
    expect(update).not.toHaveBeenCalled();
  });

  it("refuses to make a coworker of an account no agent owns", async () => {
    const { prisma, update } = rolePrisma(makeUser({ role: "USER", agentId: null }));

    await expect(setRole(prisma, "coworker")).rejects.toMatchObject({
      status: 400,
      code: "coworker_needs_agent",
    });
    expect(update).not.toHaveBeenCalled();
  });

  // Nothing is cascaded: a demoted agent keeps every ad and lead it owned,
  // and `counts` is what makes that visible instead of the change looking free.
  it("demotes an agent that still owns records, and reports what it owns", async () => {
    const { prisma } = rolePrisma(makeUser({ role: "AGENT" }));
    prisma.ad.groupBy = vi.fn().mockResolvedValue([{ agentId: USER_ID, _count: { _all: 42 } }]);
    prisma.lead.groupBy = vi.fn().mockResolvedValue([{ agentId: USER_ID, _count: { _all: 7 } }]);

    const { user } = await setRole(prisma, "user");

    expect(user.role).toBe("user");
    expect(user.counts).toEqual({ ads: 42, leads: 7 });
  });

  // No early return for a no-op: the write is idempotent, and skipping it
  // would make updatedAt lie about when the row was last touched in that one
  // case only.
  it("still writes when the role is already what was asked for", async () => {
    const { prisma, update } = rolePrisma(makeUser({ role: "AGENT" }));

    await setRole(prisma, "agent");

    expect(update).toHaveBeenCalledWith({ where: { id: USER_ID }, data: { role: "AGENT" } });
  });

  it("throws a 404 not_found for an id no row matches", async () => {
    const { prisma } = rolePrisma(null);

    await expect(setRole(prisma, "agent")).rejects.toMatchObject({ status: 404, code: "not_found" });
  });
});

// ---------------------------------------------------------------------------
// listAudit

describe("listAudit", () => {
  const auditPrisma = (rows) => {
    const findMany = vi.fn().mockResolvedValue(rows);
    return { prisma: createAdminPrisma({ activityEvent: { findMany } }), findMany };
  };

  const event = (overrides = {}) => ({
    id: THIRD_ID,
    type: "AD_CREATED",
    createdAt: new Date("2026-08-12T10:30:00Z"),
    agent: { id: USER_ID, fullName: "Bekzod Agent" },
    coworker: null,
    ad: null,
    lead: null,
    meta: null,
    ...overrides,
  });

  // The service comment says this list must track schema.prisma's EventType.
  // Asserting it against the schema file is what makes that a fact rather than
  // an intention: a new event type added to Postgres and not to the map would
  // be unfilterable in the console and would fall back to a lowercased raw
  // value on the wire.
  it("knows exactly the event types schema.prisma declares", () => {
    const schema = readFileSync(new URL("../../prisma/schema.prisma", import.meta.url), "utf8");
    const body = schema.match(/enum EventType \{([^}]*)\}/)[1];
    const declared = body
      .split("\n")
      .map((line) => line.replace(/\/\/.*/, "").trim())
      .filter(Boolean);

    expect(Object.values(adminService.EVENT_TYPE).sort()).toEqual([...declared].sort());
    // Order matters too, not just membership: the route derives its ?type
    // enum from these keys, and the console renders the filter in that order.
    expect(Object.keys(adminService.EVENT_TYPE)).toEqual(declared.map((v) => v.toLowerCase()));
  });

  it("filters on the Postgres enum value the wire key names", async () => {
    const { prisma, findMany } = auditPrisma([]);

    await adminService.listAudit(ctxOf(prisma), { type: "ig_assist_aborted", agentId: USER_ID });

    expect(findMany.mock.calls[0][0].where).toEqual({ type: "IG_ASSIST_ABORTED", agentId: USER_ID });
  });

  it("asks for no filter at all when neither is supplied", async () => {
    const { prisma, findMany } = auditPrisma([]);

    await adminService.listAudit(ctxOf(prisma), {});

    expect(findMany.mock.calls[0][0].where).toEqual({ type: undefined, agentId: undefined });
  });

  it("nulls every relation the event does not carry", async () => {
    const { prisma } = auditPrisma([event({ agent: null })]);

    const { items } = await adminService.listAudit(ctxOf(prisma), {});

    expect(items[0]).toEqual({
      id: THIRD_ID,
      type: "ad_created",
      createdAt: "2026-08-12T10:30:00.000Z",
      agent: null,
      coworker: null,
      ad: null,
      lead: null,
      meta: null,
    });
  });

  it("keeps only the id and label of each relation, never the whole row", async () => {
    const { prisma } = auditPrisma([
      event({
        ad: { id: OTHER_ID, title: "Sunny flat", description: "long text", price: 120000 },
        lead: { id: THIRD_ID, fullName: "Jamshid Buyer", phone: "+998901234567" },
      }),
    ]);

    const { items } = await adminService.listAudit(ctxOf(prisma), {});

    expect(items[0].ad).toEqual({ id: OTHER_ID, title: "Sunny flat" });
    expect(items[0].lead).toEqual({ id: THIRD_ID, fullName: "Jamshid Buyer" });
  });
});
