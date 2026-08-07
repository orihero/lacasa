// Single source of truth for every environment variable this API reads.
// Every module below imports `config` and reads a property off it — never
// `process.env` directly — so what's required (and what happens when it's
// missing) is documented in exactly one place instead of scattered
// `process.env.X ?? fallback` fallbacks across a dozen files.
//
// `required: true` vars have no sane default: the app cannot serve a single
// request without them (JWT_SECRET, DATABASE_URL, the MinIO credentials),
// so `loadConfig()` fails fast at boot with one readable message listing
// every missing var at once, instead of a cryptic failure the first time a
// request happens to touch them. Everything else either has a default that
// matches this codebase's historical `process.env.X ?? fallback`, or gates
// an optional feature the app already degrades gracefully without
// (Instagram OAuth, LLM field-mapping, Telegram) — those stay unset-able.
//
// ENV_VARS doubles as the source for apps/api/.env.example: run
// `node scripts/gen-env-example.mjs` (from apps/api) to regenerate it from
// this list, so the schema and the example file can never drift apart.
import "dotenv/config";
import { z } from "zod";

export const ENV_VARS = [
  {
    name: "DATABASE_URL",
    required: true,
    type: "string",
    example: "postgresql://lacasa:lacasa_dev@localhost:5432/lacasa",
  },
  { name: "PORT", type: "number", default: 4200, example: "4200" },
  {
    name: "CORS_ORIGIN",
    type: "string",
    example: "http://localhost:5273",
    comment: "Comma-separated list of allowed origins; unset allows all",
  },
  {
    name: "APP_URL",
    type: "string",
    default: "http://localhost:5273",
    example: "http://localhost:5273",
    comment: "Used to build redirect URLs, e.g. the Instagram OAuth settings-page landing",
  },
  {
    name: "JWT_SECRET",
    required: true,
    type: "string",
    example: "change-me-to-a-long-random-string",
  },
  { name: "JWT_EXPIRES_IN", type: "string", default: "7d", example: "7d" },
  {
    name: "MINIO_ENDPOINT",
    type: "string",
    default: "localhost",
    example: "localhost",
    comment: "MinIO — docker-compose values shown; a native scoop MinIO uses minioadmin/minioadmin by default",
  },
  { name: "MINIO_PORT", type: "number", default: 9000, example: "9000" },
  { name: "MINIO_USE_SSL", type: "boolean", default: false, example: "false" },
  { name: "MINIO_ACCESS_KEY", required: true, type: "string", example: "lacasa" },
  { name: "MINIO_SECRET_KEY", required: true, type: "string", example: "lacasa_dev_secret" },
  { name: "MINIO_BUCKET", type: "string", default: "lacasa", example: "lacasa" },
  {
    name: "MINIO_PUBLIC_URL",
    type: "string",
    example: "http://localhost:9000/lacasa",
    comment: "Base URL clients use to load objects (public-read bucket); defaults to http://localhost:9000/<MINIO_BUCKET>",
  },
  {
    name: "IG_APP_ID",
    type: "string",
    comment: "Instagram OAuth (Business Login for Instagram) — leave unset to disable /api/auth/instagram/*",
  },
  { name: "IG_APP_SECRET", type: "string" },
  { name: "IG_REDIRECT_URI", type: "string", example: "http://localhost:4200/api/auth/instagram/callback" },
  {
    name: "ANTHROPIC_API_KEY",
    type: "string",
    comment: "Unset disables extension-assisted AI field-mapping (docs/07 §3.3)",
  },
  { name: "LLM_MODEL", type: "string", default: "claude-opus-5", example: "claude-opus-5" },
  {
    name: "OLX_DAILY_CAP",
    type: "number",
    default: 15,
    example: "15",
    comment: "Per-agent daily cap on OLX cross-post sessions (docs/07 §7)",
  },
  { name: "IG_ASSIST_DAILY_CAP", type: "number", default: 5, example: "5" },
  {
    name: "TG_BOT_TOKEN",
    type: "string",
    comment:
      "Server-side Telegram publish + contact relay (rotate the old leaked tokens before use). Left optional " +
      "like IG_APP_ID/ANTHROPIC_API_KEY: unset degrades /api/publish/telegram and /api/contact to a clean " +
      "503 (TG_CONFIGURED below), it does not fail boot -- flipping this to required would break every dev " +
      "machine and CI job that has never set it.",
  },
  {
    name: "TG_CONTACT_CHAT_ID",
    type: "string",
    comment: "Office chat POST /api/contact relays to; unset also degrades that route to a 503, same reasoning as TG_BOT_TOKEN",
  },
];

function zodFor(spec) {
  if (spec.type === "number") {
    const base = z.coerce.number().int().positive();
    if (spec.required) return base;
    if (spec.default !== undefined) return base.default(spec.default);
    return base.optional();
  }
  if (spec.type === "boolean") {
    // Matches the historical `process.env.X === "true"` checks: anything
    // other than the literal string "true" (including unset) is false.
    return z.string().optional().transform((v) => v === "true");
  }
  if (spec.required) return z.string().min(1, `${spec.name} is required`);
  if (spec.default !== undefined) return z.string().default(spec.default);
  return z.string().optional();
}

const envSchema = z.object(Object.fromEntries(ENV_VARS.map((v) => [v.name, zodFor(v)])));

// A blank `KEY=` line in a .env file sets process.env.KEY to "", not
// undefined — dotenv doesn't distinguish "unset" from "set to empty".
// Treating "" as unset here means every default/optional field above
// behaves the same whether a var is missing entirely or just left blank,
// which is what every one of this app's `process.env.X ?? fallback` sites
// already assumed in spirit (even though `??` alone doesn't catch "").
function emptyToUndefined(env) {
  const out = {};
  for (const key of Object.keys(env)) out[key] = env[key] === "" ? undefined : env[key];
  return out;
}

export function loadConfig(env = process.env) {
  const result = envSchema.safeParse(emptyToUndefined(env));
  if (!result.success) {
    const lines = result.error.issues.map((i) => `  - ${i.path.join(".")}: ${i.message}`);
    throw new Error(`Invalid environment configuration — fix these and restart:\n${lines.join("\n")}`);
  }
  const data = result.data;
  return {
    ...data,
    MINIO_PUBLIC_URL: data.MINIO_PUBLIC_URL ?? `http://localhost:9000/${data.MINIO_BUCKET}`,
    IG_CONFIGURED: Boolean(data.IG_APP_ID && data.IG_APP_SECRET && data.IG_REDIRECT_URI),
    LLM_CONFIGURED: Boolean(data.ANTHROPIC_API_KEY),
    TG_CONFIGURED: Boolean(data.TG_BOT_TOKEN),
  };
}

export const config = loadConfig();

export function renderEnvExample() {
  const lines = ["# Copy to apps/api/.env for local development. Never commit apps/api/.env.", ""];
  for (const v of ENV_VARS) {
    if (v.comment) lines.push(`# ${v.comment}`);
    lines.push(`${v.name}=${v.example ?? ""}`);
  }
  return `${lines.join("\n")}\n`;
}
