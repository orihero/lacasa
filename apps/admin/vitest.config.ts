import { fileURLToPath, URL } from "node:url";
import react from "@vitejs/plugin-react";
import { reactPreset } from "@lacasa/config-vitest/react";

export default reactPreset({
  plugins: [react()],
  resolve: {
    alias: {
      "@": fileURLToPath(new URL("./src", import.meta.url)),
    },
    // Same nested-React-19-vs-hoisted-React-18 split as vite.config.ts (see
    // the comment there) — vitest needs the identical fix, or a real
    // MemoryRouter/QueryClientProvider/@phosphor-icons/react component
    // crashes with a mismatched-dispatcher error the instant it mounts.
    dedupe: ["react", "react-dom"],
  },
  test: {
    globals: true,
    server: {
      deps: {
        // resolve.dedupe above is necessary but NOT sufficient under vitest.
        // Vitest externalizes node_modules packages by default, so a hoisted
        // dependency is loaded through Node's own resolution and never passes
        // through Vite's resolver — which is the only thing dedupe hooks into.
        // @phosphor-icons/react sits at the repo root (one copy satisfies every
        // workspace), so externalized it resolves `react/jsx-runtime` relative
        // to ITSELF and gets apps/web's React 18, then hands React 19 elements
        // it does not recognise: "A React Element from an older version of
        // React was rendered." Inlining it puts the package back in the module
        // graph, where dedupe applies and there is one React again.
        // Only bites when a test actually mounts an icon — see
        // shell/__tests__/ErrorBoundary.test.tsx, the first one that did.
        inline: ["@phosphor-icons/react"],
      },
    },
    // Appended to (not replacing) the shared react preset's own setup file —
    // vite's mergeConfig concatenates arrays. See src/test/setup.ts for why
    // this workspace needs one of its own.
    setupFiles: ["./src/test/setup.ts"],
    // The shared react preset's 40% floor is calibrated to apps/web's largely
    // untested legacy UI. This app starts clean, so it starts higher — the
    // four feature screens land after this scaffold and are expected to raise
    // it further, never to lower it.
    coverage: {
      thresholds: { lines: 50, functions: 50, branches: 50, statements: 50 },
      exclude: [
        "src/main.tsx",
        "src/**/*.d.ts",
        "**/node_modules/**",
        "dist/**",
        "coverage/**",
        "*.config.{ts,js}",
      ],
    },
  },
});
