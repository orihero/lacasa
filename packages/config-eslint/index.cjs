/**
 * @lacasa/config-eslint — base ESLint config shared by every workspace.
 * eslint:recommended plus the parser options every workspace (ESM, plain
 * JS/JSX or TS/TSX) needs. `react.cjs` and `node.cjs` both extend this.
 *
 * Includes a TypeScript override so *.ts/*.tsx parse correctly wherever
 * this is the first (or only) TS-aware lint pass — some apps/web .tsx
 * files already use real TS syntax (type annotations) that the default
 * parser (espree) cannot parse at all. It intentionally does NOT pull in
 * `plugin:@typescript-eslint/recommended` (which turns many rules on as
 * errors) — only the base-rule/TS-syntax conflicts are disabled, and the
 * one TS-specific rule we do want is a warning, not an error, so a
 * first-ever lint pass stays green.
 */
module.exports = {
  extends: ['eslint:recommended'],
  parserOptions: {
    ecmaVersion: 'latest',
    sourceType: 'module',
  },
  env: {
    es2022: true,
  },
  ignorePatterns: ['dist', 'node_modules', '.eslintrc.cjs'],
  rules: {
    // The `_`-prefix convention this codebase already writes (`_req`, `_next`)
    // is honoured explicitly, because some of those parameters are required
    // even though they are unused — Express identifies an error handler by its
    // arity, so deleting a trailing `_next` to appease this rule breaks the
    // handler. Warning on it invites exactly that fix.
    'no-unused-vars': ['warn', { argsIgnorePattern: '^_', varsIgnorePattern: '^_' }],
  },
  overrides: [
    {
      files: ['**/*.ts', '**/*.tsx'],
      parser: '@typescript-eslint/parser',
      parserOptions: {
        ecmaVersion: 'latest',
        sourceType: 'module',
        ecmaFeatures: { jsx: true },
      },
      plugins: ['@typescript-eslint'],
      rules: {
        // TypeScript itself (via `typecheck`) already catches these; the
        // base JS versions false-positive on TS-only syntax (overloads,
        // ambient types, declaration merging, etc).
        'no-undef': 'off',
        'no-unused-vars': 'off',
        'no-redeclare': 'off',
        'no-dupe-class-members': 'off',
        'no-use-before-define': 'off',
        // Same `_`-prefix convention as the base rule above.
        '@typescript-eslint/no-unused-vars': [
          'warn',
          { argsIgnorePattern: '^_', varsIgnorePattern: '^_' },
        ],
      },
    },
  ],
};
