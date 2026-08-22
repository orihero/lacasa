/**
 * @lacasa/config-vitest ships plain `.js` with no declaration files for its
 * subpath exports (`./react`, `./react/server`), so every TS-strict consumer
 * hits TS7016 importing them — here that is vitest.config.ts's
 * `@lacasa/config-vitest/react` import. Fixing the package itself is outside
 * this workspace's owned paths; this ambient declaration is scoped to the one
 * subpath this app actually imports.
 *
 * Lives under src/test/ (and is listed in tsconfig.node.json's `include`
 * alongside the config files it exists for) rather than at the workspace root,
 * mirroring where apps/console keeps its copy.
 */
declare module "@lacasa/config-vitest/react" {
  import type { UserConfig } from "vitest/config";

  export function reactPreset(overrides?: UserConfig): UserConfig;
  const baseReactConfig: UserConfig;
  export default baseReactConfig;
}
