/**
 * @lacasa/domain — framework-agnostic contracts (enums, validators,
 * formatters, and zod schemas) shared across apps/web, apps/api, and
 * apps/extension.
 *
 * Every module here is also reachable as its own subpath (e.g.
 * `@lacasa/domain/enums`, `@lacasa/domain/validators/phone`) for callers
 * that only want one slice of the package; this root entry point re-exports
 * the full public surface for convenience.
 */

// Kept stable for packages/api-client and packages/crosspost-protocol,
// which already depend on this identifier and function to prove their own
// workspace-dependency wiring resolves end to end.
export const DOMAIN_PACKAGE_NAME = '@lacasa/domain';

export function ping(): 'pong' {
  return 'pong';
}

export * from './enums';

export * from './ads/caption';
export * from './ads/currency';

export * from './validators/phone';

export * from './leads/transitions';

export * from './formatting/date';

export * from './schemas/ad';
export * from './schemas/lead';
export * from './schemas/user';
export * from './schemas/publish';

export * from './errors';
