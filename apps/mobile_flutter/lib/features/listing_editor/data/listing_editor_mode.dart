/// Chooses which [ListingEditorRepository] the feature's four screens run
/// on: bundled fixtures (default) or the real [LaCasaApi]. Same
/// compile-time-switch shape as every other feature's own `*_mode.dart` —
/// see `features/home/data/home_feed_mode.dart` for the pattern this
/// mirrors.
///
/// ```
/// flutter run \
///   --dart-define=LACASA_LISTING_EDITOR_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
const bool useLiveListingEditorApi = bool.fromEnvironment(
  'LACASA_LISTING_EDITOR_LIVE_API',
);
