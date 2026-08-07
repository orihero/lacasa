# Instagram Onboarding — OAuth Connect + Extension-Assisted Fallback

> Status: implemented (2026-07-30). §1 OAuth connect lives in
> `server/src/routes/instagramAuth.js` + `server/src/lib/instagram.js` (with a
> daily refresh job in `server/src/lib/igTokenRefresh.js`); publishing moved
> server-side to `POST /api/publish/instagram` and raw tokens are no longer
> shipped to the client. §2 was implemented **wider than spec'd** by product
> decision: the extension (`extension/`) does full automation — photo
> injection + caption — not caption-assist only; the consent gate, the
> never-click-Share rule, the 5/day cap, and self-reported completion all
> remain. Meta App Review (§1.3) is still a prerequisite for publish scopes.

> Detail doc for `06-cross-posting.md` §2 (Instagram row). Read that doc first
> for the cross-channel overview. This doc covers two changes to the
> Instagram channel: replacing manual token entry with a real OAuth connect
> flow, and a secondary, explicitly risk-labeled extension-assisted fallback
> that reuses the OLX extension's mechanics (`07-olx-crosspost-extension.md`)
> for agents who still won't connect an account.

## 0. The actual problem

Today, `igTokens` just appears on the `User` record
(`src/lib/userStore.js:23`) — there is no in-app flow that produces it.
`docs/04-api-spec.md` even plans the endpoint for it: `PUT /users/me/ig-tokens`,
documented as "replace IG token list (**write-only**)" — i.e. an agent (or
whoever administers their account) is expected to go generate a long-lived
Graph API token by hand via Meta's Graph API Explorer/App dashboard and paste
it in. That's not a form field, it's a developer task, and it's the reason
agents skip Instagram entirely rather than use the (safe, already-working)
publish path in `src/services/ig.ts`.

Two independent fixes, not one:

1. **Remove the need for a manually-minted token at all** — a real "Connect
   Instagram" OAuth button. Same underlying Graph API publish path, zero
   added risk, solves the actual drop-off problem. §1.
2. **A fallback for agents who still won't connect anything** — generalize
   the OLX browser extension to also assist on Instagram's own web composer.
   Deliberately narrower in scope than OLX (caption-only, never touches photo
   selection or the Share click) because Meta's bot detection is materially
   more aggressive than OLX's — this is a real, disclosed risk, not a free
   upgrade. §2.

## 1. OAuth connect flow (primary fix)

### 1.1 Which Meta flow

Two current options, both live in 2026:

| Flow | Requires a linked Facebook Page | Fits |
|---|---|---|
| Instagram API with **Instagram Login** ("Business Login for Instagram") | No | Per-user consumer-style connect — one agent, one IG professional account |
| Instagram API with **Facebook Login for Business** | Yes | Agencies centrally managing many client accounts via Meta Business Manager |

**Recommendation: Instagram Login.** Each La Casa agent connects their own
account — this is the same shape as Buffer/Later's per-user connect flow, not
an agency-manages-many-clients pattern. Requiring a linked Facebook Page
(Facebook Login for Business) would just trade one onboarding blocker for
another — exactly the problem this fix exists to remove.

### 1.2 Flow shape

1. Frontend: "Connect Instagram" button (`ProfileSetting.jsx`, replacing the
   current bare toggle at line 240-243) opens
   `GET /auth/instagram/connect` in a new tab/popup (not an iframe — Meta
   blocks OAuth in iframes).
2. Backend `GET /auth/instagram/connect`: builds the Meta authorize URL with
   `client_id`, `redirect_uri`, `response_type=code`,
   `scope=instagram_business_basic,instagram_business_content_publish`, and a
   signed `state` param encoding `{ agentId, nonce }` (CSRF protection +
   links the callback back to the right agent). 302-redirects there.
3. Agent logs into Instagram (if not already) and approves on Meta's own
   consent screen — no La Casa UI is involved in credential entry.
4. Meta redirects to `GET /auth/instagram/callback?code=...&state=...`
   (public route, Meta calls it directly):
   - validate `state`, resolve `agentId`
   - exchange `code` → short-lived token (`POST
     https://api.instagram.com/oauth/access_token`)
   - exchange short-lived → **long-lived token, 60-day expiry** (`GET
     https://graph.instagram.com/access_token?grant_type=ig_exchange_token&client_secret=...&access_token=...`)
   - fetch the connected account's id/username (`GET
     https://graph.instagram.com/me?fields=user_id,username&access_token=...`)
   - upsert `AgentIgToken` (schema change, §1.4)
   - redirect back to `/settings?ig=connected` (or `?ig=error` on failure)
5. Refresh: **server-side, no user interaction, but not automatic** — a
   scheduled job (daily) finds tokens expiring within 7 days and calls `GET
   https://graph.instagram.com/refresh_access_token?grant_type=ig_refresh_token&access_token=...`
   (token must be ≥24h old, not yet expired — refreshing on a fixed daily
   cadence comfortably satisfies both). If a token is allowed to actually
   lapse past 60 days, the agent must re-connect from scratch — the job's
   whole job is making sure that doesn't happen silently.

Un-verified detail to confirm against Meta's live docs before implementing:
secondary sources disagreed on whether the authorize host is
`www.instagram.com/oauth/authorize` or `api.instagram.com/oauth/authorize` —
resolve this by loading `developers.facebook.com/docs/instagram-platform` in
an actual browser (it 404s on a plain fetch, likely JS-rendered) before
wiring the redirect.

### 1.3 App Review

Publishing scopes (`instagram_business_content_publish`) need Meta App Review
before they work for real (non-tester) accounts — a screencast of the connect
flow, privacy policy, and ToS pages. Reported turnaround is roughly 2-4 weeks
in 2026 write-ups (**not confirmed against Meta's official SLA** — treat as a
planning estimate, not a commitment). This has a lead time longer than the
engineering work itself: **start the App Review submission before the OAuth
code is finished**, not after. Check whether La Casa currently has a public
privacy policy / ToS page — App Review requires linking one, and if it
doesn't exist yet that's a blocking prerequisite, not a follow-up.

### 1.4 Schema change

`AgentIgToken` currently only stores a bare `accessToken` with no expiry —
add what the refresh job and multi-account UI (`igAccounts.map(...)` in
`ProfileSetting.jsx`) both need:

```prisma
model AgentIgToken {
  id           String    @id @default(uuid()) @db.Uuid
  agentId      String    @map("agent_id") @db.Uuid
  agent        User      @relation(fields: [agentId], references: [id], onDelete: Cascade)
  accessToken  String    @map("access_token")
  igUserId     String    @map("ig_user_id")
  igUsername   String?   @map("ig_username")
  expiresAt    DateTime  @map("expires_at") @db.Timestamptz()
  refreshedAt  DateTime? @map("refreshed_at") @db.Timestamptz()
  createdAt    DateTime  @default(now()) @map("created_at") @db.Timestamptz()

  @@unique([agentId, igUserId])
  @@index([agentId])
  @@index([expiresAt])
  @@map("agent_ig_tokens")
}
```

`@@index([expiresAt])` is what makes the daily refresh job's "expiring within
7 days" query cheap. `@@unique([agentId, igUserId])` lets one agent connect
more than one IG account (matches the existing `igAccounts.map()` UI) without
duplicate rows on reconnect.

### 1.5 API additions

Extends `04-api-spec.md`'s Auth and Publishing tables. **Replaces** the
currently-planned `PUT /users/me/ig-tokens` (manual paste) rather than
sitting alongside it — one connect mechanism, not two competing ones:

| Method & path | Access | Body / params | Returns | Notes |
|---|---|---|---|---|
| `GET /auth/instagram/connect` | agent | — | 302 → Meta authorize URL | builds signed `state` |
| `GET /auth/instagram/callback` | public (Meta calls this) | `?code&state` | 302 → `/settings?ig=connected\|error` | code/token exchange, upserts `AgentIgToken` |
| `DELETE /auth/instagram/:igUserId` | agent (own) | — | `{ ok: true }` | disconnect, deletes the stored token |

`~~PUT /users/me/ig-tokens~~` — drop from the plan; OAuth connect replaces it.

## 2. Extension-assisted fallback (secondary, risk-scoped)

For agents who still won't connect an account (or during the App-Review
waiting period before publish scopes go live). Reuses the OLX extension
package (`07-olx-crosspost-extension.md` §8) rather than shipping a second
extension — `extension/` becomes multi-target, not OLX-only.

### 2.1 Why this is narrower than OLX, deliberately

Meta's bot/anti-automation detection is the most aggressive of any channel in
this project's scope — it's the exact reason Instagram's native composer and
Facebook Marketplace were ruled out entirely in `06-cross-posting.md` §5.
This fallback re-opens Instagram's web composer specifically, but only for
the one field genuinely worth LLM help — **the caption** — not the whole
form:

- The extension **never touches photo selection**. The agent clicks IG's own
  "+ Create" button, picks/orders/crops photos themselves, entirely through
  Instagram's native UI with zero scripted interaction. This is the part of
  the flow closest to Meta's file-picker/native-dialog boundary and the part
  most worth keeping 100% human.
- The extension **never clicks Share.** Same structural exclusion pattern as
  OLX's "never clicks Publish" (`07-olx-crosspost-extension.md` §7) — the
  action vocabulary has no submit action, full stop.
- The extension fills exactly one field: the caption textarea, once IG's
  compose modal reaches its "Write a caption" step (detected via a bounded
  `MutationObserver`, same pattern as OLX's category-step waits).
- **No DOM-snapshot-to-LLM round trip is needed.** Unlike OLX (many
  heterogeneous fields, unknown category tree), there is exactly one target
  field. The LLM's job is pure text generation — "write an Instagram caption
  for this Ad" — not field-mapping. This is a much smaller, cheaper feature
  than the OLX extension, not a copy of it.

### 2.2 Flow

1. "Cross-post to Instagram" button in `AdsEdit`/`AdsAdd` prefers the OAuth
   path (§1) when the agent has a connected `AgentIgToken`. It only offers
   "Try caption-assist instead" when no token is connected — this fallback is
   never the default for an agent who's already connected.
2. First use: a one-time, explicit risk-disclosure dialog — *"This fills only
   your caption text using AI. You still pick your photos and click Share
   yourself in Instagram. Using browser tools on Instagram carries some risk
   of a temporary review from Meta — we never post or click anything on your
   behalf."* Requires an explicit opt-in checkbox, stored per-agent
   (`User.igAssistConsentAt`), before the button activates. This is not
   boilerplate legal text — it is the actual guardrail that makes this an
   informed, opt-in fallback rather than a silent behavior change.
3. Extension opens `instagram.com`, agent clicks Create and picks photos
   normally.
4. `content/instagram-caption-assist.ts` watches for the caption textarea via
   `MutationObserver`; once present, calls
   `POST /publish/instagram/caption { adId }` → `{ caption }` (pure LLM
   generation server-side, same secret-handling pattern as OLX's
   `LLM_API_KEY` — see `06-cross-posting.md` §4.3) and fills it with the same
   native-setter + `input`/`change` event technique as OLX
   (`07-olx-crosspost-extension.md` §3.4) — IG's compose UI is also React.
5. Agent reviews/edits the caption and clicks Instagram's own Share button.
   The extension does not know this happened — it isn't watching for it.
6. Back in La Casa, the agent clicks a plain **"Mark as posted"** button on
   the Ad, which calls `POST /publish/olx/confirm`-equivalent for this
   channel (`POST /publish/instagram/caption/confirm { adId, event: "published"|"aborted" }`,
   upserting `AdPublication(INSTAGRAM, payload.mechanism = "extension-assisted")`).
   This is a deliberate choice: scraping Instagram's own post-success state
   to auto-detect completion would mean *more* scripted interaction with
   Meta's UI, not less — exactly what §2.1 is trying to avoid. A human
   self-report click is simpler, safer, and sufficient for the status grid.

### 2.3 New backend route

One route, much smaller than OLX's field-mapping endpoint:

| Method & path | Access | Body | Returns | Notes |
|---|---|---|---|---|
| `POST /publish/instagram/caption` | agent/coworker | `{ adId }` | `{ caption }` | pure LLM text generation from the Ad's structured fields (title, city/district, rooms, area, price, description) — no DOM snapshot involved |
| `POST /publish/instagram/caption/confirm` | agent/coworker | `{ adId, event: "published"\|"aborted" }` | `{ publication }` | human self-report; upserts `AdPublication(INSTAGRAM)` with `payload.mechanism = "extension-assisted"` |

### 2.4 Guardrails (stricter than OLX's, matching the elevated risk)

- Lower daily cap than OLX's default 15/day — default **5/day**, same
  server-enforced pattern (`07-olx-crosspost-extension.md` §7).
- Explicit one-time consent (§2.2 step 2) before the button ever activates —
  OLX has no equivalent gate; this fallback does, because the risk is real
  and undisclosed automation on a personal/business social account is a
  materially bigger deal than a classifieds draft.
- The status grid (`GET /ads/:id/publish-status`,
  `08-publish-tracking.md` §4) should visibly distinguish
  `payload.mechanism` so an agent (and support staff) can tell "published via
  Graph API" from "published via caption-assist, self-reported" at a glance.

### 2.5 Extension package changes

`extension/manifest.json` (`07-olx-crosspost-extension.md` §1) gains
`https://www.instagram.com/*` to `host_permissions` and a third content
script entry. File layout becomes multi-target rather than OLX-only:

```
extension/src/content/
  lacasa-bridge.ts              # unchanged — site-agnostic trigger relay
  olx-autofill.ts               # OLX adapter (07 §3-5)
  instagram-caption-assist.ts   # new — IG adapter (this doc §2.2)
  dom-executor.ts               # shared — native setter + event dispatch (used by both adapters)
```

`dom-executor.ts`'s `setNativeValue` helper (`07-olx-crosspost-extension.md`
§3.4 code) is reused as-is — it's not OLX-specific, it's "how to write into a
React-controlled input from a content script," which is exactly what the IG
caption field also needs.

## 3. Build order

- **Phase E (extend further)** — OAuth connect flow (§1): new
  `AgentIgToken` columns + migration, `/auth/instagram/connect|callback`,
  refresh job, drop the planned `PUT /users/me/ig-tokens`. No new risk
  profile, same theme Phase E is already about. Start the Meta App Review
  submission (§1.3) as early as possible in this phase — it's the long pole,
  not the code.
- **Phase F (extend)** — caption-assist fallback (§2) ships alongside the
  OLX extension work, since it's the same package and the same
  human-in-the-loop review-before-action pattern, just narrower in scope and
  with an added consent gate. Sequence it *after* the OAuth flow ships — the
  fallback only makes sense once "connect properly" is the visibly-easier
  default option.
