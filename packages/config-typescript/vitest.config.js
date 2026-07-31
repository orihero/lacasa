import { nodePreset } from '@lacasa/config-vitest/node';

export default nodePreset({
  test: {
    // JSON config files, not source — coverage thresholds don't apply.
    coverage: { enabled: false },
  },
});
