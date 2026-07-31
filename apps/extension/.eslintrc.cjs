// See apps/web/.eslintrc.cjs for why require.resolve(...) is used here
// instead of the bare '@lacasa/config-eslint/node' specifier.
module.exports = {
  root: true,
  extends: [require.resolve('@lacasa/config-eslint/node')],
  env: { browser: true },
  ignorePatterns: ['dist', 'node_modules'],
};
