# Data Model — Firestore → PostgreSQL

Authoritative schema lives in `server/prisma/schema.prisma`; this doc explains
the mapping decisions.

## Conventions

- Primary keys: `uuid` (Firestore doc ids were opaque strings anyway).
- All timestamps `timestamptz`, `created_at`/`updated_at` on every table.
- Enums for every closed value set (Firestore stored them as free strings).
- Numeric fields are real numbers (Firestore holds mixed `"3"`/`3` — the API
  validates and coerces on write).

## Tables

### `users`  ← Firestore `users` + Firebase Auth

| Column | Type | From | Notes |
|---|---|---|---|
| id | uuid PK | doc id / auth uid | |
| full_name | text | fullName | |
| email | citext UNIQUE | email | |
| password_hash | text | — | bcrypt; replaces plaintext `password` + Firebase Auth |
| role | enum `user_role` (USER, AGENT, COWORKER) | role | |
| phone_number | text? | phoneNumber | |
| avatar_url | text? | avatar | MinIO public URL |
| agent_id | uuid? FK→users | agentId | self-reference; set only for coworkers |
| tg_chat_ids | bigint[] | tgChatIds | agent's connected TG channels |
| realtor_kind | enum `realtor_kind` (SOLO, AGENCY)? | — | null for buyers; set from the sign-up choice |
| realtor_status | enum `realtor_status` (NONE, PENDING, APPROVED, REJECTED) | — | an application, not a permission — `role` still decides what the account can do |
| agency_name | text? | — | agency only; shown in place of the agent's own name on the team's listings |
| office_phone | text? | — | agency only; same `+998` rule as `phone_number` |
| team_size | enum `team_size` (JUST_ME, TWO_TO_FIVE, SIX_TO_FIFTEEN, SIXTEEN_PLUS)? | — | agency only; self-reported at sign-up |
| realtor_applied_at / realtor_decided_at | timestamptz? | — | when the application was made, and when it was approved/rejected |
| created_at / updated_at | timestamptz | — | |

**Realtor sign-up** (`20260803120000_realtor_kind`, mockups/SCREENS.md §13). Choosing
*Realtor* at registration writes `realtor_kind` + `realtor_status = PENDING` and leaves
`role = USER`, so the workspace stays shut until the application is approved — approving
is what sets `role = AGENT` and `realtor_decided_at`. There is no self-serve approval
route yet; it replaces the Google Form with a row someone reviews. Agents that predate
the split were backfilled to `AGENCY` / `APPROVED`, since they have always been able to
add coworkers — the API refuses coworker creation only for an explicit `SOLO`.

`igTokens[]` moves out of the user document into its own table so tokens are
never sent to clients:

### `agent_ig_tokens`  ← `users.igTokens[]`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| agent_id | uuid FK→users | |
| access_token | text | server-only; excluded from all API responses |
| created_at | timestamptz | |

### `ads`  ← Firestore `ads`

| Column | Type | From | Notes |
|---|---|---|---|
| id | uuid PK | doc id | |
| title | text | title | |
| city | text | city | values come from `@lacasa/domain/data/regions` |
| district | text | district | |
| address | text? | address | |
| reference | text? | reference | landmark |
| type | enum `ad_type` (RESIDENTIAL, NONRESIDENTIAL) | type | |
| category | enum `ad_category` (RENT, SALE) | category | |
| repairment | enum `repairment` (NOT_REPAIRED, NORMAL, GOOD, EXCELLENT)? | repairment | |
| rooms | int? | rooms | |
| area | numeric(10,2)? | area | m² |
| storey | int? | storey | floor of the unit |
| floors | int? | floors | floors in building |
| furniture | enum `furniture` (WITH, WITHOUT)? | furniture | |
| hashtags | text? | hashtags | |
| price | numeric(14,2) | price | |
| price_type | enum `currency_code` (UZS, USD) | priceType | |
| stage | enum `ad_stage` (ACTIVE, SOLD, DRAFT) | stage `"1"/"2"/"3"` | |
| description | text? | description | |
| near_places | text[] | nearPlacesList | |
| options | jsonb | optionList | `[{id,key,value}]`, free-form form extras |
| active | boolean | active | |
| agent_id | uuid FK→users | agentId | |
| coworker_id | uuid? FK→users | coworkerId | |
| created_at / updated_at | timestamptz | serverTimestamp | |

### `ad_photos`  ← `ads.photos[]` (Storage URLs)

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| ad_id | uuid FK→ads ON DELETE CASCADE | |
| object_key | text | MinIO key `ads/{uuid}-{name}` |
| url | text | public URL (what the UI renders) |
| position | int | carousel order |

### `leads`  ← Firestore `leads`

| Column | Type | From |
|---|---|---|
| id | uuid PK | doc id |
| full_name | text | fullName |
| phone | text | phone |
| email | text? | email |
| budget | numeric(14,2)? | budget |
| comment | text? | comment |
| conversation_comment | text? | conversationComment |
| status | enum `lead_status` (NEW, COULD_NOT_CONNECT, NEED_TO_CALL_BACK, REJECTED, ACCEPTED) | status |
| source | text? | source |
| callback_date | timestamptz? | callbackDate |
| active | boolean | active |
| agent_id | uuid FK→users | agentId |
| coworker_id | uuid? FK→users | coworkerId |
| created_at / updated_at | timestamptz | — |

### `activity_events`  ← Firestore `statistics`

The overloaded `stage` int becomes a named enum:

| Firestore `stage` | enum `event_type` |
|---|---|
| 1 | AD_CREATED |
| 2 | AD_SOLD |
| 3 | AD_DRAFT_UPDATED |
| 4 | LEAD_CREATED |
| 5 | LEAD_STATUS_CHANGED |

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | |
| type | enum `event_type` | |
| agent_id | uuid FK→users | |
| coworker_id | uuid? FK→users | |
| ad_id | uuid? FK→ads | old `postId` |
| lead_id | uuid? FK→leads | |
| meta | jsonb? | old secondary `type` field (1=edit, 2=social post) |
| created_at | timestamptz | indexed with agent_id for time-bucketed dashboards |

### `currency_rates`  ← Firestore `currency`

| Column | Type | Notes |
|---|---|---|
| id | uuid PK | in practice one row (USD→UZS) |
| code | enum `currency_code` UNIQUE | USD |
| rate | numeric(14,2) | e.g. 12900 |
| updated_at | timestamptz | |

### `nearby_place_options`  ← Firestore `nearbyList`

| Column | Type |
|---|---|
| id | uuid PK |
| label | text UNIQUE |
| position | int |

## Indexes

- `ads (agent_id, stage)`, `ads (stage, active)` — the two hot query shapes.
- `leads (agent_id)`, `leads (coworker_id)`.
- `activity_events (agent_id, created_at)`, `activity_events (type)`.
- `users (agent_id)` — coworker lookup; `users (role)` — agents directory.

## Reference data

Cities/districts (14 regions, 203 districts) stay bundled JSON rather than
tables — the data is static and only feeds dropdowns. It lives in
`packages/domain/src/data/regions.json`, imported as
`@lacasa/domain/data/regions`, so apps/web and apps/mobile share one copy
instead of each carrying their own (docs/10 §5 Decision 2/3). No API route:
nothing about it changes at runtime.

Promote to `regions`/`districts` tables later if server-side filter validation
is wanted — `Ad.city`/`Ad.district` are still free text on write.

Seed data (`server/prisma/seed.js`): one currency rate row, the default
nearby-place labels, and a dev agent account.
