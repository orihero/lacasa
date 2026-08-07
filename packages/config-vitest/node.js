// @lacasa/config-vitest/node — preset for framework-agnostic Node
// workspaces (apps/api, packages/domain, packages/api-client, ...).
import { defineConfig, mergeConfig } from 'vitest/config';

export const baseNodeConfig = defineConfig({
  test: {
    environment: 'node',
    coverage: {
      provider: 'v8',
      reporter: ['text', 'html', 'lcov'],
      thresholds: {
        lines: 80,
        functions: 80,
        branches: 80,
        statements: 80,
      },
    },
  },
});

/**
 * @param {import('vitest/config').UserConfig} overrides
 */
export function nodePreset(overrides = {}) {
  return mergeConfig(baseNodeConfig, defineConfig(overrides));
}

export default baseNodeConfig;
