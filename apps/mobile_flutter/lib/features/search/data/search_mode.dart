/// Chooses which [SearchRepository] `listing-search` runs on: the real
/// [LaCasaApi] (default) or bundled fixtures — resolved through
/// `lib/api/app_mode.dart`, the single source of truth every
/// `*_mode.dart` switch's default now defers to. Independent from
/// `LACASA_HOME_LIVE_API`/`LACASA_FAVOURITES_LIVE_API` — forcing one to
/// fixtures does not force the others.
///
/// **To force `listing-search` to fixtures:**
/// ```
/// flutter run --dart-define=LACASA_SEARCH_LIVE_API=false
/// ```
///
/// **To point `listing-search` at a specific non-default API host:**
/// ```
/// flutter run \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

import '../../../api/app_mode.dart';

/// `final`, not `const` — see `app_mode.dart`'s doc comment for why the
/// default now depends on a runtime check.
final bool useLiveSearchApi = resolveUseLiveApi(
  const String.fromEnvironment('LACASA_SEARCH_LIVE_API', defaultValue: ''),
);
