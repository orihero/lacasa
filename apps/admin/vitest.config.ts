import { fileURLToPath, URL } from "node:url";
import react from "@vitejs/plugin-react";
import { reactPreset } from "@lacasa/config-vitest/react";

// The shared react preset (jsdom + jest-dom + msw + RTL cleanup) with this
// workspace's own additions. Unlike apps/web's vitest.config.js this does NOT
// merge the real vite.config.ts: the only thing tests need out of it is the
// react plugin and the "@" alias, both restated below, and pulling in the
// server block would hand vitest a strictPort it has no use for.
//
// No `resolve.dedupe` and no `server.deps.inline` — both existed only to
// bridge the old React 19 app to a hoisted React 18. See vite.config.ts.
export default reactPreset({
  plugins: [react()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  test: {
    globals: true,
    // Appended to (not replacing) the shared preset's setup file — vite's
    // mergeConfig concatenates arrays. See src/test/setup.ts for what this
    // workspace needs on top.
    setupFiles: ["./src/test/setup.ts"],
    // The shared preset's 40% floor is calibrated to apps/web's largely
    // untested legacy UI. This app starts clean, so it starts higher; the four
    // feature screens land after this scaffold and are expected to raise it
    // further, never to lower it.
    //
    // The screens have now landed, so this is that ratchet turn. Measured on
    // the full suite: 91.17 lines / 91.17 statements / 89.98 branches /
    // 89.60 functions. The floors sit just under each measured figure — close
    // enough that a real regression trips them, with ~1-2pt of slack so an
    // incidental branch does not. Raise these as coverage climbs; never lower
    // them to make a failing run pass.
    coverage: {
      thresholds: { lines: 90, functions: 88, branches: 88, statements: 90 },
      exclude: [
        "src/main.tsx",
        "src/test/**",
        "src/**/*.d.ts",
        "**/node_modules/**",
        "dist/**",
        "coverage/**",
        "*.config.{ts,js}",
      ],
    },
  },
});
