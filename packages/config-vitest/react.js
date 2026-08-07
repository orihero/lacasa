// @lacasa/config-vitest/react — preset for React UI workspaces
// (apps/web). jsdom + @testing-library/jest-dom + msw wiring.
import { fileURLToPath } from 'node:url';
import { defineConfig, mergeConfig } from 'vitest/config';

const setupFile = fileURLToPath(
  new URL('./setup/react.setup.js', import.meta.url),
);

export const baseReactConfig = defineConfig({
  test: {
    environment: 'jsdom',
    setupFiles: [setupFile],
    // web is mostly untested UI today — 40% is the honest starting bar,
    // raise it as suites are backfilled.
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      thresholds: {
        lines: 40,
        functions: 40,
        branches: 40,
        statements: 40,
      },
    },
  },
});

/**
 * @param {import('vitest/config').UserConfig} overrides
 */
export function reactPreset(overrides = {}) {
  return mergeConfig(baseReactConfig, defineConfig(overrides));
}

export default baseReactConfig;
