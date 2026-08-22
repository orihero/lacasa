// Prisma calls only — no business logic, no HTTP concerns. Every function
// takes `prisma` (i.e. `ctx.prisma`) as its first argument so it stays
// testable against the fake ctx in test/helpers/testApp.js without a real
// database.
//
// Several functions here are called with an interactive-transaction client
// (`tx`) rather than the root client — that is deliberate and needs no second
// set of functions, because a Prisma transaction client exposes the same
// model/`$queryRaw` surface. The parameter is still named `prisma` so the
// signature convention above holds uniformly across this directory.

// ---------------------------------------------------------------------------
// Overview aggregates

// One round trip, not six. `$transaction([...])` is the batching form (all
// six statements go to Postgres together and run in one transaction), which
// matters twice over here: the dashboard's tiles are read as a single
// consistent snapshot rather than six independently-timed counts that can
// disagree with each other, and the control room pays one network round trip
// instead of six.
//
// Every aggregate is a `groupBy` over the whole table rather than one
// `count()` per bucket — five buckets of lead status would otherwise be five
// queries, and adding a sixth LeadStatus value to schema.prisma would
// silently not appear until someone remembered to add a query for it. The
// grouped form picks up new enum values for free; the service layer is what
// zero-fills the buckets that have no rows (a `groupBy` cannot emit a group
// with count 0 — there are no rows to group).
export function overviewAggregates(prisma) {
  return prisma.$transaction([
    prisma.user.groupBy({ by: ["role"], _count: { _all: true } }),
    prisma.user.groupBy({ by: ["realtorStatus"], _count: { _all: true } }),
    prisma.ad.groupBy({ by: ["stage"], _count: { _all: true } }),
    prisma.lead.groupBy({ by: ["status"], _count: { _all: true } }),
    prisma.adPublication.groupBy({ by: ["status"], _count: { _all: true } }),
    // Newest signups, tie-broken on id for the same reason every paged read
    // below is — two accounts created in the same millisecond must still come
    // back in a stable order.
    prisma.user.findMany({ orderBy: [{ createdAt: "desc" }, { id: "desc" }], take: 5 }),
  ]);
}

// ---------------------------------------------------------------------------
// Keyset pagination
//
// Every list below is ordered (createdAt desc, id desc) and paged with
// Prisma's `cursor`/`skip: 1`, exactly like agentRepository.js#findReviewsForAgent:
// the cursor is the previous page's last row id (opaque to the client, but in
// fact just a uuid), and `take` is the caller's page size *plus one* so the
// service can tell "there is a next page" from "that was the last row"
// without a second COUNT(*). id is both the tie-breaker that makes the order
// total and the cursor value itself, since it is the unique field Prisma's
// cursor pagination needs.

const pageArgs = ({ take, cursor }) => ({
  orderBy: [{ createdAt: "desc" }, { id: "desc" }],
  take,
  ...(cursor ? { cursor: { id: cursor }, skip: 1 } : {}),
});

// ---------------------------------------------------------------------------
// Realtor applications

// `realtorStatus` is always one of PENDING/APPROVED/REJECTED here (the
// service maps the wire key and the route rejects anything else), which is
// what keeps NONE — every buyer who never applied — out of this list without
// needing an extra `not: "NONE"` clause that could drift from the filter.
export function findApplications(prisma, { realtorStatus, take, cursor }) {
  return prisma.user.findMany({ where: { realtorStatus }, ...pageArgs({ take, cursor }) });
}

// ---------------------------------------------------------------------------
// Users directory

// `q` matches fullName OR email, case-insensitively. `mode: "insensitive"`
// is a Postgres-only Prisma feature (it compiles to ILIKE) — fine here,
// this app has no other datasource.
//
// Filters are composed as an object rather than a chain of conditional
// `where` merges so an absent filter contributes literally nothing: Prisma
// drops `undefined` fields, so `{ role: undefined }` is not "role is null",
// it is "do not filter on role".
export function findUsers(prisma, { q, role, realtorStatus, take, cursor }) {
  return prisma.user.findMany({
    where: {
      role,
      realtorStatus,
      ...(q
        ? {
            OR: [
              { fullName: { contains: q, mode: "insensitive" } },
              { email: { contains: q, mode: "insensitive" } },
            ],
          }
        : {}),
    },
    ...pageArgs({ take, cursor }),
  });
}

export function findUserById(prisma, id) {
  return prisma.user.findUnique({ where: { id } });
}

export function updateUser(prisma, id, data) {
  return prisma.user.update({ where: { id }, data });
}

// One grouped query for however many users are on the current page, rather
// than a count per row — same shape and reasoning as
// agentRepository.js#countAdsByAgentIds. Prisma handles an empty `in` list
// fine, so callers need no special case, and a user with zero ads simply has
// no row in the result (a groupBy cannot produce a zero-count group), which
// the service turns into 0.
//
// Counted by *ownership* (`agentId`), not by authorship: an ad a coworker
// created belongs to the agency, so it counts toward the agent's row and not
// the coworker's. That is exactly the number the role-change screen needs —
// "demoting this AGENT would orphan N ads" — and it is why a coworker
// honestly reads 0 here.
export function countAdsByOwnerIds(prisma, userIds) {
  return prisma.ad.groupBy({
    by: ["agentId"],
    where: { agentId: { in: userIds } },
    _count: { _all: true },
  });
}

export function countLeadsByOwnerIds(prisma, userIds) {
  return prisma.lead.groupBy({
    by: ["agentId"],
    where: { agentId: { in: userIds } },
    _count: { _all: true },
  });
}

export function countAdmins(prisma, { excludeUserId }) {
  return prisma.user.count({ where: { role: "ADMIN", id: { not: excludeUserId } } });
}

// ---------------------------------------------------------------------------
// Row locks for the two write paths
//
// Both writes below re-read their row inside the transaction, and a plain
// re-read is not enough on its own: Postgres runs at READ COMMITTED by
// default, where two concurrent transactions can each SELECT the same
// still-PENDING application, each see "pending", and each UPDATE it. The
// re-read has to take a lock for the check to actually mean anything by the
// time the UPDATE lands — that is what `FOR UPDATE` adds, and it is why these
// are raw statements: Prisma's query builder has no way to express row-level
// locking.
//
// `${userId}::uuid` goes through Prisma's tagged-template parameter binding,
// never string interpolation, so this is safe from injection despite being
// raw SQL. The route validates the id as a uuid before it ever gets here, so
// the cast cannot fail with a 22P02 on a malformed value.

export function lockUserForUpdate(prisma, userId) {
  return prisma.$queryRaw`SELECT "id" FROM "users" WHERE "id" = ${userId}::uuid FOR UPDATE`;
}

// A role change needs a wider lock than a single row, because the
// "last_admin" rule is a fact about the whole ADMIN population, not about the
// row being edited: two admins demoting *each other* concurrently would each
// count one remaining admin (the other one, not yet demoted) and both
// succeed, leaving zero. Locking every ADMIN row alongside the target
// serializes any two role changes that could interact, so the count taken
// after this statement stays true until the transaction commits.
//
// `ORDER BY "id"` is what keeps that safe from deadlocking itself: two
// concurrent callers acquire the same rows in the same order, so one simply
// waits for the other instead of the pair blocking on locks held crosswise.
export function lockUsersForRoleChange(prisma, userId) {
  return prisma.$queryRaw`
    SELECT "id" FROM "users"
    WHERE "id" = ${userId}::uuid OR "role" = 'ADMIN'::"UserRole"
    ORDER BY "id"
    FOR UPDATE
  `;
}

// ---------------------------------------------------------------------------
// Audit trail

// ActivityEvent is the audit trail — there is no separate admin-action log,
// and this read is query-only (nothing in /api/admin writes an event; see the
// note on actorFields in src/middleware/roles.js, which returns null for an
// ADMIN precisely because an admin has no agent scope to attribute an event
// to).
//
// Each relation is pulled with an explicit `select` rather than a bare
// `include`: the audit table shows a name and a title, and there is no reason
// for an admin list endpoint to ship a lead's phone number or an ad's full
// description over the wire to render one cell.
export function findAuditEvents(prisma, { type, agentId, take, cursor }) {
  return prisma.activityEvent.findMany({
    where: { type, agentId },
    include: {
      agent: { select: { id: true, fullName: true } },
      coworker: { select: { id: true, fullName: true } },
      ad: { select: { id: true, title: true } },
      lead: { select: { id: true, fullName: true } },
    },
    ...pageArgs({ take, cursor }),
  });
}
