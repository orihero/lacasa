// Inlines woff2 files as data URIs so each deck is a single self-contained HTML
// file (artifact CSP blocks font CDNs, and a silent fallback would wreck the
// typography these decks are built on).
//
//   node presentation/build.mjs              # every deck
//   node presentation/build.mjs b-editorial  # just one (name with or without .html)
//
// src/*.html  ->  *.html  with every {{font:name}} replaced by base64.
//
// The single-deck form exists so three agents can build and re-render their own
// deck concurrently without racing each other's output file.

import { readFile, writeFile, readdir } from "node:fs/promises";
import { join, dirname } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));
const srcDir = join(here, "src");
const fontDir = join(here, "fonts");

const fonts = new Map();
for (const file of await readdir(fontDir)) {
  if (!file.endsWith(".woff2")) continue;
  const b64 = (await readFile(join(fontDir, file))).toString("base64");
  fonts.set(file.replace(/\.woff2$/, ""), `data:font/woff2;base64,${b64}`);
}

const only = new Set(
  process.argv.slice(2).map((a) => (a.endsWith(".html") ? a : `${a}.html`)),
);

const all = (await readdir(srcDir)).filter((f) => f.endsWith(".html"));
for (const name of only) {
  if (!all.includes(name)) throw new Error(`no such deck: src/${name}`);
}

for (const file of all) {
  if (only.size && !only.has(file)) continue;
  const src = await readFile(join(srcDir, file), "utf8");
  const missing = [];
  const out = src.replace(/\{\{font:([\w.-]+)\}\}/g, (_, name) => {
    if (!fonts.has(name)) missing.push(name);
    return fonts.get(name) ?? "";
  });
  if (missing.length) {
    throw new Error(`${file}: no font file for ${[...new Set(missing)].join(", ")}`);
  }
  await writeFile(join(here, file), out);
  console.log(`${file} -> ${(out.length / 1024).toFixed(0)} KB`);
}
