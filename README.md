# La Casa — Real Estate Platform

An npm-workspaces monorepo for a real-estate marketplace + agent CRM, running on
**Express + PostgreSQL + MinIO**. Migrated off Firebase (see
[docs/05-migration-plan.md](docs/05-migration-plan.md) for what is left).

## Workspaces

| Workspace | What it is | Dev port |
|---|---|---|
| `apps/api` | Express + Prisma REST API — the single backend for every surface | 4200 |
| `apps/web` | Public marketplace + the legacy realtor dashboard (React 18) | 5273 |
| `apps/console` | The Direction F agent console (React 19 + Tailwind) | 5274 |
| `apps/extension` | Chrome extension for OLX / Instagram crossposting | — |
| `apps/mobile_flutter` | Flutter mobile client | — |
| `packages/*` | `api-client`, `domain`, `crosspost-protocol` + shared eslint/ts/vitest configs | — |

## Docs

| Doc | Contents |
|---|---|
| [docs/01-current-architecture.md](docs/01-current-architecture.md) | As-is analysis (Firebase usage, known problems) |
| [docs/02-target-architecture.md](docs/02-target-architecture.md) | To-be design (API, auth, uploads, integrations) |
| [docs/03-data-model.md](docs/03-data-model.md) | Firestore → Postgres mapping |
| [docs/04-api-spec.md](docs/04-api-spec.md) | REST API v1 endpoints |
| [docs/05-migration-plan.md](docs/05-migration-plan.md) | Phased migration plan & **current status** |
| [docs/06-cross-posting.md](docs/06-cross-posting.md) | Crossposting design |
| [docs/07-olx-crosspost-extension.md](docs/07-olx-crosspost-extension.md) | The OLX extension |
| [docs/08-publish-tracking.md](docs/08-publish-tracking.md) | `AdPublication` and publish status |
| [docs/09-instagram-onboarding.md](docs/09-instagram-onboarding.md) | IG OAuth + Meta App Review |
| [mockups/SCREENS.md](mockups/SCREENS.md) | Mobile screen spec |
| [mockups/f/PLAN.md](mockups/f/PLAN.md) | Console adaptation plan |

## Local development

Prereqs: Node 20+ and either native PostgreSQL 16+ & MinIO
(scoop: `scoop install postgresql minio minio-client`) or Docker Desktop.
Flutter is only needed for `apps/mobile_flutter`.

```sh
# 1. Infrastructure: Postgres (:5432) + MinIO (:9000, console :9001)
#    Option A — native (current dev machine): Postgres & MinIO already run via scoop.
#    One-time setup:
#      psql -U postgres -h localhost -c "CREATE ROLE lacasa LOGIN PASSWORD 'lacasa_dev' CREATEDB"
#      psql -U postgres -h localhost -c "CREATE DATABASE lacasa OWNER lacasa"
#      mc mb --ignore-existing local/lacasa && mc anonymous set download local/lacasa
#    Option B — Docker:
docker compose up -d

# 2. Install everything once, from the repo root (npm workspaces)
npm install

# 3. API
cp apps/api/.env.example apps/api/.env    # then edit if needed
npx prisma migrate dev -w @lacasa/api     # creates schema
npm run seed -w @lacasa/api               # currency rate, nearby places, agent@lacasa.dev / password123
npm run dev:api                           # http://localhost:4200/api/health

# 4. Frontends (each needs the API running)
npm run dev:web                           # http://localhost:5273
npm run dev:console                       # http://localhost:5274
npm run dev:mobile-flutter                # needs the Flutter SDK
```

Root scripts fan out across every workspace: `npm run build`, `npm run lint`,
`npm run test`, `npm run typecheck`. To scope one, add `-w @lacasa/<name>`.

MinIO console: http://localhost:9001 (user `lacasa`, password `lacasa_dev_secret`).
Prisma Studio (DB browser): `npm run studio -w @lacasa/api`.

> ⚠️ Telegram publishing and the contact form now go through `apps/api`
> (`POST /publish/telegram`, `POST /contact`) — the bot token lives only in
> the server's env and is no longer compiled into the `apps/web` bundle or
> hardcoded in source. The **old token is still burned and needs rotating**:
> it shipped in public bundles and one hardcoded literal for a long time, so
> it remains in git history regardless of what the code does today — see
> docs/05 Phase E.4.

## CI

`.github/workflows/ci.yml` runs on every push and pull request against
`main` and `chore/monorepo`, on `ubuntu-latest` in a Node 20 / Node 22
matrix (this repo's `engines.node` floor). Each matrix job:

1. `npm ci` — installs from the single root `package-lock.json` (this is an
   npm-workspaces monorepo; there is no per-workspace lockfile).
2. `prisma generate` for `@lacasa/api`, run explicitly rather than relying
   solely on `@prisma/client`'s postinstall.
3. `npm run build/lint/typecheck --workspaces --if-present`.
4. `npm run test --workspaces --if-present -- --coverage` — unit tests with
   coverage enabled, so the thresholds each workspace configures in
   `packages/config-vitest` (80% default, 95% for `packages/domain`, 40%
   for `apps/web`) actually gate the build instead of sitting unenforced.
5. `npm run test:integration -w @lacasa/api -- --coverage` — `@lacasa/api`'s
   supertest suite against a real Postgres, provided by a GitHub Actions
   `services:` container (not `docker-compose.yml`, which is reserved for
   local Docker use and binds the same ports a native dev setup already
   uses). `apps/api/vitest.config.js` points this project's `DATABASE_URL`
   at `TEST_DATABASE_URL`, and its `globalSetup` runs
   `prisma migrate deploy` against it before any test runs — no separate
   migration step is needed in the workflow.

All environment variables the workflow sets (`DATABASE_URL`,
`TEST_DATABASE_URL`, `JWT_SECRET`, `MINIO_ACCESS_KEY`, `MINIO_SECRET_KEY`)
are dummy CI-only values required by `apps/api/src/lib/config.js`'s
fail-fast validation — never real secrets, so the workflow also runs
unmodified on pull requests from forks.
