import { fileURLToPath, URL } from "node:url";
import react from "@vitejs/plugin-react";
import { defineConfig } from "vite";

// Port 5274 — apps/web holds 5273 (strictPort), and both run side by side for
// the whole of the console's parity push.
//
// dedupe: apps/web still runs React 18, so npm's workspace hoister leaves a
// React 18 copy at the repo root and nests this app's React 19 one arm's
// length away in apps/console/node_modules. react-router-dom, react-query and
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
    port: 5274,
    strictPort: true,
  },
});
