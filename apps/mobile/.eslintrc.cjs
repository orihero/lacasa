// See apps/web/.eslintrc.cjs for why require.resolve(...) is used here
// instead of the bare '@lacasa/config-eslint/react' specifier.
module.exports = {
  root: true,
  extends: [require.resolve('@lacasa/config-eslint/react')],
  env: {
    // React Native has no DOM, but it does expose the same fetch/console/
    // timer globals `env.browser` already declares — reusing it (rather
    // than hand-rolling a native globals list) keeps this in sync with
    // apps/web's config with zero extra maintenance.
    browser: true,
    node: true,
  },
  ignorePatterns: ['dist', '.expo', 'web-build', '.eslintrc.cjs', 'coverage'],
};
