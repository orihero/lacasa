// Metro does not follow npm workspace layout by default — it only looks
// under this project's own node_modules. This wires it up to also see the
// monorepo root's node_modules (where npm hoists most shared deps) and the
// workspace packages themselves (@lacasa/domain, @lacasa/api-client, ...),
// so `import { LEAD_STATUS } from '@lacasa/domain'` resolves the same way
// it does for apps/web and apps/extension.
const path = require('node:path');
const { getDefaultConfig } = require('expo/metro-config');

const projectRoot = __dirname;
const monorepoRoot = path.resolve(projectRoot, '../..');

const config = getDefaultConfig(projectRoot);

// Watch the whole monorepo (not just this app) so Metro picks up changes
// in packages/domain and packages/api-client when they're consumed
// straight from source during local dev, not just their built dist/.
config.watchFolders = [monorepoRoot];

// Resolve node_modules from this project first, then fall back to the
// hoisted root — this is what actually lets `import { LEAD_STATUS } from
// '@lacasa/domain'` find the copy npm workspaces symlinks into
// monorepoRoot/node_modules/@lacasa/domain.
config.resolver.nodeModulesPaths = [
  path.resolve(projectRoot, 'node_modules'),
  path.resolve(monorepoRoot, 'node_modules'),
];

// disableHierarchicalLookup stays FALSE — deliberately, despite it being
// the commonly-cited setting for monorepos. Verified by hand: turning it
// on breaks this project. npm did not hoist expo-modules-core (a plain,
// single-version, non-conflicting dependency of expo itself) all the way
// up to apps/mobile/node_modules — it left it one level deeper, nested at
// apps/mobile/node_modules/expo/node_modules/expo-modules-core (confirm
// with `npm explain expo-modules-core` if npm's hoist ever shifts it).
// With disableHierarchicalLookup: true, Metro *only* consults the two
// fixed nodeModulesPaths above and never finds that nested copy, so
// `expo export --platform web` fails with "Unable to resolve module
// expo-modules-core" before it ever gets to bundling app code. Leaving
// hierarchical lookup ON makes Metro also walk up from each importing
// file through its own ancestor node_modules (same as Node/tsc/vitest
// already do), which finds both that nested expo dependency *and*
// monorepoRoot/node_modules/@lacasa/domain — nodeModulesPaths above is
// then a belt-and-suspenders explicit fallback, not the only path.

module.exports = config;
