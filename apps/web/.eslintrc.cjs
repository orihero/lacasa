// NOTE: `extends` uses require.resolve(...) rather than the bare
// specifier '@lacasa/config-eslint/react'. ESLint 8's shareable-config
// naming convention mangles any bare "@scope/pkg/subpath" extend into
// "@scope/eslint-config-pkg/subpath" before resolving it — it doesn't
// respect package.json "exports" subpaths the way Node's require() does.
// Passing an already-resolved absolute path sidesteps that entirely.
module.exports = {
  root: true,
  extends: [require.resolve('@lacasa/config-eslint/react')],
  ignorePatterns: ['dist', '.eslintrc.cjs', 'server', 'coverage'],
}
