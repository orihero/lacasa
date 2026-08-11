/// Chooses which [SavedListingsRepository] `saved-listings` runs on: the
/// real [LaCasaApi] (default) or bundled fixtures — resolved through
/// `lib/api/app_mode.dart`, the single source of truth every
/// `*_mode.dart` switch's default now defers to. A dedicated flag rather
/// than reusing `LACASA_FAVOURITES_LIVE_API`: that switch governs the
/// id-only favourite *set* every heart control reads, while this one governs
/// the full [Ad] payload this screen renders cards from — two different
/// fetches of the same underlying `GET /api/saved-ads` data (see
/// `saved_listings_repository.dart`'s doc comment for why both exist
/// independently rather than one screen borrowing the other's fetch).
///
/// **To force this screen to fixtures:**
/// ```
/// flutter run --dart-define=LACASA_SAVED_LISTINGS_LIVE_API=false
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
final bool useLiveSavedListingsApi = resolveUseLiveApi(
  const String.fromEnvironment(
    'LACASA_SAVED_LISTINGS_LIVE_API',
    defaultValue: '',
  ),
);
