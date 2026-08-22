// Per-slide screenshots of a built deck, so a deck can be *looked at* instead of
// assumed correct. Headless Chrome, one 1280x720 PNG per slide.
//
//   node presentation/shots.mjs b-editorial.html [outDir] [slideCount]
//   WIN=1024,768 node presentation/shots.mjs b-editorial.html shots/b-small
//
// WIN overrides the capture viewport (default 1280x720) — a deck that only
// letterboxes correctly at exactly 16:9 is a deck that breaks on a projector.
//
// Every deck answers `?static#N` with slide N shown and all transitions off,
// which is what makes this scriptable. Each run gets its own throwaway Chrome
// profile so three of these can run at once.

import { mkdir, rm, readdir } from "node:fs/promises";
import { execFile } from "node:child_process";
import { promisify } from "node:util";
import { existsSync } from "node:fs";
import { join, dirname, resolve, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { tmpdir } from "node:os";

const run = promisify(execFile);
const here = dirname(fileURLToPath(import.meta.url));

const CHROME = [
  "C:/Program Files/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Google/Chrome/Application/chrome.exe",
  "C:/Program Files (x86)/Microsoft/Edge/Application/msedge.exe",
].find((p) => existsSync(p));
if (!CHROME) throw new Error("no Chrome/Edge binary found");

const [deckArg, outArg, countArg] = process.argv.slice(2);
if (!deckArg) throw new Error("usage: node shots.mjs <deck.html> [outDir] [slideCount]");

const deck = resolve(here, deckArg.endsWith(".html") ? deckArg : `${deckArg}.html`);
if (!existsSync(deck)) throw new Error(`not built: ${deck} — run build.mjs first`);

const slug = basename(deck, ".html");
const outDir = resolve(outArg ?? join(here, "shots", slug));
const count = Number(countArg ?? 13);

await rm(outDir, { recursive: true, force: true });
await mkdir(outDir, { recursive: true });

const profile = join(tmpdir(), `deckshot-${slug}`);
await rm(profile, { recursive: true, force: true });

const fileUrl = `file:///${deck.replace(/\\/g, "/")}`;

for (let n = 1; n <= count; n++) {
  const out = join(outDir, `${String(n).padStart(2, "0")}.png`);
  await run(CHROME, [
    "--headless=new",
    "--disable-gpu",
    "--hide-scrollbars",
    "--force-device-scale-factor=1",
    `--window-size=${process.env.WIN ?? "1280,720"}`,
    "--virtual-time-budget=2500",
    `--user-data-dir=${profile}`,
    `--screenshot=${out}`,
    `${fileUrl}?static#${n}`,
  ]);
}

const written = (await readdir(outDir)).filter((f) => f.endsWith(".png"));
if (written.length !== count) {
  throw new Error(`expected ${count} PNGs, got ${written.length} in ${outDir}`);
}
console.log(`${slug}: ${written.length} slides -> ${outDir}`);
