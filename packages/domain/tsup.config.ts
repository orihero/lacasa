import { defineConfig } from 'tsup';

// Keys become the flat dist/<key>.{js,cjs,d.ts} output name, which is
// exactly what the package.json "./*" exports subpath pattern expects
// (dist/*.js, dist/*.cjs, dist/*.d.ts) — e.g. `enums` here backs the
// `@lacasa/domain/enums` subpath.
export default defineConfig({
  entry: {
    index: 'src/index.ts',
    enums: 'src/enums/index.ts',
    'enums/ads': 'src/enums/ads.ts',
    'enums/leads': 'src/enums/leads.ts',
    'enums/events': 'src/enums/events.ts',
    'enums/publish': 'src/enums/publish.ts',
    'ads/caption': 'src/ads/caption.ts',
    'ads/currency': 'src/ads/currency.ts',
    'validators/phone': 'src/validators/phone.ts',
    'leads/transitions': 'src/leads/transitions.ts',
    'formatting/date': 'src/formatting/date.ts',
    'data/regions': 'src/data/regions.ts',
    'schemas/ad': 'src/schemas/ad.ts',
    'schemas/lead': 'src/schemas/lead.ts',
    'schemas/user': 'src/schemas/user.ts',
    'schemas/publish': 'src/schemas/publish.ts',
    errors: 'src/errors.ts',
  },
  format: ['esm', 'cjs'],
  dts: true,
  sourcemap: true,
  clean: true,
  outDir: 'dist',
  target: 'es2022',
});
