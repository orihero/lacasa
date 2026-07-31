import { nodePreset } from '@lacasa/config-vitest/node';

// packages/domain is pure contract code with no framework glue — hold it
// to a higher coverage bar than the shared 80% default.
export default nodePreset({
  test: {
    coverage: {
      thresholds: {
        lines: 95,
        functions: 95,
        branches: 95,
        statements: 95,
      },
    },
  },
});
