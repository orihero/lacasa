# Migration Plan — Firebase → Postgres + MinIO

Fresh-start migration (no production data ETL, per decision 2026-07-30).
Each phase leaves the app in a working state; Firebase is removed only at the end.

**Status as of 2026-08-07.** Firebase is gone from the codebase and the monorepo
restructure is merged to `main`. What remains is not the data migration — it is
the social-publishing tail (Phase E) and the secrets that tail still leaks.

> Paths changed on 2026-07-31: the old `server/` is now `apps/api/`, the SPA is
> `apps/web/`, and the repo is an npm-workspaces monorepo (`apps/*`,
> `packages/*`). Earlier revisions of this doc used the pre-monorepo paths.

## Phase A — Infrastructure — **done**

- [x] `docker-compose.yml`: Postgres 16 + MinIO + bucket bootstrap (CI-only; the
      dev machine runs both natively via scoop).
- [x] `apps/api/` scaffold: Express app, Prisma schema, seed script, env template.
- [x] Schema migrated and seeded.

## Phase B — Auth — **done**

1. [x] `/auth/register`, `/auth/login`, `/auth/me` (bcrypt + JWT).
2. [x] `apps/web/src/lib/api.js` (axios + token interceptor, token in localStorage).
3. [x] `login.jsx`, `register.jsx`, `layout.jsx`, `userStore.js` rewritten off
       `onAuthStateChanged`.
4. [x] Sign-up declares buyer / solo realtor / agency (`RealtorKind`,
       `RealtorStatus`, `TeamSize`).

Verified: register → login → `/auth/me` round-trip, wrong-password and
missing-token rejection (401).

## Phase C — Core data (ads, utils, uploads) — **done**

1. [x] Ads endpoints + zod validation; `/api/ads`, `/api/my/ads`,
       `/api/my/ads/stage-counts`.
2. [x] `POST /api/uploads/presign` → PUT to MinIO; `assetUpload.js` rewritten
       behind the same signature.
3. [x] `adsListStore.js` / `utilsStore.js` rewritten; `AdsAdd` / `AdsEdit` updated.
4. [x] Legacy `/post` route (`newPostPage`) deleted.
5. [x] Later additions: `Ad.lat`/`lng`, `AdPhoto.mediaType`, `Ad.tour3dLink`
       (absolute http(s) only), `computePricePerSqm` in `@lacasa/domain`.

## Phase D — CRM (leads, coworkers, statistics) — **done**

1. [x] `/api/leads`, `/api/coworkers`, `/api/statistics`, `/api/agents`,
       `/api/saved-ads` endpoints.
2. [x] `useLeadStore`, `useCoworkerStore`, `useStatisticsStore`, `agentsStore`
       rewritten; kanban, `CoworkerAdd` (second-Firebase-app hack gone), `Chart`
       updated.

## Phase E — Social publishing server-side — **PARTIALLY DONE, and the blocker**

| # | Item | Status |
|---|---|---|
| 1a | `POST /publish/instagram` | **done** |
| 1b | `POST /publish/telegram` | **NOT DONE** — see below |
| 1c | `POST /contact` | **NOT DONE** — `apps/api/src/app.js:73` still carries the TODO |
| 2 | IG tokens in `agent_ig_tokens`, stripped from client state | **done** |
| 3 | Replace direct TG/IG calls in the client | **IG done, TG not** |
| 4 | **Rotate the leaked Telegram bot token and IG tokens** | **NOT DONE** |
| 5 | `AdPublication` model + upsert from the publish handlers | **done** (`publishService.js`) |
| 6 | `POST /publish/youtube` status report-back | **NOT DONE** |
| 7 | Instagram OAuth connect flow + daily refresh job | **done** (`instagramAuth.js`: `/connect-url`, `/callback`, `DELETE /:igUserId`) |

### E.1b / E.3 / E.4 — the live secret

Telegram publishing never moved server-side. It still runs in the browser:

- `apps/web/src/services/tg.ts:12-17` builds an axios client against
  `https://api.telegram.org/bot${import.meta.env.VITE_TG_BOT_TOKEN}`, so the bot
  token is compiled into the public JS bundle and readable by anyone who loads
  the site. `AdsAdd.tsx:312` and `AdsEdit.tsx:292` publish through it.
- `apps/web/src/routes/aboutPageNew/components/ContactUs.jsx:32` is worse — the
  token is **hardcoded as a string literal in source**, not even an env var, and
  is committed to git history.

Rotation (E.4) is the urgent half and is a human action in BotFather — the
current token must be considered burned regardless of what the code does next.
The code half is E.1b + E.1c: a server-side `POST /publish/telegram` and
`POST /contact` holding the token in `apps/api` env, with `tg.ts` and
`ContactUs.jsx` calling those instead.

### E.6 — YouTube

`apps/web/src/services/yt.ts` still does the full resumable upload from the
browser under the user's own OAuth, and reports nothing back, so YouTube never
appears in `AdPublication`. Keeping the upload client-side is fine (the user's
own quota); the missing piece is the status report-back endpoint.

### E.7 — Meta App Review

The OAuth code is done; **the Meta App Review submission is the long pole and is
still outstanding**. See `09-instagram-onboarding.md` §1. Real IG publishing does
not work for other agents' accounts until it clears, and the console's Connected
Accounts screen should say so rather than implying it works.

## Phase F — Extension-assisted publishing — **done**

1. [x] `POST /publish/:channel/map-fields` + `POST /publish/:channel/confirm`
       (generic over channel, covers OLX).
2. [x] `apps/extension/`: `olx-autofill.ts`, `dom-snapshot.ts`, `dom-executor.ts`,
       `lacasa-bridge.ts`, review banner. Fills the DOM, waits for a human click
       on OLX's own Publish button.
3. [x] `GET /publish/ads/:adId/status` + `GET /publish/status`. Surfaced in
       `apps/console` (Publish status screen). **Not surfaced in `apps/web`** —
       intentional, the console is the agent-facing surface now.
4. [x] `instagram-autofill.ts` caption-assist fallback + `POST /publish/instagram/consent`.

## Phase G — Cleanup — **mostly done**

1. [x] `firebase` dependency, `src/lib/firebase.js` and the Firebase env vars are
       gone — no Firebase reference remains anywhere in `apps/web/src`.
2. [x] `instagram-graph-api` and `googleapis` removed; `gapi-script` kept (it is
       the one actually used, by the client-side YT OAuth).
3. [ ] Purge `VITE_TG_BOT_TOKEN` from `apps/web/.env` — **blocked on E.1b**. The
       remaining client env surface is `VITE_API_URL`, `VITE_TG_BOT_TOKEN`,
       `VITE_YT_CLIEND_ID` (sic — the typo is in the code), `VITE_YT_TOKEN`.
4. [ ] Hosting: the SPA now needs the API deployed alongside it. `vercel.json`
       still describes the old SPA-only deploy. Out of scope for the local-dev
       milestone, but it is the thing standing between `main` and a real deploy.

## Phase H (backlog, not scheduled) — Realting.uz feed sync

Passive batch sync via a generated XML/YML feed, not a per-ad click. Needs its
own design pass (field-mapping to Realting's schema, feed hosting, cron
cadence) before it becomes a real phase. The `REALTING` value is reserved in
`PublishChannel` today (see `06-cross-posting.md` §4) so this doesn't require
a second migration once it starts.

## Beyond the migration — the surfaces that grew out of it

Not part of the Firebase migration, but tracked here because they share the
backend and are the active work:

- **`apps/console`** — the Direction F agent console (`mockups/f/PLAN.md`).
- **`apps/mobile_flutter`** — the Flutter client. The API layer and the home,
  listing and saved features exist; the rest of `mockups/SCREENS.md` (search,
  agents, the whole Work/CRM tab, auth, profile) does not. The Expo prototype
  that used to live at `apps/mobile` was deleted on 2026-08-07 in favor of it.
- **`apps/web`** — public marketplace + the legacy realtor dashboard. Still the
  only surface that can create an ad, and still the one holding the TG token.

## Risks / notes

- **Secrets leaked in git history** (bot token, API keys in a committed `.env`).
  Rotation matters more than deletion — and the Telegram token is not merely
  historical, it is still live in `main` today (Phase E.4).
- Firestore's implicit "no schema" hid mixed types; the API's zod validation
  surfaces bad form inputs early — expected, not a regression.
- YT publishing keeps using the user's own browser OAuth for now.
- i18n keys, routing, and component structure were intentionally left alone —
  only the data layer changed.
