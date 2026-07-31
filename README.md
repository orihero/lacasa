# La Casa — Real Estate Platform

React + Vite SPA (public listings + agent CRM dashboard) being migrated from
Firebase to a local-first stack: **Express API + PostgreSQL + MinIO**.

## Docs

| Doc | Contents |
|---|---|
| [docs/01-current-architecture.md](docs/01-current-architecture.md) | As-is analysis (Firebase usage, known problems) |
| [docs/02-target-architecture.md](docs/02-target-architecture.md) | To-be design (API, auth, uploads, integrations) |
| [docs/03-data-model.md](docs/03-data-model.md) | Firestore → Postgres mapping |
| [docs/04-api-spec.md](docs/04-api-spec.md) | REST API v1 endpoints |
| [docs/05-migration-plan.md](docs/05-migration-plan.md) | Phased migration plan & status |

## Local development

Prereqs: Node 20+, Yarn (frontend) / npm (server), and either native
PostgreSQL 16+ & MinIO (scoop: `scoop install postgresql minio minio-client`)
or Docker Desktop.

```sh
# 1. Infrastructure: Postgres (:5432) + MinIO (:9000, console :9001)
#    Option A — native (current dev machine): Postgres & MinIO already run via scoop.
#    One-time setup:
#      psql -U postgres -h localhost -c "CREATE ROLE lacasa LOGIN PASSWORD 'lacasa_dev' CREATEDB"
#      psql -U postgres -h localhost -c "CREATE DATABASE lacasa OWNER lacasa"
#      mc mb --ignore-existing local/lacasa && mc anonymous set download local/lacasa
#    Option B — Docker:
docker compose up -d

# 2. API
cd server
cp .env.example .env        # then edit if needed
npm install
npx prisma migrate dev      # creates schema
npm run seed                # currency rate, nearby places, agent@lacasa.dev / password123
npm run dev                 # http://localhost:4200/api/health

# 3. Frontend
yarn
yarn dev                    # http://localhost:5273
```

MinIO console: http://localhost:9001 (user `lacasa`, password `lacasa_dev_secret`).
Prisma Studio (DB browser): `cd server && npm run studio`.

> Note: the frontend still talks to Firebase until the migration phases in
> docs/05 land; the API currently serves `/api/health`, `/api/utils/*`, and
> `/api/uploads/presign`.

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
