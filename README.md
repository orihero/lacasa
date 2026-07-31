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
