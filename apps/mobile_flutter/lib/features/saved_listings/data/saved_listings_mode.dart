/// Chooses which [SavedListingsRepository] `saved-listings` runs on: bundled
/// fixtures (default) or the real [LaCasaApi] — the same screen-local
/// compile-time-switch idiom `features/agents/data/agents_mode.dart` and
/// `shared/state/favourite_ad_ids_mode.dart` establish. A dedicated flag
/// rather than reusing `LACASA_FAVOURITES_LIVE_API`: that switch governs the
/// id-only favourite *set* every heart control reads, while this one governs
/// the full [Ad] payload this screen renders cards from — two different
/// fetches of the same underlying `GET /api/saved-ads` data (see
/// `saved_listings_repository.dart`'s doc comment for why both exist
/// independently rather than one screen borrowing the other's fetch).
///
/// **To point this screen at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_SAVED_LISTINGS_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

const bool useLiveSavedListingsApi = bool.fromEnvironment(
  'LACASA_SAVED_LISTINGS_LIVE_API',
);
