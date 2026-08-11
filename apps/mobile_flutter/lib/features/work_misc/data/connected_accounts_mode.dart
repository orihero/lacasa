/// Chooses which [ConnectedAccountsRepository] `connected-accounts` runs
/// on: the real [LaCasaApi] (default) or bundled fixtures — resolved
/// through `lib/api/app_mode.dart`, the single source of truth every
/// `*_mode.dart` switch's default now defers to.
///
/// **To force this screen to fixtures:**
/// ```
/// flutter run --dart-define=LACASA_CONNECTED_ACCOUNTS_LIVE_API=false
/// ```
///
/// **To point this screen at a specific non-default API host:**
/// ```
/// flutter run \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

import '../../../api/app_mode.dart';

/// `final`, not `const` — see `app_mode.dart`'s doc comment for why the
/// default now depends on a runtime check.
final bool useLiveConnectedAccountsApi = resolveUseLiveApi(
  const String.fromEnvironment(
    'LACASA_CONNECTED_ACCOUNTS_LIVE_API',
    defaultValue: '',
  ),
);
