import { nodePreset } from '@lacasa/config-vitest/node';

// Content-script logic touches DOM APIs (autofill, banner injection),
// so this runs under jsdom rather than the plain node preset's default.
export default nodePreset({
  test: {
    environment: 'jsdom',
    // Ratchet floors set just under measured coverage (24.56 stmts /
    // 80.67 branch / 75.86 func). Statement coverage is low because the
    // bulk of this workspace is site-specific autofill selectors that only
    // a real OLX/Instagram page exercises; the branching logic that is
    // worth testing — dom-snapshot and dom-executor — is well covered.
    coverage: {
      thresholds: { lines: 22, statements: 22, branches: 78, functions: 73 },
    },
  },
});
