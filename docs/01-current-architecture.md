# Current Architecture (as-is)

> Snapshot of the codebase before the Postgres/MinIO migration. Date: 2026-07-30.

## Overview

**La Casa** (`estateui`) is a real-estate platform for the Uzbekistan market:
public listing site + agent dashboard (listings, leads, coworkers, analytics,
multi-channel social publishing).

- **Frontend:** React 18 + Vite, MUI + Tailwind, react-router v6, zustand, i18next.
- **Backend:** none. The app is a static SPA (deployed on Vercel) that talks to
  Firebase directly from the browser.
- **Data:** Firebase Firestore + Firebase Storage.
- **Auth:** Firebase Auth, email/password only.

## Firebase usage

Initialized in `src/lib/firebase.js` (project `lecasa-105ab`). Services used:
Auth, Firestore, Storage, Analytics.

### Firestore collections

| Collection | Purpose | Written by |
|---|---|---|
| `users` | All accounts: `user` (visitor), `agent`, `coworker` (belongs to an agent via `agentId`) | register, coworker CRUD, profile settings |
| `ads` | Property listings. `stage`: `"1"` active, `"2"` sold, `"3"` draft | `AdsAdd`, `AdsEdit`, legacy `newPostPage` |
| `leads` | CRM leads with kanban pipeline (`new` → `accepted`/`rejected` …) | `LeadAdd`, `LeadUpdate`, kanban |
| `statistics` | Append-only event log used for dashboard counts (overloaded `stage` int enum) | every ad/lead mutation |
| `currency` | Single doc: UZS↔USD rate | manually |
| `nearbyList` | Single doc: selectable "nearby place" tags | manually |

### Storage

One helper, `src/lib/assetUpload.js`, uploads everything to a flat
`images/{timestamp}{filename}` path and stores the public download URL in
Firestore (`ads.photos[]`, `users.avatar`). Files are never deleted.

## State layer

Zustand stores in `src/lib/` call the Firestore SDK inline (no caching, no
optimistic updates): `userStore`, `adsListStore`, `agentsStore`,
`useCoworkerStore`, `useLeadStore`, `useStatisticsStore`, `utilsStore`.
This layer is the seam where the new REST client will plug in.

## External integrations (all client-side today)

| Service | Files | Notes |
|---|---|---|
| Telegram Bot API | `src/services/tg.ts`, `AdsAdd`/`AdsEdit`, `ContactUs.jsx` | Publishes listings to agent channels; contact form posts to a **hardcoded bot token in source** |
| Instagram Graph API | `src/services/ig.ts` | Publishes photo carousels using per-agent tokens stored in `users.igTokens[]` |
| YouTube Data API | `src/services/yt.ts`, `src/services/cors_upload.js` | Browser OAuth + resumable video upload |
| CloudPano | `homePage.jsx` | Static 3D-tour iframe embed |

## Known problems (fixed by the migration, see doc 02)

1. **Plaintext passwords** are stored in the `users` Firestore docs alongside
   Firebase Auth (`register.jsx`, `CoworkerAdd.jsx`).
2. **Secrets ship in the client bundle**: Telegram bot token (hardcoded in
   `ContactUs.jsx` and in `VITE_TG_BOT_TOKEN`), Google API keys, per-agent IG
   tokens readable by any logged-in client.
3. **Client-side privilege escalation**: an agent's browser creates coworker
   auth accounts via a second Firebase app instance (`CoworkerAdd.jsx`).
4. **No server-side validation** anywhere; Firestore holds mixed string/number
   types for numeric fields (`stage` is a string, `price`/`rooms` vary).
5. **Orphaned storage files**: uploads are never deleted.
6. `statistics` is an append-only log emulating what SQL aggregates do naturally.

## Frontend routes (for reference)

Public: `/` (landing), `/ads`, `/list`, `/post/:id`, `/agents`, `/agent/:id`,
`/login`, `/register`.
Dashboard (`/profile/...`): analytics chart, ads CRUD, leads CRUD + kanban,
coworkers CRUD, profile settings with social-account connection.
Legacy: `/post` (`newPostPage`) — superseded by `AdsAdd`, candidate for removal.
