// Regenerates apps/api/.env.example from the ENV_VARS list in
// src/lib/config.js, so the schema and the example file can never drift
// apart. Run from apps/api: `node scripts/gen-env-example.mjs`.
import { writeFileSync } from "node:fs";
import { fileURLToPath } from "node:url";
import { renderEnvExample } from "../src/lib/config.js";

const outPath = fileURLToPath(new URL("../.env.example", import.meta.url));
writeFileSync(outPath, renderEnvExample());
console.log(`Wrote ${outPath}`);
