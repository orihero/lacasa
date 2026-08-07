/// Chooses which [SearchRepository] `listing-search` runs on: bundled
/// fixtures (default) or the real [LaCasaApi]. Exact same pattern and
/// rationale as `features/home/data/home_feed_mode.dart` — its own doc
/// comment explains why this is a screen-local compile-time switch rather
/// than reading `lib/api/env.dart` directly. Independent from
/// `LACASA_HOME_LIVE_API`/`LACASA_FAVOURITES_LIVE_API` — flipping one does
/// not flip the others.
///
/// **To point `listing-search` at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_SEARCH_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
const bool useLiveSearchApi = bool.fromEnvironment('LACASA_SEARCH_LIVE_API');
