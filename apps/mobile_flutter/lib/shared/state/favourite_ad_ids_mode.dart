/// Chooses which [FavouriteAdIdsRepository] every screen's heart control
/// runs on: the real [LaCasaApi] (default) or bundled fixtures — resolved
/// through `lib/api/app_mode.dart`, the single source of truth every
/// `*_mode.dart` switch's default now defers to.
///
/// Deliberately its **own** flag rather than reusing
/// `LACASA_HOME_LIVE_API`: favourites are shared state read by multiple
/// features, so they get a name that doesn't imply a "home" scope. Both
/// flags share the same global default via `app_mode.dart`, so a plain
/// `flutter run`/`flutter test` with no per-feature define set behaves
/// consistently across every feature — only a build that explicitly wants
/// fixtures needs to know these are separate switches.
///
/// **To force favourites to fixtures:**
/// ```
/// flutter run --dart-define=LACASA_FAVOURITES_LIVE_API=false
/// ```
///
/// **To point favourites at a specific non-default API host:**
/// ```
/// flutter run \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

import '../../api/app_mode.dart';

/// `final`, not `const` — see `app_mode.dart`'s doc comment for why the
/// default now depends on a runtime check.
final bool useLiveFavouritesApi = resolveUseLiveApi(
  const String.fromEnvironment('LACASA_FAVOURITES_LIVE_API', defaultValue: ''),
);
