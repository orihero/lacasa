/**
 * @lacasa/crosspost-protocol — the shared wire contract between apps/web,
 * apps/api, and apps/extension for cross-posting listings (OLX, Instagram,
 * ...), built on @lacasa/domain's enums. This barrel re-exports both
 * sub-modules; consumers that only need one side of the wire may also
 * import the subpath directly (`@lacasa/crosspost-protocol/messages` or
 * `@lacasa/crosspost-protocol/background`) to keep bundles lean.
 */
export * from './messages';
export * from './background';

export const CROSSPOST_PROTOCOL_PACKAGE_NAME = '@lacasa/crosspost-protocol';
