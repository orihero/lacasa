import { mergeConfig } from 'vitest/config';
import { reactPreset } from '@lacasa/config-vitest/react';
import viteConfig from './vite.config.js';

// Merge with the real vite.config.js (not just the shared preset) so
// tests go through the same @vitejs/plugin-react JSX transform as the
// actual app build/dev server — without it, JSX in .jsx test files has
// no automatic React import and fails at runtime.
export default mergeConfig(viteConfig, reactPreset());
