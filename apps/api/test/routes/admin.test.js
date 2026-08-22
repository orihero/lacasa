import { describe, expect, it, vi } from "vitest";
import supertest from "supertest";
import { buildTestApp, createFakePrisma } from "../helpers/testApp.js";
import { signToken } from "../../src/lib/jwt.js";
import adminRouter from "../../src/routes/admin.js";

// Unit-level route tests: supertest against createApp() with a hand-rolled
// ctx.prisma, no vi.mock() and no database. Unlike the *.integration.test.js
// files next to this one, /api/admin has no fixture path through the public
// API at all — there is no endpoint that creates an ADMIN (that is
// scripts/promote-admin.mjs's job by design), so the fake-ctx seam is the
// only place the whole eight-endpoint surface can be driven end to end.
//
// The token is minted with the real signToken, so requireAuth verifies a
// genuinely-signed JWT rather than a stubbed one: the role gate is the single
// most important thing in this file and it must be exercised through the same
// code path a real client hits.

const ADMIN_ID = "aaaaaaaa-0000-4000-8000-000000000001";
const TARGET_ID = "bbbbbbbb-0000-4000-8000-000000000002";
const OTHER_ID = "cccccccc-0000-4000-8000-000000000003";
const NEXT_ID = "dddddddd-0000-4000-8000-000000000004";

const authHeader = (role, sub = ADMIN_ID) => `Bearer ${signToken({ sub, role })}`;
const asAdmin = (req, sub = ADMIN_ID) => req.set("Authorization", authHeader("ADMIN", sub));

// createFakePrisma's own $transaction hands the callback its *base* object —
// the one carrying nothing but $queryRaw/$transaction — so `tx.user` inside
// the callback would be undefined. Both admin writes (decideApplication,
// setUserRole) run inside an interactive transaction and call model methods on
// the `tx` they are handed, which for real Prisma exposes the identical model
// surface as the root client. This override reproduces that: the callback gets
// the same fully-stubbed client back.
//
// It also answers ONE findUnique that no handler in this router asks for: the
// router's gate is `requireAuth, requireRole, loadCurrentUser,
// requireCurrentRole`, so every request first re-reads the *acting* admin's
// own row to confirm they are still an ADMIN in Postgres and not merely in a
// week-old token. Serving that lookup here, keyed on the actor id, is what
// lets each test below go on stubbing only the row its own handler reads.
function createAdminPrisma(overrides = {}) {
  const stubbedFindUnique = overrides.user?.findUnique;
  const prisma = createFakePrisma({
    ...overrides,
    user: {
      ...overrides.user,
      findUnique: vi.fn(async (args) => {
        if (args?.where?.id === ADMIN_ID) return makeUser({ id: ADMIN_ID, role: "ADMIN" });
        if (!stubbedFindUnique) {
          throw new Error("fake prisma: no stub for user.findUnique() — pass it in overrides");
        }
        return stubbedFindUnique(args);
      }),
    },
    $transaction: (arg) => (Array.isArray(arg) ? Promise.all(arg) : arg(prisma)),
  });
  return prisma;
}

// A full Prisma User row, passwordHash included — that column is on every row
// the admin repository reads (findUnique/findMany take no `select`), so the
// fixture carries it and the leak suite at the bottom of this file proves the
// serializer drops it rather than the query never having fetched it.
function makeUser(overrides = {}) {
  return {
    id: TARGET_ID,
    fullName: "Dilnoza Karimova",
    email: "dilnoza@example.test",
    passwordHash: "$2a$10$notarealbcrypthashbutshapedlikeone",
    role: "USER",
    phoneNumber: "+998901112233",
    avatarUrl: null,
    address: null,
    tgChatIds: [],
    realtorKind: "SOLO",
    realtorStatus: "PENDING",
    agencyName: null,
    officePhone: null,
    teamSize: null,
    realtorAppliedAt: new Date("2026-08-01T09:00:00Z"),
    realtorDecidedAt: null,
    agentId: null,
    igAssistConsentAt: null,
    createdAt: new Date("2026-07-30T08:00:00Z"),
    updatedAt: new Date("2026-08-01T09:00:00Z"),
    ...overrides,
  };
}

// Stubs the read/lock/write trio both write paths share. `update` returns the
// merged row rather than a canned one so the response reflects the data the
// service actually asked to be written — a service that wrote the wrong role
// would otherwise still answer with a fixture that looks correct.
function decisionPrisma(existing, extra = {}) {
  const update = vi.fn(async ({ data }) => ({ ...existing, ...data }));
  const findUnique = vi.fn().mockResolvedValue(existing);
  const queryRaw = vi.fn().mockResolvedValue([{ id: existing?.id }]);
  const prisma = createAdminPrisma({
    $queryRaw: queryRaw,
    user: { findUnique, update, count: vi.fn().mockResolvedValue(1), ...(extra.user ?? {}) },
    ad: { groupBy: vi.fn().mockResolvedValue([]) },
    lead: { groupBy: vi.fn().mockResolvedValue([]) },
    ...extra.root,
  });
  return { prisma, findUnique, update, queryRaw };
}

// ---------------------------------------------------------------------------
// Authorization

// Every route the admin router declares. The gate below iterates this list
// instead of spot-checking two or three endpoints: requireRole is applied
// once via router.use, so a handler mounted *above* that line — or moved to
// another router later — would be wide open with every other endpoint's test
// still green. A single unguarded admin handler is privilege escalation, so
// the coverage here has to be total, and the first test below is what keeps
// it total as the router grows.
//
// Each entry is written once, as "<METHOD> <router path>", and the request
// URL is *derived* from it — never written a second time. A hand-written URL
// could silently disagree with its name, and a 403 would not expose that:
// requireRole is a router.use, so it also answers 403 for a path this router
// declares no route for. A typo'd URL would sail through the sweep below
// while testing nothing.
const ROUTE_PARAM_VALUES = { ":userId": TARGET_ID, ":id": TARGET_ID };

const ENDPOINTS = [
  "GET /overview",
  "GET /applications",
  "POST /applications/:userId/approve",
  "POST /applications/:userId/reject",
  "GET /users",
  "GET /users/:id",
  "PATCH /users/:id/role",
  "GET /audit",
].map((name) => {
  const [method, routePath] = name.split(" ");
  return {
    name,
    method: method.toLowerCase(),
    path: `/api/admin${routePath.replace(/:\w+/g, (param) => ROUTE_PARAM_VALUES[param])}`,
  };
});

// Every model method any of the eight handlers reaches for, stubbed with an
// empty-but-valid answer. Used only by the "an ADMIN is never refused" test,
// which needs all eight to get *past* the gate without the un-stubbed proxy
// turning each one into a 500 that the assertion could not tell apart from a
// genuine refusal.
const fullyStubbedPrisma = () =>
  createAdminPrisma({
    $queryRaw: vi.fn().mockResolvedValue([]),
    user: {
      findUnique: vi.fn().mockResolvedValue(makeUser()),
      findMany: vi.fn().mockResolvedValue([]),
      groupBy: vi.fn().mockResolvedValue([]),
      update: vi.fn(async ({ data }) => ({ ...makeUser(), ...data })),
      count: vi.fn().mockResolvedValue(2),
    },
    ad: { groupBy: vi.fn().mockResolvedValue([]) },
    lead: { groupBy: vi.fn().mockResolvedValue([]) },
    adPublication: { groupBy: vi.fn().mockResolvedValue([]) },
    activityEvent: { findMany: vi.fn().mockResolvedValue([]) },
  });

describe("the /api/admin role gate", () => {
  // Read off the router itself rather than trusted to a hand-maintained list:
  // adding a ninth endpoint without adding it to ENDPOINTS fails here, which
  // is the only way the exhaustive 401/403 sweep below can stay exhaustive.
  it("covers every route the admin router declares", () => {
    const declared = adminRouter.stack
      .filter((layer) => layer.route)
      .map((layer) => `${Object.keys(layer.route.methods)[0].toUpperCase()} ${layer.route.path}`);

    expect(declared.sort()).toEqual(ENDPOINTS.map(({ name }) => name).sort());
    expect(declared).toHaveLength(8);
  });

  // The other half of the guard above: proves each derived URL actually
  // reaches its handler, so the 403 sweep is refusing a real endpoint rather
  // than an unmatched path. 400 counts as reaching it — PATCH .../role is
  // sent with no body here and validation is the handler's own answer.
  it.each(ENDPOINTS)("routes $name to a handler for an ADMIN", async ({ method, path }) => {
    const res = await asAdmin(supertest(buildTestApp({ prisma: fullyStubbedPrisma() }))[method](path));

    expect([200, 400]).toContain(res.status);
  });

  it.each(ENDPOINTS)("401s $name with no token at all", async ({ method, path }) => {
    const app = buildTestApp();
    const res = await supertest(app)[method](path);

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("unauthorized");
  });

  it.each(ENDPOINTS)("401s $name with a token this server did not sign", async ({ method, path }) => {
    const app = buildTestApp();
    const forged = "eyJhbGciOiJIUzI1NiJ9.eyJzdWIiOiJ4Iiwicm9sZSI6IkFETUlOIn0.not-a-real-signature";
    const res = await supertest(app)[method](path).set("Authorization", `Bearer ${forged}`);

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("unauthorized");
  });

  // The three roles that exist alongside ADMIN. A buyer is the obvious
  // attacker, but AGENT and COWORKER matter more: they are the roles that
  // legitimately hold a token for the rest of the API, so they are the ones
  // that would actually be pointed at /api/admin by accident or on purpose.
  for (const role of ["USER", "AGENT", "COWORKER"]) {
    it.each(ENDPOINTS)(`403s $name for a ${role} token`, async ({ method, path }) => {
      // No prisma stubs on purpose: every model method rejects, so a handler
      // that slipped past the gate cannot accidentally satisfy this
      // assertion. Verified by removing the gate and re-running — all eight
      // then answer 500 (400 for the role PATCH, which validates its empty
      // body before touching Prisma), and every case here fails.
      const app = buildTestApp({ prisma: createFakePrisma() });
      const res = await supertest(app)[method](path).set("Authorization", authHeader(role));

      expect(res.status).toBe(403);
      expect(res.body.error.code).toBe("forbidden");
    });
  }

  // The other half of the gate, and the half a JWT alone cannot enforce. The
  // `role` in a token is frozen at sign-in for JWT_EXPIRES_IN (7 days), so
  // "remove this person's admin rights" would otherwise do nothing for a week
  // — and the demoted holder's very first move could be PATCH /users/:id/role
  // on their own row, putting ADMIN back and making the revocation
  // permanently undoable. Swept across all eight endpoints for the same
  // reason the 403 sweep above is: one handler mounted above the gate is the
  // whole hole.
  it.each(ENDPOINTS)("403s $name once the database no longer backs the token's ADMIN claim", async ({ method, path }) => {
    // No other stubs: a handler that ran anyway would hit the rejecting proxy
    // and answer 500, which this assertion would catch rather than mistake
    // for a refusal.
    const prisma = createFakePrisma({
      user: { findUnique: vi.fn().mockResolvedValue(makeUser({ id: ADMIN_ID, role: "USER" })) },
    });

    const res = await asAdmin(supertest(buildTestApp({ prisma }))[method](path));

    expect(res.status).toBe(403);
    expect(res.body.error.code).toBe("forbidden");
  });

  // Deletion is the other thing a still-valid token cannot know about, and
  // loadCurrentUser's own answer for it — 401, not 403: there is no account
  // behind this token at all, so "wrong role" would be the wrong story.
  it("401s once the acting admin's account no longer exists", async () => {
    const prisma = createFakePrisma({ user: { findUnique: vi.fn().mockResolvedValue(null) } });

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/users"));

    expect(res.status).toBe(401);
    expect(res.body.error.code).toBe("unauthorized");
  });

  it("lets an ADMIN token through to the handler", async () => {
    const { prisma } = decisionPrisma(makeUser());
    const res = await asAdmin(supertest(buildTestApp({ prisma })).get(`/api/admin/users/${TARGET_ID}`));

    expect(res.status).toBe(200);
  });
});

// ---------------------------------------------------------------------------
// GET /api/admin/overview

describe("GET /api/admin/overview", () => {
  // The six aggregates overviewAggregates batches, in the order it batches
  // them. user.groupBy is called twice with different `by` clauses, so the
  // stub switches on the clause rather than on call order.
  function overviewPrisma({ roles, applications, ads, leads, publications, signups }) {
    return createAdminPrisma({
      user: {
        groupBy: vi.fn(async ({ by }) => (by[0] === "role" ? roles : applications)),
        findMany: vi.fn().mockResolvedValue(signups),
      },
      ad: { groupBy: vi.fn().mockResolvedValue(ads) },
      lead: { groupBy: vi.fn().mockResolvedValue(leads) },
      adPublication: { groupBy: vi.fn().mockResolvedValue(publications) },
    });
  }

  const grouped = (field, entries) =>
    entries.map(([value, n]) => ({ [field]: value, _count: { _all: n } }));

  it("returns the documented shape, with every total summed from its own groups", async () => {
    const prisma = overviewPrisma({
      roles: grouped("role", [
        ["USER", 40],
        ["AGENT", 7],
        ["COWORKER", 2],
        ["ADMIN", 1],
      ]),
      applications: grouped("realtorStatus", [
        ["NONE", 40],
        ["PENDING", 3],
        ["APPROVED", 6],
        ["REJECTED", 1],
      ]),
      ads: grouped("stage", [
        ["ACTIVE", 12],
        ["SOLD", 4],
        ["DRAFT", 2],
      ]),
      leads: grouped("status", [
        ["NEW", 5],
        ["ACCEPTED", 3],
      ]),
      publications: grouped("status", [
        ["PUBLISHED", 9],
        ["FAILED", 1],
        ["DRAFTED_AWAITING_REVIEW", 2],
      ]),
      signups: [makeUser({ id: OTHER_ID, role: "AGENT", createdAt: new Date("2026-08-10T12:00:00Z") })],
    });

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/overview"));

    expect(res.status).toBe(200);
    expect(res.body).toEqual({
      users: { total: 50, buyers: 40, agents: 7, coworkers: 2, admins: 1 },
      // NONE is not a bucket here: 40 buyers who never applied are not 40
      // applications, and the contract's three keys are the only three.
      applications: { pending: 3, approved: 6, rejected: 1 },
      ads: { total: 18, active: 12, sold: 4, draft: 2 },
      leads: {
        total: 8,
        byStatus: {
          new: 5,
          could_not_connect: 0,
          need_to_call_back: 0,
          rejected: 0,
          accepted: 3,
        },
      },
      // `pending` had no rows at all and must still report 0 rather than be
      // missing — a groupBy cannot emit a zero-count group.
      publications: { published: 9, failed: 1, pending: 0, drafted_awaiting_review: 2 },
      recentSignups: [
        {
          id: OTHER_ID,
          fullName: "Dilnoza Karimova",
          email: "dilnoza@example.test",
          role: "agent",
          createdAt: "2026-08-10T12:00:00.000Z",
        },
      ],
    });
  });

  it("reports zeros rather than gaps on an empty platform", async () => {
    const prisma = overviewPrisma({
      roles: [],
      applications: [],
      ads: [],
      leads: [],
      publications: [],
      signups: [],
    });

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/overview"));

    expect(res.status).toBe(200);
    expect(res.body.users).toEqual({ total: 0, buyers: 0, agents: 0, coworkers: 0, admins: 0 });
    expect(res.body.applications).toEqual({ pending: 0, approved: 0, rejected: 0 });
    expect(res.body.ads).toEqual({ total: 0, active: 0, sold: 0, draft: 0 });
    expect(res.body.leads.total).toBe(0);
    expect(Object.values(res.body.leads.byStatus)).toEqual([0, 0, 0, 0, 0]);
    expect(res.body.publications).toEqual({
      published: 0,
      failed: 0,
      pending: 0,
      drafted_awaiting_review: 0,
    });
    expect(res.body.recentSignups).toEqual([]);
  });
});

// ---------------------------------------------------------------------------
// GET /api/admin/applications

describe("GET /api/admin/applications", () => {
  const applicationsPrisma = (rows) => {
    const findMany = vi.fn().mockResolvedValue(rows);
    return { prisma: createAdminPrisma({ user: { findMany } }), findMany };
  };

  it("defaults to the pending queue and pages 25 at a time", async () => {
    const { prisma, findMany } = applicationsPrisma([makeUser()]);

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/applications"));

    expect(res.status).toBe(200);
    expect(findMany).toHaveBeenCalledWith({
      where: { realtorStatus: "PENDING" },
      orderBy: [{ createdAt: "desc" }, { id: "desc" }],
      take: 26,
    });
    expect(res.body.items[0]).toEqual({
      id: TARGET_ID,
      fullName: "Dilnoza Karimova",
      email: "dilnoza@example.test",
      phoneNumber: "+998901112233",
      realtor: {
        kind: "solo",
        status: "pending",
        agencyName: null,
        officePhone: null,
        teamSize: null,
        appliedAt: "2026-08-01T09:00:00.000Z",
        decidedAt: null,
      },
      createdAt: "2026-07-30T08:00:00.000Z",
    });
    expect(res.body.nextCursor).toBeNull();
  });

  it.each([
    ["approved", "APPROVED"],
    ["rejected", "REJECTED"],
  ])("maps the ?status=%s wire key to its Postgres value", async (key, value) => {
    const { prisma, findMany } = applicationsPrisma([]);

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).get(`/api/admin/applications?status=${key}`),
    );

    expect(res.status).toBe(200);
    expect(findMany.mock.calls[0][0].where).toEqual({ realtorStatus: value });
  });

  // `none` means "never applied", which is every buyer on the platform —
  // accepting it would offer a filter whose only honest answer is a list
  // nobody asked to review.
  it.each(["none", "PENDING", "anything"])("rejects ?status=%s", async (status) => {
    const { prisma } = applicationsPrisma([]);

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).get(`/api/admin/applications?status=${status}`),
    );

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });
});

// ---------------------------------------------------------------------------
// Pagination, which every list endpoint shares

describe("keyset pagination", () => {
  const rowsPrisma = (rows) => {
    const findMany = vi.fn().mockResolvedValue(rows);
    return { prisma: createAdminPrisma({ user: { findMany } }), findMany };
  };

  it("hands back the last row of the page as nextCursor when more rows exist", async () => {
    // take+1 rows come back from the repository — the extra one is how the
    // service knows there is another page without a second COUNT(*).
    const { prisma, findMany } = rowsPrisma([
      makeUser({ id: TARGET_ID }),
      makeUser({ id: NEXT_ID }),
      makeUser({ id: OTHER_ID }),
    ]);

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/applications?limit=2"));

    expect(findMany.mock.calls[0][0].take).toBe(3);
    expect(res.body.items.map((i) => i.id)).toEqual([TARGET_ID, NEXT_ID]);
    expect(res.body.nextCursor).toBe(NEXT_ID);
  });

  it("passes that cursor straight back to Prisma, skipping the row it names", async () => {
    const { prisma, findMany } = rowsPrisma([makeUser({ id: OTHER_ID })]);

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).get(`/api/admin/applications?limit=2&cursor=${NEXT_ID}`),
    );

    expect(res.status).toBe(200);
    expect(findMany.mock.calls[0][0]).toMatchObject({ cursor: { id: NEXT_ID }, skip: 1, take: 3 });
    // Fewer rows than take+1 came back, so this was the last page.
    expect(res.body.nextCursor).toBeNull();
  });

  it("returns nextCursor null when the page is exactly full but nothing follows", async () => {
    const { prisma } = rowsPrisma([makeUser({ id: TARGET_ID }), makeUser({ id: NEXT_ID })]);

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/applications?limit=2"));

    expect(res.body.items).toHaveLength(2);
    expect(res.body.nextCursor).toBeNull();
  });

  it("refuses a cursor that is not one of this API's ids", async () => {
    const { prisma } = rowsPrisma([]);

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).get("/api/admin/applications?cursor=page-2"),
    );

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });

  // An explicit "too big" beats silently serving 100 rows to a caller that
  // asked for 500 and will page as if it got them.
  it.each([101, 500, 0, -5])("refuses limit=%s rather than quietly clamping it", async (limit) => {
    const { prisma } = rowsPrisma([]);

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).get(`/api/admin/applications?limit=${limit}`),
    );

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });

  it("accepts the ceiling itself", async () => {
    const { prisma, findMany } = rowsPrisma([]);

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).get("/api/admin/applications?limit=100"),
    );

    expect(res.status).toBe(200);
    expect(findMany.mock.calls[0][0].take).toBe(101);
  });

  // Applied by the same shared schema on all four lists, so a copy of the
  // page params that forgot the ceiling would show up here.
  it.each([
    ["/api/admin/users", { user: { findMany: vi.fn().mockResolvedValue([]) } }],
    ["/api/admin/audit", { activityEvent: { findMany: vi.fn().mockResolvedValue([]) } }],
  ])("applies the same limit ceiling to %s", async (path, stubs) => {
    const prisma = createAdminPrisma(stubs);

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get(`${path}?limit=101`));

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });
});

// ---------------------------------------------------------------------------
// POST /api/admin/applications/:userId/approve

describe("POST /api/admin/applications/:userId/approve", () => {
  it("approves and promotes a pending buyer to AGENT", async () => {
    const { prisma, update, queryRaw } = decisionPrisma(makeUser({ role: "USER" }));

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).post(`/api/admin/applications/${TARGET_ID}/approve`),
    );

    expect(res.status).toBe(200);
    expect(update).toHaveBeenCalledTimes(1);
    const { data } = update.mock.calls[0][0];
    expect(data.role).toBe("AGENT");
    expect(data.realtorStatus).toBe("APPROVED");
    expect(data.realtorDecidedAt).toBeInstanceOf(Date);

    expect(res.body.user.role).toBe("agent");
    expect(res.body.user.realtor.status).toBe("approved");
    expect(res.body.user.realtor.decidedAt).toEqual(expect.any(String));

    // The row lock is what makes the PENDING check mean anything under READ
    // COMMITTED; without it two admins can both decide the same application.
    expect(queryRaw).toHaveBeenCalled();
  });

  // Approving decides the *application*. Writing AGENT over a COWORKER strips
  // its agency scope and over an ADMIN quietly demotes it out of the control
  // room, so the promotion is strictly USER -> AGENT and nothing else.
  it.each(["AGENT", "COWORKER", "ADMIN"])("approves without touching a %s's role", async (role) => {
    const { prisma, update } = decisionPrisma(makeUser({ role, agentId: role === "COWORKER" ? OTHER_ID : null }));

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).post(`/api/admin/applications/${TARGET_ID}/approve`),
    );

    expect(res.status).toBe(200);
    expect(update.mock.calls[0][0].data).not.toHaveProperty("role");
    expect(res.body.user.role).toBe(role.toLowerCase());
  });

  it.each(["APPROVED", "REJECTED", "NONE"])(
    "409s not_pending on an application already at %s, writing nothing",
    async (realtorStatus) => {
      const { prisma, update } = decisionPrisma(makeUser({ realtorStatus }));

      const res = await asAdmin(
        supertest(buildTestApp({ prisma })).post(`/api/admin/applications/${TARGET_ID}/approve`),
      );

      expect(res.status).toBe(409);
      expect(res.body.error.code).toBe("not_pending");
      expect(update).not.toHaveBeenCalled();
    },
  );

  it("404s a well-formed id that matches no account", async () => {
    const { prisma, update } = decisionPrisma(null);

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).post(`/api/admin/applications/${TARGET_ID}/approve`),
    );

    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe("not_found");
    expect(update).not.toHaveBeenCalled();
  });

  // 400, not 404: every id column is @db.Uuid, so the server cannot look this
  // up to say whether it exists — it can only say the id is not an id.
  it("400s a malformed id instead of letting Postgres raise a 22P02", async () => {
    const { prisma } = decisionPrisma(makeUser());

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).post("/api/admin/applications/not-a-uuid/approve"),
    );

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });
});

// ---------------------------------------------------------------------------
// POST /api/admin/applications/:userId/reject

describe("POST /api/admin/applications/:userId/reject", () => {
  // A rejected applicant is still a buyer. Demoting them here would be a
  // second decision nobody asked for.
  it("records the rejection and leaves the account's role alone", async () => {
    const { prisma, update } = decisionPrisma(makeUser({ role: "USER" }));

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).post(`/api/admin/applications/${TARGET_ID}/reject`),
    );

    expect(res.status).toBe(200);
    const { data } = update.mock.calls[0][0];
    expect(data).not.toHaveProperty("role");
    expect(data.realtorStatus).toBe("REJECTED");
    expect(data.realtorDecidedAt).toBeInstanceOf(Date);
    expect(res.body.user.role).toBe("user");
    expect(res.body.user.realtor.status).toBe("rejected");
  });

  it("does not demote an agent whose second application is rejected", async () => {
    const { prisma, update } = decisionPrisma(makeUser({ role: "AGENT" }));

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).post(`/api/admin/applications/${TARGET_ID}/reject`),
    );

    expect(res.status).toBe(200);
    expect(update.mock.calls[0][0].data).not.toHaveProperty("role");
    expect(res.body.user.role).toBe("agent");
  });

  it.each(["APPROVED", "REJECTED", "NONE"])("409s not_pending on a %s application", async (realtorStatus) => {
    const { prisma, update } = decisionPrisma(makeUser({ realtorStatus }));

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).post(`/api/admin/applications/${TARGET_ID}/reject`),
    );

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe("not_pending");
    expect(update).not.toHaveBeenCalled();
  });
});

// ---------------------------------------------------------------------------
// GET /api/admin/users and GET /api/admin/users/:id

describe("GET /api/admin/users", () => {
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

  it("returns the serializeUser shape plus createdAt and owned-record counts", async () => {
    const { prisma } = usersPrisma([makeUser({ role: "AGENT" })], {
      ads: [{ agentId: TARGET_ID, _count: { _all: 42 } }],
      leads: [{ agentId: TARGET_ID, _count: { _all: 7 } }],
    });

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/users"));

    expect(res.status).toBe(200);
    expect(res.body.items[0]).toMatchObject({
      id: TARGET_ID,
      role: "agent",
      createdAt: "2026-07-30T08:00:00.000Z",
      counts: { ads: 42, leads: 7 },
    });
  });

  it("reports zero for an account that owns nothing, rather than omitting counts", async () => {
    const { prisma } = usersPrisma([makeUser()]);

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/users"));

    expect(res.body.items[0].counts).toEqual({ ads: 0, leads: 0 });
  });

  it("maps the role and realtorStatus wire keys to their Postgres values", async () => {
    const { prisma, findMany } = usersPrisma([]);

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).get("/api/admin/users?role=coworker&realtorStatus=approved"),
    );

    expect(res.status).toBe(200);
    expect(findMany.mock.calls[0][0].where).toMatchObject({
      role: "COWORKER",
      realtorStatus: "APPROVED",
    });
  });

  it("searches fullName or email case-insensitively", async () => {
    const { prisma, findMany } = usersPrisma([]);

    await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/users?q=dilnoza"));

    expect(findMany.mock.calls[0][0].where.OR).toEqual([
      { fullName: { contains: "dilnoza", mode: "insensitive" } },
      { email: { contains: "dilnoza", mode: "insensitive" } },
    ]);
  });

  it.each([
    ["role=administrator", "role"],
    ["realtorStatus=maybe", "realtorStatus"],
  ])("rejects an unknown %s filter value", async (query) => {
    const { prisma } = usersPrisma([]);

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get(`/api/admin/users?${query}`));

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });

  // An `in: []` query is a round trip whose answer is already known.
  it("does not go counting anything for an empty page", async () => {
    const { prisma, adGroupBy, leadGroupBy } = usersPrisma([]);

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/users"));

    expect(res.body.items).toEqual([]);
    expect(adGroupBy).not.toHaveBeenCalled();
    expect(leadGroupBy).not.toHaveBeenCalled();
  });
});

describe("GET /api/admin/users/:id", () => {
  it("returns one account with its counts", async () => {
    const { prisma } = decisionPrisma(makeUser({ role: "AGENT" }));

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get(`/api/admin/users/${TARGET_ID}`));

    expect(res.status).toBe(200);
    expect(res.body.user.id).toBe(TARGET_ID);
    expect(res.body.user.counts).toEqual({ ads: 0, leads: 0 });
  });

  it("404s an id that matches no account", async () => {
    const { prisma } = decisionPrisma(null);

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get(`/api/admin/users/${TARGET_ID}`));

    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe("not_found");
  });

  it("400s a malformed id", async () => {
    const { prisma } = decisionPrisma(makeUser());

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/users/nope"));

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });
});

// ---------------------------------------------------------------------------
// PATCH /api/admin/users/:id/role

describe("PATCH /api/admin/users/:id/role", () => {
  const patchRole = (prisma, role, { id = TARGET_ID, actor = ADMIN_ID } = {}) =>
    asAdmin(supertest(buildTestApp({ prisma })).patch(`/api/admin/users/${id}/role`), actor).send({ role });

  it("changes a role and answers with the updated account and its counts", async () => {
    const { prisma, update } = decisionPrisma(makeUser({ role: "USER" }));

    const res = await patchRole(prisma, "agent");

    expect(res.status).toBe(200);
    expect(update).toHaveBeenCalledWith({ where: { id: TARGET_ID }, data: { role: "AGENT" } });
    expect(res.body.user.role).toBe("agent");
    expect(res.body.user.counts).toEqual({ ads: 0, leads: 0 });
  });

  // Almost always a misclick, and the one mistake an admin cannot undo
  // themselves afterwards — so it is refused even when other admins exist.
  it("400s self_demotion when an admin removes their own admin role", async () => {
    const { prisma, update } = decisionPrisma(makeUser({ id: ADMIN_ID, role: "ADMIN" }));

    const res = await patchRole(prisma, "agent", { id: ADMIN_ID });

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("self_demotion");
    expect(update).not.toHaveBeenCalled();
  });

  it("lets an admin re-apply their own admin role — it demotes nobody", async () => {
    const { prisma, update } = decisionPrisma(makeUser({ id: ADMIN_ID, role: "ADMIN" }));

    const res = await patchRole(prisma, "admin", { id: ADMIN_ID });

    expect(res.status).toBe(200);
    expect(update).toHaveBeenCalledWith({ where: { id: ADMIN_ID }, data: { role: "ADMIN" } });
  });

  it("409s last_admin when demoting the only remaining admin", async () => {
    const { prisma, update } = decisionPrisma(makeUser({ role: "ADMIN" }), {
      user: { count: vi.fn().mockResolvedValue(0) },
    });

    const res = await patchRole(prisma, "user");

    expect(res.status).toBe(409);
    expect(res.body.error.code).toBe("last_admin");
    expect(update).not.toHaveBeenCalled();
  });

  it("allows demoting an admin while another one remains", async () => {
    const count = vi.fn().mockResolvedValue(1);
    const { prisma, update } = decisionPrisma(makeUser({ role: "ADMIN" }), { user: { count } });

    const res = await patchRole(prisma, "user");

    expect(res.status).toBe(200);
    expect(count).toHaveBeenCalledWith({ where: { role: "ADMIN", id: { not: TARGET_ID } } });
    expect(update).toHaveBeenCalledWith({ where: { id: TARGET_ID }, data: { role: "USER" } });
  });

  // A COWORKER's every scoped read resolves through effectiveAgentId(), which
  // returns user.agentId — one with no agent would reach the Work tab and see
  // nothing, with no admin endpoint able to fix it.
  it("400s coworker_needs_agent for an account no agent owns", async () => {
    const { prisma, update } = decisionPrisma(makeUser({ role: "USER", agentId: null }));

    const res = await patchRole(prisma, "coworker");

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("coworker_needs_agent");
    expect(update).not.toHaveBeenCalled();
  });

  it("allows coworker when the account already has an owning agent", async () => {
    const { prisma, update } = decisionPrisma(makeUser({ role: "USER", agentId: OTHER_ID }));

    const res = await patchRole(prisma, "coworker");

    expect(res.status).toBe(200);
    expect(update).toHaveBeenCalledWith({ where: { id: TARGET_ID }, data: { role: "COWORKER" } });
  });

  it.each(["superadmin", "ADMIN", "", null])("400s validation on role=%s", async (role) => {
    const { prisma, update } = decisionPrisma(makeUser());

    const res = await patchRole(prisma, role);

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
    expect(update).not.toHaveBeenCalled();
  });

  it("400s validation on a body with no role at all", async () => {
    const { prisma } = decisionPrisma(makeUser());

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).patch(`/api/admin/users/${TARGET_ID}/role`),
    ).send({});

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });

  it("404s an id that matches no account", async () => {
    const { prisma } = decisionPrisma(null);

    const res = await patchRole(prisma, "agent");

    expect(res.status).toBe(404);
    expect(res.body.error.code).toBe("not_found");
  });
});

// ---------------------------------------------------------------------------
// GET /api/admin/audit

describe("GET /api/admin/audit", () => {
  const auditEvent = (overrides = {}) => ({
    id: NEXT_ID,
    type: "OLX_CROSSPOST_COMPLETED",
    createdAt: new Date("2026-08-12T10:30:00Z"),
    agent: { id: OTHER_ID, fullName: "Bekzod Agent" },
    coworker: null,
    ad: { id: TARGET_ID, title: "Sunny flat" },
    lead: null,
    meta: { channel: "olx" },
    ...overrides,
  });

  const auditPrisma = (rows) => {
    const findMany = vi.fn().mockResolvedValue(rows);
    return { prisma: createAdminPrisma({ activityEvent: { findMany } }), findMany };
  };

  it("lowercases the event type and carries only the relation fields the table renders", async () => {
    const { prisma } = auditPrisma([auditEvent()]);

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/audit"));

    expect(res.status).toBe(200);
    expect(res.body.items[0]).toEqual({
      id: NEXT_ID,
      type: "olx_crosspost_completed",
      createdAt: "2026-08-12T10:30:00.000Z",
      agent: { id: OTHER_ID, fullName: "Bekzod Agent" },
      coworker: null,
      ad: { id: TARGET_ID, title: "Sunny flat" },
      lead: null,
      meta: { channel: "olx" },
    });
  });

  // Both relations are onDelete: SetNull, so an event whose ad was deleted
  // stays in the trail with a null subject instead of vanishing from it.
  it("keeps an event whose ad and lead are both gone", async () => {
    const { prisma } = auditPrisma([auditEvent({ ad: null, lead: null, meta: null })]);

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/audit"));

    expect(res.body.items[0].ad).toBeNull();
    expect(res.body.items[0].lead).toBeNull();
    expect(res.body.items[0].meta).toBeNull();
  });

  it("maps the type filter's wire key back to the Postgres enum value", async () => {
    const { prisma, findMany } = auditPrisma([]);

    const res = await asAdmin(
      supertest(buildTestApp({ prisma })).get(`/api/admin/audit?type=lead_created&agentId=${OTHER_ID}`),
    );

    expect(res.status).toBe(200);
    expect(findMany.mock.calls[0][0].where).toEqual({ type: "LEAD_CREATED", agentId: OTHER_ID });
  });

  it.each(["LEAD_CREATED", "lead_deleted"])("rejects ?type=%s", async (type) => {
    const { prisma } = auditPrisma([]);

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get(`/api/admin/audit?type=${type}`));

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });

  it("rejects an agentId that is not an id", async () => {
    const { prisma } = auditPrisma([]);

    const res = await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/audit?agentId=bekzod"));

    expect(res.status).toBe(400);
    expect(res.body.error.code).toBe("validation");
  });
});

// ---------------------------------------------------------------------------
// What no admin response may ever carry

// The repository reads user rows with no `select`, so passwordHash is on
// every row that reaches the service — these endpoints are safe because
// serializeUser whitelists, and that is a property worth pinning rather than
// assuming. The IG access token is the second half of the same rule: it lives
// on AgentIgToken and is deliberately never sent to any client (migration
// plan E.2), so an `include: { igTokens: true }` added to the admin
// repository for a "connected accounts" column must not reach the wire.
describe("secrets no admin response may carry", () => {
  const SECRET_HASH = "$2a$10$notarealbcrypthashbutshapedlikeone";
  const IG_TOKEN = "IGQVJXsecret-long-lived-token";

  const leakyRow = (overrides = {}) =>
    makeUser({
      igTokens: [{ id: OTHER_ID, accessToken: IG_TOKEN, igUserId: "17841400000000000" }],
      ...overrides,
    });

  const assertClean = (res) => {
    const body = JSON.stringify(res.body);
    expect(res.status).toBeLessThan(400);
    expect(body).not.toContain("passwordHash");
    expect(body).not.toContain(SECRET_HASH);
    expect(body).not.toContain("accessToken");
    expect(body).not.toContain(IG_TOKEN);
  };

  it("keeps them out of the users list", async () => {
    const prisma = createAdminPrisma({
      user: { findMany: vi.fn().mockResolvedValue([leakyRow()]) },
      ad: { groupBy: vi.fn().mockResolvedValue([]) },
      lead: { groupBy: vi.fn().mockResolvedValue([]) },
    });

    assertClean(await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/users")));
  });

  it("keeps them out of a single user", async () => {
    const { prisma } = decisionPrisma(leakyRow());

    assertClean(await asAdmin(supertest(buildTestApp({ prisma })).get(`/api/admin/users/${TARGET_ID}`)));
  });

  it("keeps them out of the applications queue", async () => {
    const prisma = createAdminPrisma({ user: { findMany: vi.fn().mockResolvedValue([leakyRow()]) } });

    assertClean(await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/applications")));
  });

  it("keeps them out of an approval response", async () => {
    const { prisma } = decisionPrisma(leakyRow());

    assertClean(
      await asAdmin(supertest(buildTestApp({ prisma })).post(`/api/admin/applications/${TARGET_ID}/approve`)),
    );
  });

  it("keeps them out of a role change", async () => {
    const { prisma } = decisionPrisma(leakyRow({ role: "USER" }));

    assertClean(
      await asAdmin(supertest(buildTestApp({ prisma })).patch(`/api/admin/users/${TARGET_ID}/role`)).send({
        role: "agent",
      }),
    );
  });

  it("keeps them out of the overview's recent signups", async () => {
    const prisma = createAdminPrisma({
      user: {
        groupBy: vi.fn().mockResolvedValue([]),
        findMany: vi.fn().mockResolvedValue([leakyRow()]),
      },
      ad: { groupBy: vi.fn().mockResolvedValue([]) },
      lead: { groupBy: vi.fn().mockResolvedValue([]) },
      adPublication: { groupBy: vi.fn().mockResolvedValue([]) },
    });

    assertClean(await asAdmin(supertest(buildTestApp({ prisma })).get("/api/admin/overview")));
  });
});
