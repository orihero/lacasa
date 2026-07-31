# Migration Plan — Firebase → Postgres + MinIO

Fresh-start migration (no production data ETL, per decision 2026-07-30).
Each phase leaves the app in a working state; Firebase is removed only at the end.

## Phase A — Infrastructure (done in this prep)

- [x] `docker-compose.yml`: Postgres 16 + MinIO + bucket bootstrap.
- [x] `server/` scaffold: Express app, Prisma schema, seed script, env template.
- [ ] `docker compose up -d`, `cd server && npm install && npx prisma migrate dev --name init && npm run seed`.

## Phase B — Auth (done)

1. [x] Implement `/auth/register`, `/auth/login`, `/auth/me` (bcrypt + JWT).
2. [x] Frontend: `src/lib/api.js` (axios + token interceptor, token in localStorage).
3. [x] Rewrite `login.jsx`, `register.jsx`, `layout.jsx` (`onAuthStateChanged` →
   `GET /auth/me` on mount), `userStore.js`.
4. [ ] Remove the plaintext `password` handling from remaining forms
   (`ProfileSetting.jsx`, `CoworkerAdd.jsx` still read/write it — deferred to
   Phase D since those forms are still Firestore-backed).

Verified: register → login → `/auth/me` round-trip, wrong-password and
missing-token rejection (401), seeded `agent@lacasa.dev` login resolves
`tgChatIds`/`igTokens` via the agent lookup. `userStore.fetchUserById`
(public agent profile) intentionally still reads Firestore — it moves in
Phase D alongside the agents directory endpoint.

## Phase C — Core data (ads, utils, uploads)

1. Ads endpoints + validation (coerce numerics, enum-map `stage`).
2. Presigned-upload endpoint; rewrite `src/lib/assetUpload.js` to
   presign → PUT to MinIO (same function signature, so callers don't change).
3. Rewrite `adsListStore.js`, `utilsStore.js`; update `AdsAdd`/`AdsEdit`.
4. Delete legacy `/post` route (`newPostPage`) — superseded by `AdsAdd`.

## Phase D — CRM (leads, coworkers, statistics)

1. Leads + coworkers + statistics endpoints.
2. Rewrite `useLeadStore`, `useCoworkerStore`, `useStatisticsStore`,
   `agentsStore`; update kanban, `CoworkerAdd` (drop second-Firebase-app hack),
   `Chart`.

## Phase E — Social publishing server-side

1. `/publish/telegram`, `/publish/instagram`, `/contact` endpoints.
2. Move IG tokens to `agent_ig_tokens`; strip token fields from client state.
3. Replace direct TG/IG calls in `AdsAdd`/`AdsEdit`/`ContactUs` with API calls;
   delete the hardcoded bot token from `ContactUs.jsx`.
4. **Rotate the Telegram bot token and IG tokens** — the current ones are
   committed to git history and must be considered burned.
5. Add the `AdPublication` model + migration; upsert a row from the TG/IG
   handlers on success/failure (see `06-cross-posting.md` §4).
6. `POST /publish/youtube` status report-back endpoint; call it from
   `src/services/yt.ts` after the resumable upload resolves/fails.
7. **Instagram OAuth connect flow** — `AgentIgToken` gains `igUserId`,
   `igUsername`, `expiresAt`, `refreshedAt`; `GET /auth/instagram/connect` +
   `GET /auth/instagram/callback` + a daily token-refresh job; drop the
   originally-planned `PUT /users/me/ig-tokens` (manual paste) in favor of
   this. Start the Meta App Review submission as early in this phase as
   possible — see `09-instagram-onboarding.md` §1, it's the long pole, not
   the code.

## Phase F — Extension-assisted publishing (OLX, Instagram caption fallback)

1. `POST /publish/olx/map-fields` (LLM field-mapping) and
   `POST /publish/olx/confirm` (extension callback) endpoints — see
   `06-cross-posting.md` §4 and `08-publish-tracking.md`.
2. Browser extension (`extension/`): reads the Ad via the existing authed API,
   opens the agent's own logged-in OLX tab, calls `/publish/olx/map-fields`,
   fills the DOM, waits for a human click on OLX's own Publish button — see
   `06-cross-posting.md` §3 and `07-olx-crosspost-extension.md`.
3. Per-ad publish-status grid in the dashboard (`GET /ads/:id/publish-status`).
4. **Instagram caption-assist fallback** (ship after 7.1-7.3 above, so
   "connect properly" is the visibly-easier default): extend the same
   extension with an `instagram-caption-assist.ts` adapter that fills only
   the caption field on `instagram.com`'s own composer — never photos, never
   Share. Requires one-time explicit risk consent before it activates and a
   lower daily cap than OLX (5/day default) — see
   `09-instagram-onboarding.md` §2.

## Phase G — Cleanup

1. Remove `firebase` dependency, `src/lib/firebase.js`, Firebase env vars.
2. Remove unused deps: `instagram-graph-api`, `googleapis` (only `gapi-script`
   is used).
3. Purge `VITE_TG_BOT_TOKEN` etc. from `.env`; keep only `VITE_API_URL`
   (+ YT client-side OAuth vars until YT publishing moves server-side).
4. Update Vercel setup or move hosting; the SPA now needs the API deployed
   alongside it (out of scope for local-dev milestone).

## Phase H (backlog, not scheduled) — Realting.uz feed sync

Passive batch sync via a generated XML/YML feed, not a per-ad click. Needs its
own design pass (field-mapping to Realting's schema, feed hosting, cron
cadence) before it becomes a real phase. The `REALTING` value is reserved in
`PublishChannel` today (see `06-cross-posting.md` §4) so this doesn't require
a second migration once it starts.

## Risks / notes

- **Secrets already leaked in git history** (bot token, API keys in `.env`
  committed). Rotation (Phase E.4) matters more than deletion.
- Firestore's implicit "no schema" hid mixed types; the API's zod validation
  will surface bad form inputs early — expected, not a regression.
- YT publishing keeps using the user's own browser OAuth for now.
- i18n keys, routing, and component structure are intentionally untouched —
  only the data layer (`src/lib/*`) and the few components doing direct
  Firestore writes change.
