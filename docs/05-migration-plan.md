# Migration Plan — Firebase → Postgres + MinIO

Fresh-start migration (no production data ETL, per decision 2026-07-30).
Each phase leaves the app in a working state; Firebase is removed only at the end.

**Status as of 2026-08-07.** Firebase is gone from the codebase and the monorepo
restructure is merged to `main`. The social-publishing tail (Phase E) is now
code-complete server-side; what remains is a human action — rotating the
leaked Telegram bot token (E.4) — and the pending Meta App Review (E.7).

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

## Phase E — Social publishing server-side — **DONE except rotation (E.4) and Meta App Review (E.7)**

| # | Item | Status |
|---|---|---|
| 1a | `POST /publish/instagram` | **done** |
| 1b | `POST /publish/telegram` | **done** — `apps/api/src/routes/publish.js`, `apps/api/src/lib/telegram.js` |
| 1c | `POST /contact` | **done** — `apps/api/src/routes/contact.js`, mounted at `/api/contact` in `app.js` |
| 2 | IG tokens in `agent_ig_tokens`, stripped from client state | **done** |
| 3 | Replace direct TG/IG calls in the client | **done** — IG and TG both go through the server now |
| 4 | **Rotate the leaked Telegram bot token and IG tokens** | **NOT DONE** — human action in BotFather, out of scope for the code changes below |
| 5 | `AdPublication` model + upsert from the publish handlers | **done** (`publishService.js`) |
| 6 | `POST /publish/youtube` status report-back | **done** — `apps/api/src/routes/publish.js`, `apps/web/src/services/yt.ts` calls it after the upload settles |
| 7 | Instagram OAuth connect flow + daily refresh job | **done** (`instagramAuth.js`: `/connect-url`, `/callback`, `DELETE /:igUserId`) |

### E.1b / E.3 / E.4 — the live secret

Telegram publishing now runs server-side:

- `apps/api/src/lib/telegram.js` wraps the Bot API (`sendMediaGroup`,
  `sendMessage`) using `config.TG_BOT_TOKEN`, read only on the server.
  `apps/api/src/services/publishService.js`'s `publishTelegramDirect`
  enforces that the caller only targets chat ids in their own
  `User.tgChatIds` and degrades to a `503 tg_unconfigured` (recording a
  `FAILED` `AdPublication` row first) if the token is unset.
- `apps/web/src/services/tg.ts` no longer builds an axios client against
  `api.telegram.org` at all — `TGService.publish()` posts to
  `POST /api/publish/telegram` instead. `AdsAdd.tsx` and `AdsEdit.tsx`
  publish through it.
- `apps/web/src/routes/aboutPageNew/components/ContactUs.jsx`'s hardcoded
  bot-token literal is gone; it now calls `POST /api/contact`
  (`apps/api/src/routes/contact.js`, rate-limited 5/min per IP). The same
  hardcoded-token bug was found independently in
  `apps/web/src/components/footer/Footer.jsx` and fixed identically.
- Lost in the move: per-channel Telegram enrichment (channel title,
  `@username`, avatar, member count) required the bot token client-side via
  `getChat`/`getChatMembersCount`/`getFile`, which has no server
  equivalent today. `TgProfileCard.tsx` and the inline TG preview cards in
  `AdsAdd`/`AdsEdit` now show an honest "unavailable" state for those
  fields instead of fabricating them; the "copy shareable post link"
  feature (needs `username`) degrades the same way. A
  `GET /publish/telegram/accounts` endpoint was not built — nothing to
  reach except the bot's per-chat data, and this app never had a bot-admin
  credential for that beyond the same `TG_BOT_TOKEN`.

Rotation (E.4) is still a human action in BotFather — the current token must
be considered burned regardless of what the code does; nothing in this repo
can perform that step.

### E.6 — YouTube

`apps/web/src/services/yt.ts` still does the full resumable upload from the
browser under the user's own OAuth (unchanged, and intentionally so — it's
the user's own quota), but now reports the outcome to
`POST /api/publish/youtube` after the upload settles or fails, so `YOUTUBE`
shows up in `AdPublication`/the status grid. The report-back call swallows
its own errors so a failed report can't mask the upload result the user
already saw.

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
3. [x] Purge `VITE_TG_BOT_TOKEN` from `apps/web/.env` — unblocked by E.1b. The
       remaining client env surface is `VITE_API_URL`, `VITE_YT_CLIEND_ID`
       (sic — the typo is in the code), `VITE_YT_TOKEN`; see
       `apps/web/.env.example`.
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
  only surface that can create an ad; no longer holds the TG token (Phase E).

## Risks / notes

- **Secrets leaked in git history** (bot token, API keys in a committed `.env`).
  Rotation matters more than deletion — the code no longer needs the old
  Telegram token (Phase E.1b/E.3), but the leaked token itself has not been
  rotated yet (Phase E.4) and must still be considered burned.
- Firestore's implicit "no schema" hid mixed types; the API's zod validation
  surfaces bad form inputs early — expected, not a regression.
- YT publishing keeps using the user's own browser OAuth for now.
- i18n keys, routing, and component structure were intentionally left alone —
  only the data layer changed.
