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
    // Appended to (not replacing) the shared react preset's own setup file —
    // vite's mergeConfig concatenates arrays. See src/test/setup.ts for why
    // this workspace needs one of its own.
    setupFiles: ["./src/test/setup.ts"],
    // The shared react preset sets a 40% floor calibrated to apps/web's
    // largely untested legacy UI. This app starts clean, so it starts higher —
    // raise it as screens land rather than letting it drift down.
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
