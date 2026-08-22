import { mergeConfig } from 'vitest/config';
import { reactPreset } from '@lacasa/config-vitest/react';
import viteConfig from './vite.config.js';

// Merge with the real vite.config.js (not just the shared preset) so
// tests go through the same @vitejs/plugin-react JSX transform as the
// actual app build/dev server — without it, JSX in .jsx test files has
// no automatic React import and fails at runtime.
export default mergeConfig(
  viteConfig,
  reactPreset({
    test: {
      // Ratchet floors set just under measured coverage (24.95 stmts /
      // 49.26 branch / 19.83 func) rather than at the react preset's
      // aspirational 40%. Most of this workspace is presentational
      // components with no business logic — the rules worth testing were
      // extracted into @lacasa/domain, which sits at 100%. These exist to
      // catch regressions; raise them as component suites are backfilled.
      coverage: {
        thresholds: { lines: 22, statements: 22, branches: 46, functions: 18 },
      },
    },
  }),
);
