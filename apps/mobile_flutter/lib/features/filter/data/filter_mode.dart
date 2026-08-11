/// Chooses which [FilterRepository] `filter-sheet`'s live count preview
/// runs on: the real [LaCasaApi] (default) or bundled fixtures. Its own
/// switch, independent of `LACASA_HOME_LIVE_API` and
/// `LACASA_FAVOURITES_LIVE_API`, resolved through `lib/api/app_mode.dart`
/// — the single source of truth every `*_mode.dart` switch's default now
/// defers to.
///
/// **To force the live count preview to fixtures:**
/// ```
/// flutter run --dart-define=LACASA_FILTER_LIVE_API=false
/// ```
///
/// **To point the live count preview at a specific non-default API host:**
/// ```
/// flutter run \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

import '../../../api/app_mode.dart';

/// `final`, not `const` — see `app_mode.dart`'s doc comment for why the
/// default now depends on a runtime check.
final bool useLiveFilterApi = resolveUseLiveApi(
  const String.fromEnvironment('LACASA_FILTER_LIVE_API', defaultValue: ''),
);
