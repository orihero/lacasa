// Bundles the MV3 extension into extension/dist. Content scripts must be
// self-contained IIFEs (MV3 content scripts are not modules); the background
// service worker is an ES module.
import * as esbuild from "esbuild";
import { cpSync, mkdirSync } from "fs";

const watch = process.argv.includes("--watch");

mkdirSync("dist", { recursive: true });
cpSync("manifest.json", "dist/manifest.json");
cpSync("src/ui/review-banner.css", "dist/review-banner.css");
try {
  cpSync("icons", "dist/icons", { recursive: true });
} catch {
  // icons are optional during development
}

const options = {
  bundle: true,
  sourcemap: false,
  logLevel: "info",
  entryPoints: [
    { in: "src/background/service-worker.ts", out: "background/service-worker" },
    { in: "src/content/lacasa-bridge.ts", out: "content/lacasa-bridge" },
    { in: "src/content/olx-autofill.ts", out: "content/olx-autofill" },
    { in: "src/content/instagram-autofill.ts", out: "content/instagram-autofill" },
  ],
  outdir: "dist",
  format: "iife",
};

if (watch) {
  const ctx = await esbuild.context(options);
  await ctx.watch();
} else {
  await esbuild.build(options);
}
