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
| `GET /agents` | public | agents directory (role=AGENT) + `adsCount` |
| `GET /agents/:id` | public | public agent profile + `adsCount` + `dealsClosedCount` |
| `PATCH /users/me` | any | own profile: fullName, phoneNumber, avatarUrl, password (re-hash), tgChatIds (agent) |
| `GET /auth/instagram/connect` | agent | 302 → Meta OAuth authorize URL; replaces the manual-token-paste flow — see `09-instagram-onboarding.md` §1 |
| `GET /auth/instagram/callback` | public (Meta calls this) | code/token exchange, upserts `agent_ig_tokens`, 302 back to `/settings` |
| `DELETE /auth/instagram/:igUserId` | agent (own) | disconnect a connected IG account |

`GET /agents/:id` backs the "Agent · N listings · M closed" row under a listing
(mockups/SCREENS.md §4.3). `adsCount` counts AD_CREATED activity events, the
same measure the directory uses; `dealsClosedCount` counts the agent's ads at
stage SOLD. The list endpoint deliberately does not carry `dealsClosedCount` —
nothing in the directory renders it. Both 404 for an id that is a real user but
not an AGENT.

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
| `GET /ads` | public | active (stage=ACTIVE) ads; filters: `city, district, category, type, rooms, repairment, storey, furniture, minArea, maxArea, minPrice, maxPrice`; pagination `page,limit` |
| `GET /ads/:id` | public | includes photos + public agent card |
| `GET /my/ads` | agent/coworker | own listings, same filters + `stage`, `sort` |
| `GET /my/ads/stage-counts` | agent/coworker | `{ active, sold, draft }` for tabs |
| `POST /ads` | agent/coworker | full ad payload + `photos: [{url, objectKey}]`; logs AD_CREATED |
| `PATCH /ads/:id` | agent/coworker (own) | stage transitions log AD_SOLD / AD_DRAFT_UPDATED |
| `DELETE /ads/:id` | agent (own) | also deletes MinIO objects |

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

## Statistics (dashboard)

| Method & path | Notes |
|---|---|
| `GET /statistics/ads?from&to&bucket=day\|week\|month` | created/sold counts per bucket (replaces client-side `useStatisticsStore` math) |
| `GET /statistics/coworkers` | per-coworker ad/lead counts |

## Uploads (MinIO)

| Method & path | Access | Notes |
|---|---|---|
| `POST /uploads/presign` | any authed | `{ fileName, contentType, scope: "ads"\|"avatars" }` → `{ uploadUrl, publicUrl, objectKey }`; presigned PUT, 10-min expiry |

## Publishing & contact (server-held secrets)

| Method & path | Access | Notes |
|---|---|---|
| `POST /publish/telegram` | agent/coworker | `{ adId, chatIds[] }` → sendMediaGroup from server bot token |
| `POST /publish/instagram` | agent/coworker | `{ adId }` → carousel publish using stored agent tokens |
| `POST /publish/instagram/caption` | agent/coworker | `{ adId }` → `{ caption }`; LLM-generated caption for the extension-assisted fallback, no publish — see `09-instagram-onboarding.md` §2 |
| `POST /publish/instagram/caption/confirm` | agent/coworker | `{ adId, event }` → human self-reports the extension-assisted post as published/aborted |
| `POST /publish/olx/map-fields` | agent/coworker | `{ adId, step, snapshot }` → LLM field-map for the extension to execute — see `07-olx-crosspost-extension.md` |
| `POST /publish/olx/confirm` | agent/coworker | `{ adId, event }` → extension callback recording draft/publish/failure |
| `GET /ads/:id/publish-status` | agent/coworker (own) | per-channel publish status grid — see `08-publish-tracking.md` |
| `POST /contact` | public, rate-limited | `{ name, phone, message }` → relayed to the office TG channel |

## Utils

| Method & path | Access | Notes |
|---|---|---|
| `GET /utils/currency` | public | `{ code: "USD", rate }` |
| `GET /utils/nearby-places` | public | `[label, ...]` |
