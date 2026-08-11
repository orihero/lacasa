# API Specification (v1)

Base URL: `http://localhost:4200/api` (dev). All responses JSON.
Auth: `Authorization: Bearer <JWT>` unless marked **public**.

Errors: `{ "error": { "code": "string", "message": "string" } }` with proper
HTTP status (400 validation, 401 unauthenticated, 403 forbidden, 404 not found).

## Auth

| Method & path | Access | Body / params | Returns |
|---|---|---|---|
| `POST /auth/register` | public | `{ fullName, email, password, phoneNumber?, realtor? }` | `{ token, user }` — role is always USER |
| `POST /auth/login` | public | `{ email, password }` | `{ token, user }` |
| `GET /auth/me` | any | — | `{ user }` (with resolved agent info for coworkers) |

`user` objects never include `password_hash` or IG tokens.

`realtor` is the sign-up choice from mockups/SCREENS.md §13, validated by
`@lacasa/domain`'s `realtorApplicationSchema` — either `{ kind: "solo" }` or
`{ kind: "agency", agencyName, officePhone?, teamSize }`, where `teamSize` is one of
`just_me | two_to_five | six_to_fifteen | sixteen_plus`. Omitting it registers a buyer.
Sending it records a **pending application** and still returns `role: "user"`: it is not
a way to self-promote to agent. The application comes back on every `user` object as
`realtor: { kind, status, agencyName, officePhone, teamSize, appliedAt, decidedAt }`,
or `null` for buyers and coworkers.

`POST /coworkers` 403s with `solo_realtor` when the calling agent's kind is `solo` — a
team is what an agency has.

## Users / agents

| Method & path | Access | Notes |
|---|---|---|
| `GET /agents` | public | agents directory (role=AGENT) + `adsCount` + `ratingAverage`/`ratingCount` |
| `GET /agents/:id` | public | public agent profile + `adsCount` + `dealsClosedCount` + `ratingAverage`/`ratingCount` |
| `PATCH /users/me` | any | own profile: fullName, phoneNumber, avatarUrl, address, password (re-hash), tgChatIds (agent) |
| `GET /auth/instagram/connect` | agent | 302 → Meta OAuth authorize URL; replaces the manual-token-paste flow — see `09-instagram-onboarding.md` §1 |
| `GET /auth/instagram/callback` | public (Meta calls this) | code/token exchange, upserts `agent_ig_tokens`, 302 back to `/settings` |
| `DELETE /auth/instagram/:igUserId` | agent (own) | disconnect a connected IG account |

`GET /agents/:id` backs the "Agent · N listings · M closed" row under a listing
(mockups/SCREENS.md §4.3). `adsCount` counts AD_CREATED activity events, the
same measure the directory uses; `dealsClosedCount` counts the agent's ads at
stage SOLD. The list endpoint deliberately does not carry `dealsClosedCount` —
nothing in the directory renders it. Both 404 for an id that is a real user but
not an AGENT.

`ratingAverage`/`ratingCount` are the `agent_reviews` aggregate (docs/03).
`ratingAverage` is `null` (never `0`/`0.0`) for an agent with zero reviews —
see docs/03's note on why a `groupBy` can't tell "no reviews" apart from
"average of zero" any other way.

### Agent reviews (mockups/SCREENS.md §3.9)

| Method & path | Access | Notes |
|---|---|---|
| `GET /agents/:id/reviews?limit=&cursor=` | public | newest-first (`createdAt desc, id desc`); `limit` 1..50 (default 20); `cursor` = previous page's last review `id` |
| `POST /agents/:id/reviews` | any authenticated | `{ rating: 1..5, comment?: string }` → upsert on `(agentId, authorId)`; `200` (not `201`) since a repeat post edits rather than stacks |
| `DELETE /agents/:id/reviews/me` | any authenticated | `204`, idempotent — removing a review that was never posted (or already removed) still answers `204` |

`GET` response: `{ reviews: [{ id, rating, comment, createdAt: { seconds }, author: { id, fullName, avatar } }], nextCursor: string | null }`.
`createdAt` is `{ seconds }` like every other timestamp on the wire (see the
`GET /statistics/coworkers` note below), not a bare ISO-8601 string.
`author` is public identity only — no email or phone leaves this endpoint.

`POST` error codes: `400 validation` (non-integer or out-of-range rating,
or a malformed body), `403 forbidden` (self-review — `agentId === authorId`),
`404 not_found` (`:id` is a real user but not role AGENT).

## Coworkers (agent only; replaces the client-side second-Firebase-app hack)

| Method & path | Notes |
|---|---|
| `GET /coworkers` | list coworkers of the authenticated agent |
| `POST /coworkers` | `{ fullName, email, password, phoneNumber?, avatarUrl? }` |
| `GET /coworkers/:id` | scoped to own agentId |
| `PATCH /coworkers/:id` | |
| `DELETE /coworkers/:id` | |

## Ads

| Method & path | Access | Notes |
|---|---|---|
| `GET /ads` | public | active (stage=ACTIVE) ads; filters: `city, district, category, type, rooms, repairment, storey, furniture, areaMin, areaMax, priceMin, priceMax, q`; `sort`; opt-in paging |
| `GET /ads/:id` | public | includes photos + public agent card |
| `GET /my/ads` | agent/coworker | own listings, same filters + `stage`, `sort`; opt-in paging |
| `GET /my/ads/stage-counts` | agent/coworker | `{ active, sold, draft }` for tabs |
| `POST /ads` | agent/coworker | full ad payload + `photos: [{url, objectKey}]`; logs AD_CREATED |
| `PATCH /ads/:id` | agent/coworker (own) | stage transitions log AD_SOLD / AD_DRAFT_UPDATED |
| `DELETE /ads/:id` | agent (own) | also deletes MinIO objects |

`q` is a case-insensitive substring match, OR'd across `title`, `description`,
`address`, `district`, `city` (Postgres full-text search is a named follow-up,
not yet built — see `adService.js#applySearch`). A blank/whitespace-only `q`
is a no-op.

`sort` is one of `newest` (default), `oldest`, `priceAsc`, `priceDesc`,
`areaAsc`, `areaDesc`, plus the legacy wire values `highestPrice`/`lowestPrice`
(aliases for `priceDesc`/`priceAsc`, kept because apps/web and apps/console
already send them to `GET /my/ads`). An unrecognized value falls back to
`newest` rather than erroring.

**Paging is opt-in.** Both endpoints return a bare JSON array by default,
unchanged from before — every existing client decodes the response directly
as an array. Sending `limit`, `cursor`, or `paged=true` switches the response
to `{ items: Ad[], nextCursor: string | null }` instead:

- `limit` — default 20, capped at 100.
- `cursor` — opaque, from the previous page's `nextCursor`; omit for the
  first page. Malformed/forged cursors are treated as "start from the top",
  not a `400`.
- On `GET /my/ads` only, `stage` (`"1"/"2"/"3"`, same wire values as
  `PATCH /ads/:id`) additionally filters by stage; on the public `GET /ads`
  a stray `?stage=` can never leak a non-active ad — `listAds` always forces
  `stage=ACTIVE` on that path regardless of what filters resolved to.

Every serialized ad carries three fields added for the Liquid Glass listing
detail (docs/10 §3):

- `lat`/`lng` — `number | null`, the map pin. Always present, never mixed: both
  set or both null, rejected with `400 validation` otherwise. Branch on
  `lat !== null && lng !== null`, **not** on falsiness — a pin at latitude 0 is
  valid. Existing ads are unpinned until someone sets coordinates.
- `tour3dLink` — `string | null`. Writes are restricted to absolute `http(s)`
  URLs (`400 validation` otherwise) because the value is rendered into an
  `<iframe src>`; relative and protocol-relative values are refused too.
- `media` — `[{url, mediaType, position}]`, the full ordered photo/video set.
  `photos` is unchanged and still a flat `string[]` of **photo** URLs only, so
  existing consumers and the crosspost payloads keep working.

Price per m² is not returned — clients compute it from `price`/`area` with
`@lacasa/domain`'s `computePricePerSqm`.

## Saved ads (favourites)

| Method & path | Access | Notes |
|---|---|---|
| `GET /saved-ads` | any authenticated | the caller's saved listings, newest save first; each entry is a full serialized ad plus `saved: true` |
| `POST /saved-ads/:adId` | user only | `{ ok: true }`; idempotent |
| `DELETE /saved-ads/:adId` | user only | `204`; idempotent |

The heart control is a buyer's, so `POST`/`DELETE` 403 `forbidden` for AGENT and
COWORKER callers rather than relying on the client to hide the button
(mockups/SCREENS.md §17). `GET` stays open to every role — an agent's list is
simply always empty, which beats 403ing a page that only wants to render.

Both writes are idempotent: saving an already-saved ad returns the same
`200 { ok: true }` and leaves one row (the `@@unique([userId, adId])` makes the
repeat the same fact), and unsaving something never saved still answers `204`.
`POST` 404s for an id that matches no ad, including a malformed one.

`GET /ads` and `GET /ads/:id` are deliberately untouched — they stay public and
carry no per-user `saved` flag, so the client merges saved state locally
(docs/10 §5 Decision 5). Saving is not restricted by ad stage, matching
`GET /ads/:id`, which does not filter by stage either.

## Leads

| Method & path | Access | Notes |
|---|---|---|
| `GET /leads` | agent/coworker | agent: all own; coworker: `?mine=true` narrows to coworkerId |
| `GET /leads/:id` | agent/coworker (own) | |
| `POST /leads` | agent/coworker | logs LEAD_CREATED |
| `PATCH /leads/:id` | agent/coworker (own) | status change logs LEAD_STATUS_CHANGED (kanban drag) |
| `DELETE /leads/:id` | agent (own) | |

## Statistics (dashboard, agent/coworker only — 403 `forbidden` otherwise)

| Method & path | Notes |
|---|---|
| `GET /statistics/ads?filterType=today\|thisWeek\|thisMonth` | `{ adsNewCount, adsSoldCount }` — a single all-time or `filterType`-bounded total; omit `filterType` for all-time (replaces client-side `useStatisticsStore` math) |
| `GET /statistics/ads/series?filterType=\|from=&to=` | bucketed AD_CREATED/AD_SOLD time series, for a chart |
| `GET /statistics/coworkers` | raw per-event feed: `[{ id, agentId, coworkerId, adId, leadId, stage, createdAt }]` |
| `GET /statistics/coworkers/summary` | one row per coworker: `{ coworkerId, adsCreatedCount, adsSoldCount, leadsCreatedCount, lastActiveAt }` |

`GET /statistics/ads/series` is the bucketed sibling of the scalar `/ads`
endpoint. `filterType` reuses the same `today`/`thisWeek`/`thisMonth`
vocabulary; an explicit `from`/`to` (ISO date strings) wins when both are
given. With neither, it defaults to `today` — unlike the scalar endpoint, an
unbounded bucketed series has no sane bound on response size. `400
validation` if `from`/`to` fail to parse or `from > to`. Response:
```json
{
  "granularity": "hour" | "day",
  "from": { "seconds": 0 },
  "to": { "seconds": 0 },
  "buckets": [{ "bucketStart": { "seconds": 0 }, "adCreatedCount": 0, "adSoldCount": 0 }]
}
```
`granularity` is server-chosen, not caller-supplied: hourly when the resolved
range spans ≤24h, daily otherwise. `buckets` is zero-filled — every bucket in
range appears whether or not any event landed in it, so a chart never has to
guess whether a gap means "zero" or "not fetched".

**Timezone.** `today`/`thisWeek`/`thisMonth` (on both this endpoint and the
scalar `/ads`) are resolved against `STATISTICS_TIMEZONE`, an IANA zone
name configured server-side (default `Asia/Tashkent`) — not the deploying
host's local zone, and not UTC. This app is single-market (phone numbers are
validated `^\+998\d{9}$`, the region vocabulary is Uzbekistan's 14
regions/203 districts), so "today" means today in Uzbekistan for every
agent regardless of where the API process happens to run. Uzbekistan has
run UTC+5 year-round with no DST since 1992, which is why one fixed zone is
exact here; a product serving a second market would need a per-agent zone
instead of one process-wide default. Bucket boundaries (hour/day) are
truncated in the same zone, so a `thisWeek` request always returns exactly
7 daily buckets and a 31-day month always returns exactly 31 — previously
the range was resolved in the deploying host's local zone while buckets
were truncated in UTC, which could pad in an extra all-zero bucket at the
edges whenever those two zones disagreed. This is a correctness fix, not a
contract change: the response shape above is unchanged.

**Range cap.** The resolved range is rejected with `400 validation` before
any bucket grid is built or database query runs if it would need more than
744 buckets — about a month of hourly buckets or two years of daily ones,
comfortably past anything a chart renders, and enough to stop an
open-ended `from`/`to` (e.g. year 1 to year 9999 — both individually valid
ISO dates) from allocating a multi-million-element response. The error
message names the 744 limit explicitly so a client can narrow its request.

`GET /statistics/coworkers/summary` lists every coworker of the calling
agent, including one with zero activity (at `0`, never omitted).
`lastActiveAt` is `null` — not a fabricated timestamp — for a coworker who
has never triggered a tracked event; it is a `{ seconds }` timestamp
otherwise, and is a max over *every* activity-event type, not just the three
counted fields.

## Uploads (MinIO)

| Method & path | Access | Notes |
|---|---|---|
| `POST /uploads/presign` | any authed | `{ fileName, contentType, scope: "ads"\|"avatars" }` → `{ uploadUrl, publicUrl, objectKey }`; presigned PUT, 10-min expiry |

## Publishing & contact (server-held secrets)

All `/publish/*` routes require `requireAuth, loadCurrentUser` plus
`actorFields(req.currentUser)` (agent or coworker) — `403 forbidden`
otherwise.

| Method & path | Notes |
|---|---|
| `POST /publish/telegram` | `{ adId, caption, imageUrls[], chatIds[] }` → sendMediaGroup from server bot token; `chatIds` are matched against the caller's own `User.tgChatIds`; `503 tg_unconfigured` if `TG_BOT_TOKEN` is unset |
| `POST /publish/instagram` | `{ adId }` → carousel publish using stored agent tokens |
| `GET /publish/instagram/accounts` | connected IG accounts for the caller |
| `POST /publish/instagram/consent` | one-time opt-in for extension-assisted IG posting |
| `POST /publish/youtube` | `{ adId, status: "PUBLISHED"\|"FAILED", externalId?, externalUrl?, errorMessage? }` → report-back only; the browser does the OAuth upload itself and reports the outcome here so `AdPublication` has a `YOUTUBE` row |
| `POST /publish/:channel/map-fields` | `{ adId, step, snapshot }` → LLM field-map for the browser extension to execute (`channel` = `olx`) — see `07-olx-crosspost-extension.md` |
| `POST /publish/:channel/confirm` | `{ adId, event }` → extension/human callback recording draft/publish/failure (`channel` = `olx` or `instagram`) |
| `POST /publish/reassign` | reassigns a still-open draft publication to a different ad |
| `POST /publish/ads/:adId/:channel/retry` | replay a `FAILED` direct-publish attempt — see below |
| `GET /publish/ads/:adId/status` | per-channel publish status for one ad — see `08-publish-tracking.md` |
| `GET /publish/status?adIds=id1,id2,...` | bulk per-channel status, up to 200 ids |
| `POST /contact` | public, rate-limited — `{ name, phone, message }` → relayed to the office TG channel |

**`POST /publish/ads/:adId/:channel/retry`** — `:channel` is `telegram` or
`instagram` only (the two channels with a real server-to-server publish call
to replay). No request body: it replays the exact request already stashed
on the failed `AdPublication` row from the original attempt, through the
same `publishTelegramDirect`/`publishInstagramDirect` functions, rather than
re-deriving a fresh caption/photo list that could silently differ from what
the agent originally reviewed. Response on success is identical in shape to
the direct-publish endpoints: `{ publication, results }`.

Error codes: `404 unknown_channel` (`:channel` isn't a real publish channel),
`400 not_retryable` (`:channel` is `youtube`, `olx`, or `realting` — each has
its own reason in `message`: YouTube has no server call to retry, OLX is
human-gated in the extension, Realting syncs on a cron), `403 forbidden` /
`404 ad_not_found` (ownership — for a real `:adId` this is the `Ad.agentId`
check every other `/publish/*` route uses; for a still-open `draft-<uuid>`
`:adId`, which has no `Ad` row to check against, ownership instead resolves
through the `AdPublication` row's own `requestedById` — the effective agent
of whoever originally requested the attempt being retried, which is `403
forbidden` both for a different tenant's draft and for a row whose
`requestedById` is `null`, e.g. because that user's account was later
deleted), `400 not_failed` (no row, or the row was never attempted — use the
normal publish endpoint), `409 already_published`, `409 awaiting_review` (a
human may still be mid-review), `409 retry_unavailable` (a `FAILED` row that
predates retry support and has nothing stored to replay), `409
retry_in_progress` (a concurrent retry won the race).

## Notifications

| Method & path | Access | Notes |
|---|---|---|
| `GET /notifications?since=&limit=` | agent/coworker | merged, newest-first feed derived from leads/ad-lifecycle/coworker/publish activity — no `notifications` table |

There is no `POST /notifications/read`: nothing in this schema durably
stores "read up to when" per agent, and adding that column/table is out of
scope for this slice (see `notificationService.js`'s header comment for the
full reasoning and the exact schema change it would need). Read state
instead flows through `since` (an ISO 8601 timestamp): `unread = createdAt >
since`. Omitting `since` marks every row unread — with no boundary the
server has no basis to claim anything has been seen. `limit` defaults to 50,
capped at 200. Both `since` and `limit` answer `400 validation` for an
unparseable/non-positive value.

Response: a JSON array, each row
`{ id, kind: "lead"|"sold"|"coworkerActivity"|"publish", title, createdAt: { seconds }, unread, targetId }`.
`id` is deterministic — built from the source row's own primary key(s), not
a minted UUID — so an unchanged row reproduces the same id across polls and
a client can dedupe against what it already rendered.

## Push notifications (server-side plumbing only)

| Method & path | Access | Notes |
|---|---|---|
| `POST /push/devices` | any authenticated | `{ token, platform: "ios"\|"android" }` → `{ ok: true }`; idempotent |
| `DELETE /push/devices/:token` | any authenticated | `204`; idempotent |

This is deliberately plumbing only, not a shipped feature: nothing in
`apps/mobile_flutter` calls either route yet, no `POST_NOTIFICATIONS`
permission is declared, and `permission_gateway.dart`'s short-circuit stays
in place — putting a permission prompt in front of a capability that cannot
yet deliver a single message is exactly what that gateway already refuses to
do elsewhere. Unlike `saved-ads`, there is no role restriction: any
authenticated role (buyer, agent, coworker) can register a device, since
nothing about "this device belongs to this account" is role-specific even
though only agents receive a push today (see below).

Both writes are idempotent on `DeviceToken`'s `@@unique([userId, token])`:
re-registering the same device (an app relaunch resending its current
token) upserts in place rather than erroring, same shape as `saved-ads`'s
dedup, and re-registering with a different `platform` updates it in place.
Unregistering a token that was never registered (or already was) still
answers `204` — the caller ends up in the state they asked for either way.

**Delivery** (`pushService.js`). `sendPushToUser(ctx, userId, { title, body,
targetId })` is guarded on `config.PUSH_CONFIGURED` (true only when
`FCM_SERVER_KEY` is set — see `apps/api/src/lib/config.js`, same
optional-integration pattern as `TG_BOT_TOKEN`/`ANTHROPIC_API_KEY`): with no
provider configured — every environment today — it logs and returns without
sending. It is wired into the two places this app already has a real,
honest reason to notify someone in real time, reusing
`notificationService.js`'s `buildLeadNotification` /`buildSoldNotification`
/`buildCoworkerNotification` /`buildPublishNotification` for the copy so a
push and its `GET /notifications` counterpart can never say two different
things about the same event:

- `lib/activity.js#logActivityEvent` — the single choke point every
  `ActivityEvent` write funnels through — fires a push for the same four
  kinds the notification feed derives (`LEAD_CREATED`/`LEAD_STATUS_CHANGED`,
  `AD_SOLD`, coworker-authored `AD_CREATED`); every other event type
  (OLX/IG cross-post session bookkeeping) has no corresponding notification
  kind and is silently skipped.
- `publishService.js`'s `AdPublication` upserts (Telegram/Instagram/YouTube
  direct-publish, and the extension-assisted confirm callback) fire a push
  on a terminal `PUBLISHED`/`FAILED` outcome, reusing `buildPublishNotification`.

Both call sites treat this as fire-and-forget in the strict sense that it
can never fail the write that triggered it: `sendPushToUser` (and its two
callers, `notifyForActivityEvent`/`notifyPublishOutcome`) catch every
failure internally and log it instead of throwing — a push-provider outage,
an expired device token, or `FCM_SERVER_KEY` being unset can never turn a
successful lead creation or ad publish into a `500` (see
`pushService.js`'s file header and `test/lib/activity.test.js` /
`test/services/pushService.test.js` for that guarantee under test).

## Regions

| Method & path | Access | Notes |
|---|---|---|
| `GET /regions?regionId=` | public | `{ regions: Region[], districts: District[] }` — the same static Uzbekistan region/district vocabulary `@lacasa/domain/data/regions` exports, served over HTTP for the one consumer that can't `import` it: apps/mobile_flutter |

Without `regionId`: full vocabulary (14 regions, 203 districts). With a
matching `regionId`: `regions` narrows to that one region (still an array,
not a bare object, so the client uses one parser either way) and `districts`
to that region's districts. An unmatched or non-numeric `regionId` is not an
error — it's a filter that matched nothing, so this still answers `200` with
`{ regions: [], districts: [] }`. `Cache-Control: public, max-age=86400`
plus a standard weak ETag on every response; a conditional GET with a
matching `If-None-Match` gets a `304`.

## Utils

| Method & path | Access | Notes |
|---|---|---|
| `GET /utils/currency` | public | `{ code: "USD", rate }` |
| `GET /utils/nearby-places` | public | `[label, ...]` |
