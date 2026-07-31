import { nodePreset } from '@lacasa/config-vitest/node';

// Content-script logic touches DOM APIs (autofill, banner injection),
// so this runs under jsdom rather than the plain node preset's default.
export default nodePreset({
  test: {
    environment: 'jsdom',
  },
});
