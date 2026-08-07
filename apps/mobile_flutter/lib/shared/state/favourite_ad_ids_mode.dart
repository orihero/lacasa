/// Chooses which [FavouriteAdIdsRepository] every screen's heart control
/// runs on: bundled fixtures (default) or the real [LaCasaApi] — the same
/// compile-time-switch idiom `features/home/data/home_feed_mode.dart`
/// established (see that file's doc comment for the full rationale on why
/// this is a dedicated `bool.fromEnvironment` flag rather than something
/// derived from `lib/api/env.dart#apiBaseUrl`).
///
/// Deliberately its **own** flag rather than reusing
/// `LACASA_HOME_LIVE_API`: favourites are shared state read by multiple
/// features now, so they get a name that doesn't imply a "home" scope.
/// Both flags default OFF (fixtures), so a plain `flutter run`/`flutter
/// test` with neither define set behaves exactly as before this seam was
/// promoted — only a build that explicitly opts into live data needs to
/// know these are now two separate switches.
///
/// **To point favourites at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_FAVOURITES_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
const bool useLiveFavouritesApi = bool.fromEnvironment(
  'LACASA_FAVOURITES_LIVE_API',
);
