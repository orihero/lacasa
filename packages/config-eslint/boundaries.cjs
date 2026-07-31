/**
 * @lacasa/config-eslint/boundaries — mechanical architecture boundaries.
 * Not extended by default; opt in from a workspace's own .eslintrc.cjs
 * (packages/domain and packages/api-client do this today).
 *
 * Enforces:
 *  1. import/no-restricted-paths — apps/* may not reach into another
 *     app's internals, and packages/domain + packages/api-client may not
 *     import from apps/* at all (they must stay framework/app agnostic).
 *  2. no-restricted-globals for window/document/localStorage/navigator,
 *     scoped to packages/domain/** and packages/api-client/src/core/**.
 *  3. no-restricted-syntax banning `import.meta` (MetaProperty), same
 *     scope as (2) — those trees must stay bundler-agnostic too.
 */
const path = require('path');

// Resolve once, from this file's own location, so the zones are correct
// no matter which workspace directory ESLint's cwd happens to be (npm
// workspaces run `lint` with cwd = the workspace, not the repo root).
const repoRoot = path.resolve(__dirname, '..', '..');
const apps = (name) => path.join(repoRoot, 'apps', name, 'src');
const pkg = (name) => path.join(repoRoot, 'packages', name, 'src');

module.exports = {
  plugins: ['import'],
  rules: {
    'import/no-restricted-paths': [
      'error',
      {
        zones: [
          { target: apps('web'), from: [apps('api'), apps('extension')] },
          { target: apps('api'), from: [apps('web'), apps('extension')] },
          { target: apps('extension'), from: [apps('web'), apps('api')] },
          {
            target: [pkg('domain'), pkg('api-client')],
            from: path.join(repoRoot, 'apps'),
          },
        ],
      },
    ],
  },
  overrides: [
    {
      files: [
        '**/packages/domain/**/*.{js,jsx,ts,tsx}',
        '**/packages/api-client/src/core/**/*.{js,jsx,ts,tsx}',
      ],
      rules: {
        'no-restricted-globals': [
          'error',
          'window',
          'document',
          'localStorage',
          'navigator',
        ],
        'no-restricted-syntax': [
          'error',
          {
            selector: 'MetaProperty',
            message:
              'import.meta is bundler/browser-specific and must not be used in framework-agnostic shared code.',
          },
        ],
      },
    },
  ],
};
