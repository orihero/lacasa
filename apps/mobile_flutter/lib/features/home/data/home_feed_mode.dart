/// Chooses which [HomeFeedRepository] the Home feed screen runs on:
/// bundled fixtures (default) or the real [LaCasaApi].
///
/// The build task asked to wire this "when the base URL is unset" — but
/// `lib/api/env.dart#apiBaseUrl` is `String.fromEnvironment(...,
/// defaultValue: 'http://localhost:4200/api')`, which collapses "no
/// `--dart-define` was passed" and "the default was passed explicitly"
/// into the same value; there is no way to tell those two apart from
/// outside `lib/api/`, and this feature is scoped to `lib/features/home/`
/// only (`lib/api/env.dart` is not this task's to edit). So this
/// introduces its own compile-time switch instead, defaulting OFF —
/// fixtures by default, which is also the safer default given the build
/// task's hard requirement that this screen "must render sensibly with NO
/// network available, because that is how it will be verified."
///
/// **To point the Home feed at a real running API:**
/// ```
/// flutter run \
///   --dart-define=LACASA_HOME_LIVE_API=true \
///   --dart-define=LACASA_API_BASE_URL=http://<host>:4200/api
/// ```
/// (the second define is `lib/api/env.dart`'s own switch — both are needed
/// together for a non-Android-emulator target).
const bool useLiveHomeFeedApi = bool.fromEnvironment('LACASA_HOME_LIVE_API');
