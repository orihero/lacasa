import { adInputSchema } from "@lacasa/domain";
import { AD_TYPE, AD_CATEGORY, REPAIRMENT, FURNITURE, AD_STAGE } from "../lib/enums.js";
import { serializeAd, parseAdInput } from "../lib/adsSerializer.js";
import { BUCKET, objectKeyFromUrl } from "../lib/minio.js";
import { createWithActivityEvent, logActivityEvent } from "../lib/activity.js";
import * as adRepository from "../repositories/adRepository.js";

export function buildAdFilters(query) {
  const where = {};
  if (query.agentId) where.agentId = query.agentId;
  if (query.city) where.city = query.city;
  if (query.district) where.district = query.district;
  if (query.category && AD_CATEGORY[query.category]) where.category = AD_CATEGORY[query.category];
  if (query.type && AD_TYPE[query.type]) where.type = AD_TYPE[query.type];
  if (query.rooms) where.rooms = Number(query.rooms);
  if (query.repairment && REPAIRMENT[query.repairment]) where.repairment = REPAIRMENT[query.repairment];
  if (query.storey) where.storey = Number(query.storey);
  if (query.furniture && FURNITURE[query.furniture]) where.furniture = FURNITURE[query.furniture];
  if (query.areaMin || query.areaMax) {
    where.area = {};
    if (query.areaMin) where.area.gte = Number(query.areaMin);
    if (query.areaMax) where.area.lte = Number(query.areaMax);
  }
  if (query.priceMin || query.priceMax) {
    where.price = {};
    if (query.priceMin) where.price.gte = Number(query.priceMin);
    if (query.priceMax) where.price.lte = Number(query.priceMax);
  }
  // Wire values are the "1"/"2"/"3" form-select values AD_STAGE already maps
  // (see packages/domain/src/enums/ads.ts's comment -- never the literal
  // strings "ACTIVE"/"SOLD"/"DRAFT" over the wire), same lookup-and-ignore
  // pattern as category/type/repairment/furniture above. Harmless to set
  // unconditionally here even for the public GET /ads path: listAds()
  // overwrites `where.stage` back to "ACTIVE" right after calling this
  // function whenever no `agentId` scope is given, so a stray `?stage=`
  // on the public feed can never leak a non-active ad.
  if (query.stage && AD_STAGE[query.stage]) where.stage = AD_STAGE[query.stage];
  return where;
}

// `?q=` free-text search (title/description/address/district/city), OR'd
// together with `contains`+`mode: "insensitive"` -- i.e. a per-row ILIKE
// scan. Postgres full-text search (a GIN-indexed `to_tsvector` column +
// `plainto_tsquery` match) would scale far better and rank results instead
// of just filtering them, but stands up a new indexed column, which means a
// migration -- out of scope for this slice (prisma/schema.prisma belongs to
// the schema-phase agent this run). Follow-up: add a generated/maintained
// tsvector column with a GIN index, then swap this for an `@@` match.
function applySearch(where, q) {
  if (q === undefined || q === null) return;
  const term = String(q).trim();
  if (!term) return;
  where.OR = ["title", "description", "address", "district", "city"].map((field) => ({
    [field]: { contains: term, mode: "insensitive" },
  }));
}

// Whitelist of wire `sort` values -> {field, direction}. Never pass a
// caller-supplied string straight into a Prisma `orderBy` -- Prisma turns
// that object into a raw ORDER BY clause, so an un-whitelisted key would be
// attacker-controlled input reaching the query builder (at best a 500 from
// an invalid column, at worst a way to probe column names that don't appear
// anywhere in the API's own shape). Resolving through this fixed map and
// falling back to the default on anything unrecognised closes that off
// entirely -- there is no code path where an arbitrary string reaches
// Prisma.
//
// `highestPrice`/`lowestPrice` are kept as aliases for `priceDesc`/
// `priceAsc` rather than replaced: they're the exact values apps/web
// (lib/adsListStore.js -> Filter.jsx / SearchPage.jsx) and apps/console
// (SortSelect.tsx, typed via @lacasa/api-client's `AdSort`) already send to
// `GET /my/ads` today. Adding the new canonical names alongside them is
// what lets this slice add `oldest`/`areaAsc`/`areaDesc` without a
// coordinated client change.
const SORT_WHITELIST = {
  newest: { field: "createdAt", direction: "desc" },
  oldest: { field: "createdAt", direction: "asc" },
  priceAsc: { field: "price", direction: "asc" },
  priceDesc: { field: "price", direction: "desc" },
  areaAsc: { field: "area", direction: "asc" },
  areaDesc: { field: "area", direction: "desc" },
  highestPrice: { field: "price", direction: "desc" }, // legacy alias, see above
  lowestPrice: { field: "price", direction: "asc" }, // legacy alias, see above
};

function resolveSort(sortParam) {
  return SORT_WHITELIST[sortParam] ?? SORT_WHITELIST.newest;
}

const DEFAULT_LIMIT = 20;
const MAX_LIMIT = 100;

function clampLimit(rawLimit) {
  const n = Number(rawLimit);
  if (!Number.isFinite(n) || n <= 0) return DEFAULT_LIMIT;
  return Math.min(Math.floor(n), MAX_LIMIT);
}

// A page is only ever returned as `{ items, nextCursor }` when the caller
// opts in by touching one of the paging params -- see listAds()'s own
// comment for why the bare-array response has to stay the unconditional
// default.
function isPagedRequest(query) {
  return query.limit !== undefined || query.cursor !== undefined || query.paged === "true";
}

function serializeSortValue(value) {
  if (value === null || value === undefined) return null;
  if (value instanceof Date) return value.toISOString();
  return value.toString(); // Prisma Decimal (price/area) or a plain number
}

// Cursor = base64url(JSON{v, id}) where `v` is the *sort field's* value on
// the last row of the previous page (serialized, or null) and `id` is that
// row's id, its tiebreaker. Opaque and unversioned on purpose -- nothing
// outside this module ever inspects a cursor, it only ever gets echoed back
// on the next request.
function encodeCursor(sort, row) {
  const payload = JSON.stringify({ v: serializeSortValue(row[sort.field]), id: row.id });
  return Buffer.from(payload, "utf8").toString("base64url");
}

function decodeCursor(cursor) {
  try {
    const { v, id } = JSON.parse(Buffer.from(String(cursor), "base64url").toString("utf8"));
    if (typeof id !== "string" || !id) return null;
    return { v: v ?? null, id };
  } catch {
    return null; // garbled/forged cursor -> treated as "start from the top", not a 400
  }
}

// Keyset ("seek") pagination on (sort.field, id) rather than an offset or a
// bare `createdAt` cursor: `LIMIT/OFFSET` re-scans and re-discards every
// prior row on each page (gets slower as the offset grows), and a cursor on
// `createdAt` alone breaks the moment two ads share a timestamp -- which is
// exactly what happens with seeded/bulk-imported data, since Postgres makes
// no ordering guarantee among rows tied on the ORDER BY key. Rows can be
// silently skipped (a tied row that sorted "before" the cursor row within
// the tie gets excluded by a naive `createdAt < cursor` filter) or repeated
// (the reverse). `id` is unique and immutable, so `(field, id)` is always a
// total order and every row appears on exactly one page.
//
// The `v === null` branches exist because `area` (unlike
// `price`/`createdAt`) is a nullable column: Postgres's default null
// placement is NULLS LAST for ASC and NULLS FIRST for DESC, so nulls form
// one contiguous block at one end of the ordering, tie-broken by `id` same
// as any other tied group -- these branches just walk that block the same
// way the non-null branches walk everything else.
function buildCursorWhere(sort, cursor) {
  const decoded = decodeCursor(cursor);
  if (!decoded) return null;
  const { v, id } = decoded;
  const isDesc = sort.direction === "desc";

  if (v === null) {
    if (isDesc) {
      // Nulls-first: still inside the null block (more nulls with a smaller
      // id), or we've exhausted it and every remaining row is non-null
      // (nulls can't reappear after the block, by definition).
      return { OR: [{ [sort.field]: null, id: { lt: id } }, { [sort.field]: { not: null } }] };
    }
    // Nulls-last: the null block is the tail of the ordering, so the only
    // rows left are more nulls with a bigger id.
    return { [sort.field]: null, id: { gt: id } };
  }

  const value = sort.field === "createdAt" ? new Date(v) : Number(v);
  if (isDesc) {
    // Nulls-first + a non-null cursor means we're already past the entire
    // null block, so it can't reappear here.
    return { OR: [{ [sort.field]: { lt: value } }, { [sort.field]: value, id: { lt: id } }] };
  }
  // Nulls-last: a larger value, the same value with a bigger id, or -- since
  // every null sorts after every non-null value in ASC order -- any null.
  return {
    OR: [{ [sort.field]: { gt: value } }, { [sort.field]: value, id: { gt: id } }, { [sort.field]: null }],
  };
}

function photosCreateData(photos) {
  return (photos ?? []).map((url, position) => ({ url, objectKey: objectKeyFromUrl(url), position }));
}

// Mirrors publishService.js's local httpError helper (no shared lib exists
// for this yet) -- routes catch it via a matching `handleServiceError`
// (see routes/ads.js) that reads `.status`/`.code` and maps straight to the
// `{ error: { code, message } }` envelope, falling through to the generic
// 500 handler for anything else.
function httpError(status, code, message) {
  const err = new Error(message);
  err.status = status;
  err.code = code;
  return err;
}

const LAT_RANGE = [-90, 90];
const LNG_RANGE = [-180, 180];

// Ad.lat/Ad.lng (docs/10 §3, listing-detail map pin). Two rules, both
// enforced here rather than in parseAdInput or the packages/domain zod
// mirror:
//
// 1. Range: -90..90 for lat, -180..180 for lng. Only checked against
//    fields actually present on *this* request (`data`, already coerced to
//    number|null by parseAdInput) -- a field the caller didn't touch keeps
//    whatever is already in the DB, which was already valid (or NULL) when
//    it was written, so it's not re-checked.
// 2. "Both set or both null": a pin with only one coordinate is
//    meaningless. This can only be decided from the *effective* post-write
//    value of each field -- this request's value if provided, else the
//    existing row's -- because PATCH bodies are partial (`PATCH {lng: null}`
//    on an ad that already has both set must fail, but nothing in that
//    body alone reveals lat is currently set). That's why this rule isn't
//    expressible as a per-field zod check or a DB CHECK constraint, and why
//    it lives in the service layer, which is the only place with both the
//    request and (on update) the pre-existing row.
//
// `existing` is `null` for createAd (nothing on the row yet).
function validateCoordinates(data, existing) {
  const fields = [
    ["lat", LAT_RANGE],
    ["lng", LNG_RANGE],
  ];

  for (const [key, [min, max]] of fields) {
    if (!(key in data)) continue;
    const value = data[key];
    if (value !== null && (typeof value !== "number" || Number.isNaN(value) || value < min || value > max)) {
      throw httpError(400, "validation", `${key} must be a number between ${min} and ${max}, or null`);
    }
  }

  const effectiveLat = "lat" in data ? data.lat : (existing ? existing.lat : null);
  const effectiveLng = "lng" in data ? data.lng : (existing ? existing.lng : null);
  if ((effectiveLat === null) !== (effectiveLng === null)) {
    throw httpError(400, "validation", "lat and lng must be set together, or both left null");
  }
}

// Ad.tour3dLink must be an absolute http(s) URL. The rule itself is defined
// once, in @lacasa/domain's adInputSchema, and only invoked here so ad-write
// validation stays in one layer alongside validateCoordinates rather than
// splitting across a second mechanism in the route.
//
// Checks the raw body, not parseAdInput's output: the schema does its own
// "" -> null coercion, and by the time parseAdInput has run the original
// string is gone.
const tour3dLinkSchema = adInputSchema.pick({ tour3dLink: true });

function validateTour3dLink(body) {
  if (body.tour3dLink === undefined) return;
  const parsed = tour3dLinkSchema.safeParse({ tour3dLink: body.tour3dLink });
  if (!parsed.success) {
    throw httpError(400, "validation", parsed.error.issues[0].message);
  }
}

// Public listing (GET /api/ads, no `agentId` option) is always scoped to
// ACTIVE ads; the caller (myAds.js) supplies `agentId` to instead list
// everything a given agent owns, active or not. `orderBy`, when a caller
// passes it explicitly, bypasses `query.sort` entirely and is used
// verbatim -- kept only for callers (and the existing unit test) that want
// to force an exact Prisma orderBy rather than go through the wire-value
// whitelist; myAds.js itself no longer does this, it passes `sort` through
// `query` like every other caller.
//
// Response shape: a bare array, unconditionally, UNLESS the caller opts
// into paging (`?limit=`, `?cursor=`, or `?paged=true`), in which case the
// response becomes `{ items, nextCursor }`. This has to be an opt-in, not a
// blanket change -- `GET /api/ads` today returns a bare JSON array and
// apps/web, apps/console and apps/mobile_flutter's AdsResource.list() /
// AgentAdsResource.myList() all decode the response directly as an array
// (`(json as List<dynamic>)` on the Flutter side); wrapping it in an
// envelope unconditionally would 500 or silently break every one of them
// the moment they tried to `.map()` over `{ items, nextCursor }`. None of
// today's callers send `limit`/`cursor`/`paged`, so none of them notice
// this feature exists until a client is deliberately updated to ask for it.
//
// `?countOnly=true` is the third response shape: `{ count }`, and nothing
// else. It exists for callers that only ever wanted the *size* of the
// result set -- apps/mobile_flutter's filter sheet renders a live
// "Apply Filters (N)" preview that re-fires on every debounced field edit,
// and with no count route to call it was reduced to fetching every matching
// row (fully serialized, photo URLs and all) purely to read `.length`. That
// cost grows linearly with the catalogue while the answer is one integer.
// Deliberately ignores `sort`/`limit`/`cursor`: a count is both order- and
// page-independent, so honouring them would only invite the caller to
// believe it counts a page rather than the whole match. See the branch
// itself for why it sits where it does.
export async function listAds(ctx, query, { agentId, orderBy } = {}) {
  const where = buildAdFilters(query);
  if (agentId) {
    where.agentId = agentId;
  } else {
    where.stage = "ACTIVE";
  }
  applySearch(where, query.q);

  // Placed *here* -- after the stage/agent scoping above and after
  // applySearch -- rather than next to buildAdFilters, so the count is taken
  // against the exact same `where` the list branches below would use. Any
  // earlier and a public `?countOnly=true` would count DRAFT/SOLD rows the
  // matching list call can never return, and a `q=` search would be counted
  // as if it weren't there: the number on the button would disagree with the
  // results behind it, which is worse than no number at all.
  if (query.countOnly === "true" || query.countOnly === true) {
    return { count: await adRepository.countAds(ctx.prisma, { where }) };
  }

  const sort = resolveSort(query.sort);
  const paged = isPagedRequest(query);

  if (!paged) {
    // Legacy path: whole result set, no `id` tiebreaker on the orderBy --
    // there's no page boundary here for a duplicate-timestamp tie to fall
    // across, since every matching row comes back in a single response.
    const legacyOrderBy = orderBy ?? { [sort.field]: sort.direction };
    const ads = await adRepository.findManyAds(ctx.prisma, { where, orderBy: legacyOrderBy });
    return ads.map(serializeAd);
  }

  const limit = clampLimit(query.limit);
  const cursorWhere = query.cursor ? buildCursorWhere(sort, query.cursor) : null;
  // AND, not a merge -- `where` may itself carry an `OR` (from applySearch)
  // that a naive `{ ...where, ...cursorWhere }` would clobber.
  const finalWhere = cursorWhere ? { AND: [where, cursorWhere] } : where;
  const keysetOrderBy = orderBy ?? [{ [sort.field]: sort.direction }, { id: sort.direction }];

  const rows = await adRepository.findManyAds(ctx.prisma, { where: finalWhere, orderBy: keysetOrderBy, take: limit + 1 });
  const hasMore = rows.length > limit;
  const page = hasMore ? rows.slice(0, limit) : rows;

  return {
    items: page.map(serializeAd),
    nextCursor: hasMore ? encodeCursor(sort, page[page.length - 1]) : null,
  };
}

export async function getAd(ctx, id) {
  const ad = await adRepository.findAdById(ctx.prisma, id);
  return ad ? serializeAd(ad) : null;
}

export async function createAd(ctx, body, actor) {
  const data = parseAdInput(body);
  validateCoordinates(data, null);
  validateTour3dLink(body);
  const photos = Array.isArray(body.photos) ? body.photos : [];

  const ad = await createWithActivityEvent(
    ctx,
    "ad",
    "AD_CREATED",
    {
      data: {
        ...data,
        priceType: data.priceType ?? "UZS",
        stage: data.stage ?? "ACTIVE",
        agentId: actor.agentId,
        coworkerId: actor.coworkerId,
        photos: { create: photosCreateData(photos) },
      },
      include: adRepository.AD_INCLUDE,
    },
    actor,
  );

  return serializeAd(ad);
}

// Returns null when no ad matches `id` under `agentId` (caller maps that to
// 404). `actor` drives the activity event, `agentId` scopes the lookup —
// they're the same value for an AGENT, different for a COWORKER acting on
// their agent's ads.
export async function updateAd(ctx, id, agentId, body, actor) {
  const existing = await adRepository.findAdByIdForAgent(ctx.prisma, id, agentId);
  if (!existing) return null;

  const data = parseAdInput(body);
  validateCoordinates(data, existing);
  validateTour3dLink(body);
  const photosProvided = Array.isArray(body.photos);

  const ad = await adRepository.updateAd(ctx.prisma, id, {
    ...data,
    ...(photosProvided ? { photos: { deleteMany: {}, create: photosCreateData(body.photos) } } : {}),
  });

  // Faithful to the original behavior (AdsEdit.tsx): any edit logs either
  // AD_SOLD (stage -> sold) or AD_DRAFT_UPDATED, never a distinct
  // "ad reactivated" event — see docs/03-data-model.md's statistics mapping.
  await logActivityEvent(ctx, data.stage === "SOLD" ? "AD_SOLD" : "AD_DRAFT_UPDATED", actor, { adId: ad.id });

  return serializeAd(ad);
}

// Returns null when no ad matches (404), true once deleted. Only an AGENT
// may delete (enforced by the route, which is why `agentId` here is always
// the caller's own id, never a coworker's agent scope).
export async function deleteAd(ctx, id, agentId) {
  const existing = await adRepository.findAdByIdForAgent(ctx.prisma, id, agentId);
  if (!existing) return null;

  await adRepository.deleteAd(ctx.prisma, id);

  await Promise.all(existing.photos.map((p) => ctx.minio.removeObject(BUCKET, p.objectKey).catch(() => {})));

  return true;
}

export async function stageCounts(ctx, agentId) {
  const counts = await adRepository.countAdsByStage(ctx.prisma, agentId);
  const byStage = Object.fromEntries(counts.map((c) => [c.stage, c._count._all]));
  return {
    stage1: byStage.ACTIVE ?? 0,
    stage2: byStage.SOLD ?? 0,
    stage3: byStage.DRAFT ?? 0,
  };
}
