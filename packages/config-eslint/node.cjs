/**
 * @lacasa/config-eslint/node — for Node/ESM workspaces (apps/api,
 * apps/extension, and the shared packages). The TypeScript override
 * lives in the base config (./index.cjs) so both this and react.cjs
 * get it.
 */
module.exports = {
  extends: [require.resolve('./index.cjs')],
  env: {
    node: true,
    es2022: true,
  },
};
