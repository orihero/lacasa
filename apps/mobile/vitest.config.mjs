import { nodePreset } from '@lacasa/config-vitest/node';

// apps/mobile's only testable-in-isolation logic today is httpTransport.ts
// (the Transport/TokenStorage adapters) — src/screens is UI, exercised by
// `expo export`/manual runs rather than vitest, and apiClient.ts is pure
// wiring with no branches (same as apps/web's untested src/lib/apiClient.js).
// Scoping coverage to the one file with real logic keeps the threshold
// meaningful instead of papering over untested UI/wiring with a low
// blanket number.
export default nodePreset({
  test: {
    coverage: {
      include: ['src/lib/httpTransport.ts'],
      thresholds: {
        lines: 90,
        functions: 90,
        branches: 90,
        statements: 90,
      },
    },
  },
});
