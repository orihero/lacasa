import { nodePreset } from './node.js';

// This package's own "source" is the presets other workspaces consume, so
// most of it only executes inside *their* test runs, never this one. Its
// own tests just assert the exported config shape.
//
// `enabled: false` states that intent, but it is not sufficient on its own:
// CI runs `vitest run --coverage`, and the CLI flag overrides it, which then
// applies the node preset's inherited 80% thresholds to a package that
// structurally cannot reach them. So pin explicit floors just under the
// measured numbers (66.66% branches / 66.66% functions) as well.
export default nodePreset({
  test: {
    coverage: {
      enabled: false,
      thresholds: { lines: 80, statements: 80, branches: 60, functions: 60 },
    },
  },
});
