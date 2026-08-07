# Publish Tracking — unified cross-channel publication status

> Detail doc for `06-cross-posting.md` §4. Read that doc first for the
> cross-channel overview; this is the full data-model/API spec it summarizes,
> with worked JSON examples and the exact migration-plan diff.

Design doc for a single data model + API surface covering every publish
channel: Telegram, Instagram, YouTube, the new OLX extension-assisted flow,
and the future Realting.uz feed. Builds on Phase E of
`docs/05-migration-plan.md`; see §3 for how it slots into the phase plan.

## 1. Why one model for four very different flows

| Channel | Trigger | Who does the actual publish click | "Done" means |
|---|---|---|---|
| Telegram | `POST /publish/telegram` | server (bot token) | message sent, ids returned |
| Instagram | `POST /publish/instagram` | server (stored agent IG token) | carousel container published |
| YouTube | client-side OAuth upload (unchanged) | browser, user's own Google session | video id exists, but server never saw it happen — needs a report-back call |
| OLX | extension fills the real OLX form | **a human**, in their own logged-in tab | form is drafted; publish is a human act, not an API call |
| Realting (future) | scheduled feed generation | Realting's crawler pulls the feed | ad appears in the generated XML/YML — a batch sync, not a per-ad click |

Despite the different mechanics, the dashboard needs one answer to "is this
ad live on channel X": a single `AdPublication` row per `(ad, channel)`,
upserted by whichever flow is responsible for that channel, is enough to
drive both the status grid and future retry/alerting logic.

## 2. Prisma model

Add to `server/prisma/schema.prisma`, following the existing
snake_case/`@map`/`@db.Uuid`/`@@index` conventions:

```prisma
enum PublishChannel {
  TELEGRAM
  INSTAGRAM
  YOUTUBE
  OLX
  REALTING
}

enum PublishStatus {
  PENDING                  // never attempted, or reset
  DRAFTED_AWAITING_REVIEW  // OLX only today: form filled, human hasn't clicked Publish yet
  PUBLISHED
  FAILED
}

model AdPublication {
  id      String         @id @default(uuid()) @db.Uuid
  adId    String         @map("ad_id") @db.Uuid
  ad      Ad             @relation(fields: [adId], references: [id], onDelete: Cascade)
  channel PublishChannel
  status  PublishStatus  @default(PENDING)

  externalId  String? @map("external_id")  // TG message_id, IG media id, YT video id, OLX ad id
  externalUrl String? @map("external_url") // https://t.me/..., https://instagram.com/p/..., https://youtu.be/..., https://olx.uz/...

  // Free-form audit payload: TG chatIds used, IG creation-container id,
  // the OLX field-map the LLM produced, the Realting feed row, etc.
  payload Json? @default("{}")

  attempts      Int       @default(0)
  lastAttemptAt DateTime? @map("last_attempt_at") @db.Timestamptz()
  publishedAt   DateTime? @map("published_at") @db.Timestamptz()
  errorMessage  String?   @map("error_message")

  // Who triggered this attempt — null for system/cron-driven channels (Realting).
  requestedById String? @map("requested_by_id") @db.Uuid
  requestedBy   User?   @relation("PublicationRequestedBy", fields: [requestedById], references: [id], onDelete: SetNull)

  createdAt DateTime @default(now()) @map("created_at") @db.Timestamptz()
  updatedAt DateTime @updatedAt @map("updated_at") @db.Timestamptz()

  @@unique([adId, channel])
  @@index([channel, status])
  @@map("ad_publications")
}
```

Wire up the two back-relations:

```prisma
model Ad {
  // ...existing fields...
  publications AdPublication[]
  // ...
}

model User {
  // ...existing fields...
  publicationRequests AdPublication[] @relation("PublicationRequestedBy")
  // ...
}
```

Notes on the design choices:

- **`@@unique([adId, channel])`** — one row per ad per channel, upserted on
  every attempt. This is what makes the status grid a single `findMany`
  instead of "latest row per group" gymnastics. `attempts`/`lastAttemptAt`
  keep a lightweight retry trail without a separate history table; if a full
  audit log is ever needed, `ActivityEvent` already exists for that (an
  `AD_PUBLISHED`/`AD_PUBLISH_FAILED` `EventType` could be added there too,
  mirroring how `AD_SOLD` etc. work today — out of scope here but a natural
  follow-up).
- **`payload Json?`** carries whatever is channel-specific instead of adding
  five sets of nullable channel-specific columns: TG `chatIds` used, IG
  container id mid-publish, the OLX LLM field-map for debugging/replay, the
  Realting feed generation batch id. For `INSTAGRAM` specifically,
  `payload.mechanism` is `"graph-api"` or `"extension-assisted"` — Instagram
  is the one channel with two publish mechanisms (`09-instagram-onboarding.md`),
  and the status grid should surface which one produced a given row.
- **`DRAFTED_AWAITING_REVIEW`** exists because OLX is fundamentally
  human-gated, and now also applies to Instagram's extension-assisted path
  (caption filled, agent hasn't self-reported publishing yet); every
  API-driven channel goes `PENDING → PUBLISHED|FAILED` directly. Modeling it
  as a status value (not a separate boolean) keeps the grid a single enum
  switch in the UI.
- **`requestedById` is nullable with `SetNull`** — Realting rows are written
  by a cron job with no acting user; TG/IG/OLX rows are written by the
  agent/coworker who clicked publish (same pattern as `Ad.coworkerId`).

## 3. Reconciling with the migration plan: Phase E extension + new Phase F

Recommendation: **split it.**

- **Phase E (extend, don't fork)** — add the `AdPublication` model itself,
  wire it into the *existing* `/publish/telegram` and `/publish/instagram`
  handlers (they already exist in scope; they just need to upsert a row
  after their API call succeeds/fails), and add the YouTube status
  report-back endpoint. This is the same "server holds publish state, secrets
  stay server-side" theme Phase E is already about — no new moving parts, no
  new infra, no new external dependency. Bolting it onto Phase E as items
  E.5–E.6 is lower-risk than inventing a new phase for it.
- **New Phase F — OLX extension-assisted publishing.** This introduces a
  genuinely new artifact (a browser extension), a new external dependency
  (an LLM API call), and a new interaction model (human-in-the-loop, review
  before publish) that nothing else in the plan touches. It deserves its own
  phase gate rather than being squeezed into Phase E's "just call the API"
  framing — it has its own risks (DOM breakage on OLX's side, LLM
  hallucinating a field mapping, extension permissions/distribution) that
  should be reviewed independently before shipping.
- **Renumber the existing Phase F ("Cleanup") to Phase G.** It doesn't
  depend on OLX work and can still run in parallel/after, just shifted down
  numerically so "Phase F" consistently means the OLX work going forward.
- **Realting.uz is not a phase yet** — flag it as a backlog item ("Phase H —
  Realting feed sync", batch/passive, no per-click UI) and reserve the enum
  value now (`REALTING` in `PublishChannel`) purely so the eventual feed
  worker doesn't require another migration to add a channel. No routes for
  it are being built in this doc.

Suggested edit to `docs/05-migration-plan.md` (already applied — shown here
for the reasoning trail):

```diff
 ## Phase E — Social publishing server-side

 1. `/publish/telegram`, `/publish/instagram`, `/contact` endpoints.
 2. Move IG tokens to `agent_ig_tokens`; strip token fields from client state.
 3. Replace direct TG/IG calls in `AdsAdd`/`AdsEdit`/`ContactUs` with API calls;
    delete the hardcoded bot token from `ContactUs.jsx`.
 4. **Rotate the Telegram bot token and IG tokens** — the current ones are
    committed to git history and must be considered burned.
+5. Add `AdPublication` model + migration; upsert a row from the TG/IG
+   handlers on success/failure.
+6. `POST /publish/youtube` status report-back endpoint; call it from
+   `src/services/yt.ts` after the resumable upload resolves/fails.
+
+## Phase F — OLX extension-assisted publishing
+
+1. `POST /publish/olx/map-fields` (LLM field-mapping) and
+   `POST /publish/olx/confirm` (extension callback) endpoints — see
+   docs/08-publish-tracking.md.
+2. Browser extension: reads the Ad via the existing authed API, opens the
+   agent's own logged-in OLX tab, calls `/publish/olx/map-fields`, fills the
+   DOM, waits for a human click on OLX's own Publish button.
+3. Per-ad publish-status grid in the dashboard (`GET /ads/:id/publish-status`).

-## Phase F — Cleanup
+## Phase G — Cleanup

 1. Remove `firebase` dependency, `src/lib/firebase.js`, Firebase env vars.
 2. Remove unused deps: `instagram-graph-api`, `googleapis` (only `gapi-script`
    is used).
 3. Purge `VITE_TG_BOT_TOKEN` etc. from `.env`; keep only `VITE_API_URL`
    (+ YT client-side OAuth vars until YT publishing moves server-side).
 4. Update Vercel setup or move hosting; the SPA now needs the API deployed
    alongside it (out of scope for local-dev milestone).
+
+## Phase H (backlog, not scheduled) — Realting.uz feed sync
+
+Passive batch sync via generated XML/YML feed, not a per-ad click. Needs its
+own design pass (field-mapping to Realting's schema, feed hosting, cron
+cadence) before it becomes a real phase.
```

## 4. API additions

Same table format as `docs/04-api-spec.md`; add a new section replacing the
current one-line `Publishing & contact` entries for TG/IG (they gain a
"Notes" clarification, no signature change) plus the new endpoints.

### Publishing & contact (server-held secrets)

| Method & path | Access | Body / params | Returns | Notes |
|---|---|---|---|---|
| `POST /publish/telegram` | agent/coworker | `{ adId, caption, imageUrls[], chatIds[] }` | `{ publication, results: [{chatId, ok, messageId?, error?}] }` | sendMediaGroup from server bot token; `chatIds` filtered against the caller's own `User.tgChatIds` (`400 no_connected_accounts` if none match); upserts `AdPublication(channel=TELEGRAM)`; `503 tg_unconfigured` if `TG_BOT_TOKEN` is unset (still records a `FAILED` row first) |
| `POST /publish/instagram` | agent/coworker | `{ adId }` | `{ publication }` | carousel publish via stored agent IG token; upserts `AdPublication(channel=INSTAGRAM)` |
| `POST /publish/youtube` | agent/coworker | `{ adId, status: "PUBLISHED"\|"FAILED", externalId?, externalUrl?, errorMessage? }` | `{ publication }` | **report-back only** — server never calls YouTube; the browser does the OAuth upload itself (per plan) and reports the outcome here so the status grid has something to show |
| `POST /publish/olx/map-fields` | agent/coworker | `{ adId, step: "category"\|"details"\|"photos"\|"price-location", snapshot: (FieldNode\|CategoryStepNode)[] }` | `{ categoryClick?, fields: FieldAction[], unresolved: UnresolvedField[], confidence }` | see §5 — does not publish anything; one call per form step, returns instructions for the extension to execute. Upserts `AdPublication(channel=OLX, status=PENDING)`, `attempts += 1`, `payload` set for audit. The first call per session (`step: "category"`) also drives the per-agent daily rate limit — see `07-olx-crosspost-extension.md` §7 |
| `POST /publish/olx/confirm` | agent/coworker | `{ adId, event: "drafted"\|"published"\|"failed"\|"aborted"\|"dom-drift", externalId?, externalUrl?, errorMessage? }` | `{ publication }` | extension callback: `drafted` once after filling the form (`DRAFTED_AWAITING_REVIEW`), `published`/`failed` once it can detect the outcome of the human's own Publish click; `aborted`/`dom-drift` are audit-only and leave `status` unchanged |
| `GET /ads/:id/publish-status` | agent/coworker (own ad) | — | `{ adId, channels: [{ channel, status, externalUrl, externalId, lastAttemptAt, errorMessage }] }` | one row **per `PublishChannel` value**, defaulting unwritten channels to `{ status: "PENDING", externalUrl: null, ... }` — this is the per-listing status grid the UI needs |
| `GET /publish/status` | agent/coworker | `?adIds=uuid,uuid,...` | `{ [adId]: [{ channel, status }, ...] }` | bulk variant for the ads *list* view (badges per row) without N+1 calls to the endpoint above |
| `POST /contact` | public, rate-limited | `{ name, phone, message }` | — | unchanged, relayed to the office TG channel |

`publication` in responses is the serialized `AdPublication` row (id,
channel, status, externalId, externalUrl, lastAttemptAt, publishedAt,
errorMessage — never `payload` in the general case, since it may contain
verbose LLM output; expose `payload` only on the OLX endpoints where the
caller needs it).

`GET /ads/:id/publish-status` response shape, concretely, for an ad that's
live on Telegram, failed on Instagram, has an OLX draft awaiting review, and
hasn't touched YouTube or Realting:

```json
{
  "adId": "6e2b...",
  "channels": [
    { "channel": "TELEGRAM",  "status": "PUBLISHED",              "externalUrl": "https://t.me/c/123/45", "externalId": "45",  "lastAttemptAt": "2026-07-29T10:00:00Z", "errorMessage": null },
    { "channel": "INSTAGRAM", "status": "FAILED",                 "externalUrl": null,                    "externalId": null,  "lastAttemptAt": "2026-07-29T10:01:00Z", "errorMessage": "IG token expired" },
    { "channel": "YOUTUBE",   "status": "PENDING",                "externalUrl": null,                    "externalId": null,  "lastAttemptAt": null,                   "errorMessage": null },
    { "channel": "OLX",       "status": "DRAFTED_AWAITING_REVIEW","externalUrl": null,                    "externalId": null,  "lastAttemptAt": "2026-07-30T09:00:00Z", "errorMessage": null },
    { "channel": "REALTING",  "status": "PENDING",                "externalUrl": null,                    "externalId": null,  "lastAttemptAt": null,                   "errorMessage": null }
  ]
}
```

## 5. Where the OLX LLM call lives

**Server-side, in `POST /publish/olx/map-fields`** — not in the extension.
This is the same fix Phase E.4 is already making for the TG bot token and IG
tokens (`docs/01-current-architecture.md` Known Issue #2: "secrets ship in
the client bundle"). An LLM API key baked into a distributed browser
extension is just as burnable as a bot token in a Vite `.env` — anyone can
unpack the extension and read it.

Flow:

1. Extension runs inside the agent's already-authenticated browser (it holds
   the same JWT the dashboard uses — reuse `Authorization: Bearer` from the
   app's localStorage/cookie the extension has permission to read, or a
   short-lived token issued via a small `POST /auth/extension-token` if
   sharing the main JWT directly is undesirable — implementation detail, not
   blocking this doc).
2. Extension opens the agent's own logged-in OLX "post an ad" tab, scrapes
   the live DOM for the current step into a `snapshot` (field
   ids/names/labels/types/options — **not** full HTML, to keep the LLM prompt
   small and avoid shipping arbitrary page content through the API).
3. Extension calls `POST /publish/olx/map-fields { adId, step, snapshot }` —
   once per form step (category, details, photos, price/location; see
   `07-olx-crosspost-extension.md` §3), not once for the whole form.
4. Server: authenticates the caller, loads the `Ad` (authorizing that
   `adId` belongs to that agent/their coworker — same ownership check as
   every other `/publish/*` route), builds a prompt from the ad's structured
   fields + `snapshot`, calls the LLM with the server-held key
   (`process.env.LLM_API_KEY` / `ANTHROPIC_API_KEY`, same env-var pattern as
   `DATABASE_URL` — never sent to the client) under a strict JSON schema, gets
   back `{ categoryClick?, fields: FieldAction[], unresolved: UnresolvedField[] }`,
   upserts the `AdPublication` row (`attempts += 1`), and returns it.
5. Extension executes the field actions against the live DOM (fills inputs,
   selects options) via its content script. **It never clicks Publish.**
   Steps 2-5 repeat per form step until the whole form is filled.
6. A human reviews the filled OLX form in their own tab and clicks OLX's
   real Publish button themselves.
7. Extension calls `POST /publish/olx/confirm { adId, event: "drafted" }`
   once the form is fully filled, then `event: "published"`/`"failed"` once it can observe the
   outcome (e.g. the post-submit redirect containing OLX's own listing id/
   URL, or a "still on the form, assume abandoned" timeout →
   `DRAFTED_AWAITING_REVIEW` stays as the last known state rather than being
   force-closed).

This keeps the LLM key, the ad-ownership authorization check, and the audit
trail (`payload.fieldMap`, `attempts`, `lastAttemptAt`) all server-side and
centralized — the extension is a thin DOM executor with no secrets and no
business logic, which also makes it easy to review/reason about from a
browser-store-listing security standpoint.

## 6. Realting.uz (future, not built here)

Different shape entirely, noted so the schema doesn't need to change again
later: no per-ad endpoint. A scheduled worker walks all `stage=ACTIVE` ads,
generates the XML/YML feed at a stable public URL (e.g.
`GET /feeds/realting.xml`, public/unauthenticated — Realting's crawler pulls
it, nothing pushes to Realting), and upserts `AdPublication(channel=
REALTING)` per ad as it writes the feed: `PUBLISHED` once included, `FAILED`
per-row if an ad fails Realting's required-field validation (e.g. missing
`area`), with `errorMessage` holding the validation reason and `payload`
holding the feed generation batch id/timestamp. `requestedById` stays null
(cron-driven, no acting user). This is why `REALTING` is in the enum today
even though no route consumes it yet — reserving the value avoids a second
migration when Phase H actually starts.
