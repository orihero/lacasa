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
    example: "http://localhost:5273,http://localhost:5274,http://localhost:5275",
    comment:
      "Comma-separated list of allowed origins; unset allows all. Three browser apps talk to this API on three ports — web 5273, console 5274, control room 5275 — and a list missing one fails as a browser-level CORS error the app cannot explain, not as an API error",
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
  {
    name: "FCM_SERVER_KEY",
    type: "string",
    comment:
      "Firebase Cloud Messaging legacy server key for push notifications (pushService.js). Optional like " +
      "TG_BOT_TOKEN/ANTHROPIC_API_KEY: unset degrades every push send to a logged no-op (PUSH_CONFIGURED " +
      "below) instead of failing boot or failing whatever write (a lead, a publish outcome) triggered the " +
      "push attempt -- see lib/activity.js and publishService.js for those trigger points. There is " +
      "deliberately no client wired up to register a device yet (docs/09's mobile-app slice keeps " +
      "permission_gateway.dart's short-circuit in place until this exists end-to-end); this var only gates " +
      "the server's half.",
  },
  {
    name: "STATISTICS_TIMEZONE",
    type: "string",
    timezone: true,
    default: "Asia/Tashkent",
    example: "Asia/Tashkent",
    comment:
      "IANA zone that defines what 'today'/'thisWeek'/'thisMonth' mean for GET /api/statistics/ads and " +
      ".../ads/series (statisticsService.js#dateRangeFor). This is a single-market product -- phone numbers " +
      "are validated ^+998\\d{9}$ and the region vocabulary is Uzbekistan's 14 regions/203 districts -- so " +
      "'today' means today in Uzbekistan, not wherever the API process happens to be deployed. Uzbekistan has " +
      "run UTC+5 year-round with no DST since 1992, so one fixed zone answers correctly for every agent. A " +
      "second market would break that assumption (either a second DST-observing zone, or just a second UTC " +
      "offset) and would need a per-agent/per-request zone resolved from the agent's region, not one " +
      "process-wide default.",
  },
];

// Delegates to Intl instead of a hardcoded allowlist: any zone the ICU data
// bundled with this Node build recognizes is accepted, which is the same
// data set `Intl.DateTimeFormat`/statisticsService.js will actually use at
// request time -- validating against anything else could pass a name at
// boot that then throws on the first request.
function isValidTimeZone(tz) {
  try {
    // eslint-disable-next-line no-new
    new Intl.DateTimeFormat(undefined, { timeZone: tz });
    return true;
  } catch {
    return false;
  }
}

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
  // `.refine()` (unlike `.min()`) lives on zod's base `ZodType`, so it has
  // to go last regardless of which of ZodString/ZodDefault/ZodOptional the
  // required/default branch below produces -- otherwise the timezone check
  // would need its own copy of this required/default branching.
  let base = spec.required ? z.string().min(1, `${spec.name} is required`) : z.string();
  if (spec.default !== undefined) base = base.default(spec.default);
  else if (!spec.required) base = base.optional();
  if (spec.timezone) base = base.refine(isValidTimeZone, { message: `${spec.name} must be a valid IANA timezone name` });
  return base;
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
    PUSH_CONFIGURED: Boolean(data.FCM_SERVER_KEY),
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
