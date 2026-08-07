/// Chooses which [FilterRepository] `filter-sheet`'s live count preview
/// runs on: bundled fixtures (default) or the real [LaCasaApi]. Its own
/// switch, independent of `LACASA_HOME_LIVE_API` and
/// `LACASA_FAVOURITES_LIVE_API` — copies the exact pattern
/// `features/home/data/home_feed_mode.dart` established, defaulting OFF
/// for the same reason: fixtures-by-default is the only way this screen
/// is verifiable with no network.
///
/// **To point the live count preview at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_FILTER_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
const bool useLiveFilterApi = bool.fromEnvironment('LACASA_FILTER_LIVE_API');
