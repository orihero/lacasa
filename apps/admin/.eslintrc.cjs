// See apps/web/.eslintrc.cjs for why this uses require.resolve(...) rather
// than the bare specifier '@lacasa/config-eslint/react': ESLint 8 mangles
// "@scope/pkg/subpath" extends into "@scope/eslint-config-pkg/subpath" and
// ignores package.json "exports", so an already-resolved absolute path is the
// only form that works.
module.exports = {
  root: true,
  extends: [require.resolve('@lacasa/config-eslint/react')],
  settings: {
    react: { version: '18.2' },
  },
  ignorePatterns: ['dist', 'coverage', '.eslintrc.cjs', '*.config.js'],
}
