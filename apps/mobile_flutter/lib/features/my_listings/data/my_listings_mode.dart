/// Chooses which [MyListingsRepository] `my-listings` runs on: bundled
/// fixtures (default) or the real [LaCasaApi]. Exact same pattern and
/// rationale as `features/search/data/search_mode.dart` — its own doc
/// comment explains why this is a screen-local compile-time switch rather
/// than reading `lib/api/env.dart` directly. Independent from every other
/// feature's own `LACASA_*_LIVE_API` switch — flipping one does not flip
/// the others.
///
/// **To point `my-listings` at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_MY_LISTINGS_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
const bool useLiveMyListingsApi = bool.fromEnvironment(
  'LACASA_MY_LISTINGS_LIVE_API',
);
