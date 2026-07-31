# API Specification (v1)

Base URL: `http://localhost:4200/api` (dev). All responses JSON.
Auth: `Authorization: Bearer <JWT>` unless marked **public**.

Errors: `{ "error": { "code": "string", "message": "string" } }` with proper
HTTP status (400 validation, 401 unauthenticated, 403 forbidden, 404 not found).

## Auth

| Method & path | Access | Body / params | Returns |
|---|---|---|---|
| `POST /auth/register` | public | `{ fullName, email, password }` | `{ token, user }` — role is always USER |
| `POST /auth/login` | public | `{ email, password }` | `{ token, user }` |
| `GET /auth/me` | any | — | `{ user }` (with resolved agent info for coworkers) |

`user` objects never include `password_hash` or IG tokens.

## Users / agents

| Method & path | Access | Notes |
|---|---|---|
| `GET /agents` | public | agents directory (role=AGENT) + `adsCount` |
| `GET /agents/:id` | public | public agent profile |
| `PATCH /users/me` | any | own profile: fullName, phoneNumber, avatarUrl, password (re-hash), tgChatIds (agent) |
| `GET /auth/instagram/connect` | agent | 302 → Meta OAuth authorize URL; replaces the manual-token-paste flow — see `09-instagram-onboarding.md` §1 |
| `GET /auth/instagram/callback` | public (Meta calls this) | code/token exchange, upserts `agent_ig_tokens`, 302 back to `/settings` |
| `DELETE /auth/instagram/:igUserId` | agent (own) | disconnect a connected IG account |

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
