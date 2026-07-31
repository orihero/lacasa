/**
 * @lacasa/config-eslint/react — reproduces apps/web's pre-migration
 * .eslintrc.cjs exactly (same extends/env/settings/rules) so repointing
 * apps/web at this shared config is a no-op for lint results.
 */
module.exports = {
  extends: [
    require.resolve('./index.cjs'),
    'plugin:react/recommended',
    'plugin:react/jsx-runtime',
    'plugin:react-hooks/recommended',
  ],
  env: {
    browser: true,
    es2020: true,
  },
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  settings: {
    react: { version: '18.2' },
  },
  plugins: ['react-refresh'],
  rules: {
    'react/prop-types': 'off',
    // Not 'no-unused-vars': 'warn' here — that's already the base
    // (index.cjs) default, and re-asserting it here would win over (and
    // so silently undo) index.cjs's per-file override that turns it off
    // in favor of @typescript-eslint/no-unused-vars for *.ts/*.tsx,
    // since this config's own top-level rules apply after configs it
    // extends in ESLint's cascade.
    'react/jsx-no-target-blank': 'off',
    'react-refresh/only-export-components': [
      'warn',
      { allowConstantExport: true },
    ],
  },
};
