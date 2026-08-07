/// Chooses which [AuthRepository] the app runs on: bundled fixtures
/// (default) or the real [LaCasaApi]. Same pattern and rationale as
/// `features/agents/data/agents_mode.dart` — a screen-local compile-time
/// switch rather than a read of `lib/api/env.dart`, so flipping this
/// feature to live does not drag every other feature's fixtures with it.
///
/// Unlike most of this app's fixtures, going live here changes more than
/// what one screen renders: it is what makes a session (and therefore the
/// role-aware tab bar, and everything behind the Work tab) real instead of
/// simulated. `FixtureAuthRepository`'s own doc comment covers what "not
/// live" still gets you for free — a persisted session that survives a
/// relaunch, without a server.
///
/// **To point auth at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_AUTH_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

const bool useLiveAuthApi = bool.fromEnvironment('LACASA_AUTH_LIVE_API');
