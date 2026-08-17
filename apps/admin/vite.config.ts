import { fileURLToPath, URL } from "node:url";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// Port 5275, strictPort — 5273 is apps/web and 5274 is apps/console, and all
// three are expected to run side by side. strictPort (rather than Vite's
// default "take the next free port") matters more here than anywhere else:
// this surface hands out destructive power over other people's accounts, and
// an admin who bookmarked :5275 must never find the agent console answering
// there because the admin app quietly slid to :5276.
//
// dedupe: apps/web still runs React 18, so npm's workspace hoister leaves a
// React 18 copy at the repo root and nests this app's React 19 one arm's
// length away in apps/admin/node_modules. react-router-dom, react-query and
// @phosphor-icons/react satisfy every workspace's semver range with a single
// copy, so npm hoists THEM to the root too — where their internal `require
// ("react")` resolves to the root's React 18, not our nested React 19. Two
// live React copies in one render tree means two dispatchers, which throws
// ("Invalid hook call" / "Objects are not valid as a React child") the moment
// any hook fires inside those hoisted packages. `dedupe` makes Vite's own
// resolver — which every import in the module graph goes through, including
// ones inside node_modules — answer every `import "react"`/`"react-dom"`
// with the exact same file, so there is only ever one dispatcher.
export default defineConfig({
  plugins: [react()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
    dedupe: ["react", "react-dom"],
  },
  server: {
    port: 5275,
    strictPort: true,
  },
});
