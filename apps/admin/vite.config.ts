import { fileURLToPath, URL } from "node:url";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// Port 5275, strictPort — 5273 is apps/web and 5274 is apps/console, and all
// three are expected to run side by side (apps/api/src/lib/config.js lists all
// three in its CORS example). strictPort — rather than Vite's default "take the
// next free port" — matters more on THIS surface than anywhere else: it hands
// out destructive power over other people's accounts, and an admin who
// bookmarked :5275 must never find the agent console answering there because
// the admin app quietly slid to :5276.
//
// NO `resolve.dedupe` HERE, DELIBERATELY. The previous build of this app ran
// React 19 while apps/web ran React 18, so npm's hoister left a React 18 copy
// at the repo root and nested this app's React 19 one arm's length away — and
// packages hoisted to the root (react-router-dom, react-query) resolved their
// own `require("react")` to the root's 18, putting two dispatchers in one
// render tree. `dedupe` was the fix for that split. This rebuild is on React
// 18.2.0, pinned to the same range as apps/web, so there is exactly one React
// in the workspace and nothing left to deduplicate. If a future workspace
// moves off 18 and the "Invalid hook call" symptom comes back, that comment
// is the history — reinstate dedupe here and in vitest.config.ts together.
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
  },
  server: {
    port: 5275,
    strictPort: true,
  },
});
