/**
 * @lacasa/config-vitest ships plain `.js` with no declaration files for its
 * subpath exports (`./react`, `./react/server`) — every TS-strict consumer
 * hits TS7016 importing them (this shows up for both this test suite's
 * `.../react/server` import and the pre-existing `vitest.config.ts`'s
 * `.../react` import, since tsc compiles this whole workspace as one
 * program). Fixing the package itself is out of this agent's owned paths
 * (packages/* is off limits per the build brief); this ambient declaration
 * is scoped to only the two subpaths this app actually imports.
 */
declare module '@lacasa/config-vitest/react' {
  import type { UserConfig } from 'vitest/config';

  export function reactPreset(overrides?: UserConfig): UserConfig;
  const baseReactConfig: UserConfig;
  export default baseReactConfig;
}

declare module '@lacasa/config-vitest/react/server' {
  import type { SetupServerApi } from 'msw/node';

  export const server: SetupServerApi;
}
