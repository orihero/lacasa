import { nodePreset } from '@lacasa/config-vitest/node';

export default nodePreset({
  test: {
    // ESLint config fragments, not source under test for coverage.
    coverage: { enabled: false },
  },
});
