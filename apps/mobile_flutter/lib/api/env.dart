/// The API base URL, resolved at compile time from `--dart-define`
/// (`--dart-define=LACASA_API_BASE_URL=https://...`). Mirrors
/// `apps/mobile/src/lib/httpTransport.ts#resolveBaseUrl`'s fallback: same
/// default, same "prepended verbatim to every request path" contract as
/// `@lacasa/api-client`'s `CreateApiClientOptions.baseUrl`.
///
/// `10.0.2.2` is the Android emulator's alias for the host machine's
/// `localhost`; a real device or iOS simulator dev build needs an explicit
/// `--dart-define` pointing at the host's LAN address instead — this
/// default only covers the Android-emulator-against-a-local-API case.
library;

const String _defaultBaseUrl = 'http://localhost:4200/api';

/// The resolved base URL every [ApiClient] request is prefixed with.
const String apiBaseUrl = String.fromEnvironment(
  'LACASA_API_BASE_URL',
  defaultValue: _defaultBaseUrl,
);
