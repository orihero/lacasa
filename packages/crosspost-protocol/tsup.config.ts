import { defineConfig } from 'tsup';

// Keys become the flat dist/<key>.{js,cjs,d.ts} output name, matching the
// package.json "./*" exports subpath pattern — e.g. `messages` here backs
// the `@lacasa/crosspost-protocol/messages` subpath (see packages/domain's
// tsup.config.ts for the same convention).
export default defineConfig({
  entry: {
    index: 'src/index.ts',
    messages: 'src/messages.ts',
    background: 'src/background.ts',
  },
  format: ['esm', 'cjs'],
  dts: true,
  sourcemap: true,
  clean: true,
  outDir: 'dist',
  target: 'es2022',
});
