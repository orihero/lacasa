# Target Architecture (to-be)

Local-first stack: the browser no longer talks to any database or holds any
secrets. Everything goes through a new REST API.

```
┌──────────────┐     HTTPS/JSON      ┌──────────────────┐
│  React SPA   │ ──────────────────► │  API (Express)   │
│  (Vite)      │                     │  Node 20+        │
└──────────────┘                     │  Prisma ORM      │
       │  photo URLs                 └───────┬──────────┘
       ▼                                     │
┌──────────────┐                    ┌────────┴─────────┐
│ MinIO        │ ◄── uploads ────── │                  │
│ (S3 API)     │    (presigned or   │  PostgreSQL 16   │
│ bucket:      │     proxied)       │  db: lacasa      │
│  lacasa      │                    └──────────────────┘
└──────────────┘
```

## Components

| Component | Choice | Notes |
|---|---|---|
| Database | PostgreSQL 16 (Docker) | schema managed by Prisma Migrate |
| ORM | Prisma | schema in `server/prisma/schema.prisma` |
| API | Node 20 + Express | `server/` workspace, plain JS (matches frontend), REST/JSON |
| File storage | MinIO (Docker) | S3-compatible; bucket `lacasa`, public-read for listing photos |
| Auth | JWT (access token) + bcrypt password hashes | replaces Firebase Auth; roles enforced server-side |
| Social publishing | moved server-side | TG/IG tokens live only in server env / DB; browser calls `/api/publish/*` |

Run `docker compose up -d` at the repo root to start Postgres + MinIO
(see `docker-compose.yml`; MinIO console at http://localhost:9001).

## Auth design

- `POST /api/auth/register` → creates `users` row with `bcrypt` hash, returns JWT.
- `POST /api/auth/login` → verifies hash, returns JWT (`{ sub, role, agentId }`).
- JWT sent as `Authorization: Bearer <token>`; middleware attaches `req.user`.
- **Coworker creation becomes a privileged endpoint**: `POST /api/coworkers`
  requires `role=agent`; server creates the account (fixes the
  second-Firebase-app hack).
- Passwords are **never** stored or returned in plaintext (fixes the current
  `users.password` field).

Role rules (enforced in middleware, mirroring current UI behavior):
- `user` — read public data, edit own profile.
- `coworker` — everything an agent can do but scoped to `agentId`'s data;
  leads can additionally be filtered to their own `coworkerId`.
- `agent` — full CRUD on own ads/leads/coworkers, own analytics, social publish.

## File upload flow (MinIO)

1. Client asks `POST /api/uploads/presign` with `{ fileName, contentType, scope }`
   (`scope`: `ads` | `avatars`).
2. Server returns a presigned PUT URL for key `{scope}/{uuid}-{safeName}` in
   bucket `lacasa`, plus the final public URL.
3. Client PUTs the file directly to MinIO, then submits the public URL in the
   ad/profile form — same shape the UI already uses (`photos: string[]`).

Bucket policy: `lacasa` is public-read (download only); writes require
presigned URLs. Ad deletion deletes its objects (fixes orphaned files).

## Social integrations (moved server-side)

- `POST /api/publish/telegram` / `POST /api/publish/instagram` — server holds
  the bot token and per-agent IG tokens (`agent_ig_tokens` values move to the DB,
  readable only by the server).
- `POST /api/contact` — replaces the contact form's direct Telegram call;
  the hardcoded token is removed from `ContactUs.jsx`.
- YouTube upload stays client-side for now (it's the user's own Google OAuth
  session), tracked as a follow-up.

## Statistics

The `statistics` collection is replaced by an `activity_events` table with a
proper enum, still append-only (the dashboard time-bucketing needs event
timestamps, so pure aggregates over `ads`/`leads` are not enough for
"created in period X" charts once rows get updated). `GET /api/statistics/*`
endpoints do the aggregation in SQL.

## Frontend changes (summary)

- New `src/lib/api.js` — axios instance with base URL `VITE_API_URL` and JWT
  interceptor.
- Each zustand store swaps Firestore calls for API calls; store shapes stay the
  same so components are mostly untouched.
- `firebase` dependency, `src/lib/firebase.js`, and the secondary-app hack are
  deleted at the end (doc 05, phase F).

## Environment

- Root `.env` keeps only frontend-safe vars: `VITE_API_URL`.
- `server/.env` (never bundled): `DATABASE_URL`, `JWT_SECRET`, MinIO creds,
  `TG_BOT_TOKEN`, contact-channel id. Template: `server/.env.example`.
