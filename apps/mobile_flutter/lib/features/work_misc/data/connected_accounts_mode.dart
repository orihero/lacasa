/// Chooses which [ConnectedAccountsRepository] `connected-accounts` runs
/// on: bundled fixtures (default) or the real [LaCasaApi] — same idiom as
/// `features/agents/data/agents_mode.dart`.
///
/// **To point this screen at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_CONNECTED_ACCOUNTS_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

const bool useLiveConnectedAccountsApi = bool.fromEnvironment(
  'LACASA_CONNECTED_ACCOUNTS_LIVE_API',
);
