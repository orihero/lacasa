// See apps/web/.eslintrc.cjs for why require.resolve(...) is used here
// instead of bare '@lacasa/config-eslint/*' specifiers.
module.exports = {
  root: true,
  extends: [
    require.resolve('@lacasa/config-eslint/node'),
    require.resolve('@lacasa/config-eslint/boundaries'),
  ],
  ignorePatterns: ['dist', 'node_modules', 'coverage'],
};
