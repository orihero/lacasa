/// Chooses which [MyListingsRepository] `my-listings` runs on: the real
/// [LaCasaApi] (default) or bundled fixtures — resolved through
/// `lib/api/app_mode.dart`, the single source of truth every
/// `*_mode.dart` switch's default now defers to. Independent from every
/// other feature's own `LACASA_*_LIVE_API` switch — forcing one to
/// fixtures does not force the others.
///
/// **To force `my-listings` to fixtures:**
/// ```
/// flutter run --dart-define=LACASA_MY_LISTINGS_LIVE_API=false
/// ```
///
/// **To point `my-listings` at a specific non-default API host:**
/// ```
/// flutter run \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

import '../../../api/app_mode.dart';

/// `final`, not `const` — see `app_mode.dart`'s doc comment for why the
/// default now depends on a runtime check.
final bool useLiveMyListingsApi = resolveUseLiveApi(
  const String.fromEnvironment('LACASA_MY_LISTINGS_LIVE_API', defaultValue: ''),
);
