/// Chooses which [CoworkersRepository] the three coworker screens run on:
/// bundled fixtures (default) or the real [LaCasaApi]. Same pattern and
/// rationale as `features/agents/data/agents_mode.dart` — a screen-local
/// compile-time switch, defaulting OFF, so flipping this feature to live
/// doesn't drag any other Work-tab feature with it.
///
/// **To point the coworkers screens at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_COWORKERS_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
library;

const bool useLiveCoworkersApi = bool.fromEnvironment('LACASA_COWORKERS_LIVE_API');
