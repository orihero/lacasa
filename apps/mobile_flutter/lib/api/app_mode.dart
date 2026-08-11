/// The single source of truth for whether the app talks to the real,
/// network-backed API or to a feature's bundled fixtures — and the
/// mechanism every one of the 15 `lib/features/*/data/*_mode.dart` switches
/// resolves its own default through.
///
/// **Why the default inverted.** Until now, every `*_mode.dart` file read
/// `bool.fromEnvironment('LACASA_<FEATURE>_LIVE_API')`, which defaults to
/// `false` when the `--dart-define` isn't passed — i.e. fixtures were the
/// default and talking to the real API was the opt-in. That made sense
/// while each feature was being built and verified screen-by-screen against
/// static seed data, but it is the wrong default for an app that is
/// otherwise finished: a build with no `--dart-define`s at all — which is
/// what `flutter run`/a release build naturally is — should show real data
/// from the real backend, not 15 features quietly frozen on Milestone-2
/// seed content. So this flips the polarity everywhere at once: the app
/// talks to the live API by default, and fixtures become the explicit
/// opt-in (this file's [useLiveApiByDefault] is what every feature's
/// default now resolves through, instead of each one hand-rolling its own
/// `false`).
///
/// **Why the `flutter test` guard exists.** Inverting the default has a
/// trap: several widget tests deliberately exercise a feature's *default*
/// wiring with no repository override (e.g.
/// `test/features/home/home_feed_screen_test.dart`'s "realistic viewport,
/// real default wiring" group) specifically to catch what a fresh install
/// actually renders. If the default simply flipped to live, those same
/// tests — and every other widget test that pumps a screen without
/// overriding its repository provider — would silently start constructing
/// `LaCasaApi.create()` and firing real HTTP requests out of the test
/// process. That is a strictly worse failure mode than a test relying on
/// fixtures: a test suite with an undeclared network dependency is flaky in
/// CI, slow, and can pass or fail depending on whether some developer's
/// laptop happens to have a local API running on port 4200 — exactly the
/// class of problem `lib/shared/map/map_tile_layer_provider.dart` already
/// exists to prevent for OpenStreetMap tiles (see that file's doc comment).
/// So [useLiveApiByDefault] additionally checks [isRunningUnderFlutterTest]
/// and falls back to fixtures whenever it's true, regardless of the global
/// opt-in below — a test can still force live explicitly through its
/// feature's own per-feature override (useful for an actual integration
/// test that *wants* a real backend), but it never gets live by accident
/// just because nobody thought to override a provider.
///
/// [isRunningUnderFlutterTest] mirrors the exact predicate the Flutter
/// framework itself uses to decide `AutomatedTestWidgetsFlutterBinding` vs.
/// `LiveTestWidgetsFlutterBinding` —
/// `packages/flutter_test/lib/src/_binding_io.dart#ensureInitialized`:
/// `environment.containsKey('FLUTTER_TEST') && environment['FLUTTER_TEST']
/// != 'false'`. Verified against the Flutter 3.44.7 SDK installed for this
/// project (`flutter --version`), not assumed: `flutter_tools` sets
/// `FLUTTER_TEST=true` in the child process environment for every `flutter
/// test` invocation (`packages/flutter_tools/lib/src/test/*.dart`), and the
/// framework's own binding selection reads it with precisely this
/// containsKey-and-not-'false' check — copied verbatim here rather than
/// imported, because `flutter_test` is a `dev_dependency` (see
/// `pubspec.yaml`) and must never end up linked into the shipped app; this
/// file needs the same true/false answer without acquiring that dependency.
/// `test/api/app_mode_test.dart` asserts this resolves to `true` when the
/// test suite itself runs, which is the one environment this predicate
/// actually has to get right.
///
/// **Why a per-feature override still exists.** A single global switch
/// can't express "only the notifications endpoint is broken right now, keep
/// everything else live" — a real, recurring need while a backend endpoint
/// is mid-development or temporarily down. Each `*_mode.dart` file keeps its
/// own `--dart-define` (`LACASA_<FEATURE>_LIVE_API`), now read as a
/// tri-state string via [resolveUseLiveApi] instead of a bare
/// `bool.fromEnvironment`: `'true'` forces that one feature live, `'false'`
/// forces it to fixtures, and leaving the define unset (the common case)
/// defers to [useLiveApiByDefault] — the same three-way split every
/// feature had before, just inverted at the "unset" branch. A bare
/// `bool.fromEnvironment` can't represent this: it collapses "the define
/// was never passed" and "the define was explicitly set to false" into the
/// same `false`, which is exactly the distinction an override needs to make
/// (an unset override must fall through to the global default, not silently
/// resolve to fixtures). The exact call every `*_mode.dart` file should make
/// is:
///
/// ```dart
/// import '../../../api/app_mode.dart';
///
/// /// See app_mode.dart's doc comment for the fixtures/live default and the
/// /// FLUTTER_TEST guard. `final`, not `const` — resolving the default now
/// /// depends on a runtime check ([isRunningUnderFlutterTest] reads
/// /// [Platform.environment]), which a `const` initializer can't do.
/// final bool useLiveHomeFeedApi = resolveUseLiveApi(
///   const String.fromEnvironment('LACASA_HOME_LIVE_API', defaultValue: ''),
/// );
/// ```
///
/// (the per-feature `--dart-define` name is unchanged from before this
/// switch — only the default it falls back to, and the type used to read
/// it, changed.)
///
/// **How to run the app against fixtures deliberately.** Set the global
/// opt-in, which forces [useLiveApiByDefault] to `false` for every feature
/// that hasn't set its own override:
///
/// ```
/// flutter run --dart-define=LACASA_USE_FIXTURES=true
/// ```
///
/// (the root `package.json`'s `dev:mobile-flutter:fixtures` script wraps
/// exactly this). A specific feature can still be pulled back to live on
/// top of that global opt-in via its own `--dart-define=LACASA_<FEATURE>_LIVE_API=true`
/// — per-feature overrides win over the global default in both directions,
/// per [resolveUseLiveApi]'s tri-state resolution above.
library;

import 'dart:io' show Platform;

/// True exactly when this process is a `flutter test` run — see this
/// library's doc comment for the exact predicate and why it has to match
/// the Flutter framework's own test-binding check precisely. `final`, not
/// `const`, because [Platform.environment] is a runtime, not a
/// compile-time, value.
final bool isRunningUnderFlutterTest = _computeIsRunningUnderFlutterTest();

bool _computeIsRunningUnderFlutterTest() {
  final env = Platform.environment;
  return env.containsKey('FLUTTER_TEST') && env['FLUTTER_TEST'] != 'false';
}

/// The global fixtures opt-in — `--dart-define=LACASA_USE_FIXTURES=true`.
/// Unlike the old per-feature switches, this one's polarity was never
/// inverted: it has always meant "fixtures," it's just new (there was
/// previously no single flag that touched every feature at once, since
/// fixtures were already every feature's unconditional default).
const bool _fixturesOptIn = bool.fromEnvironment('LACASA_USE_FIXTURES');

/// The default every feature's live/fixtures switch falls back to when its
/// own per-feature `--dart-define` override isn't set — `true` (talk to the
/// real API) unless the global fixtures opt-in is set, or this process is
/// running under `flutter test`. See this library's doc comment for why
/// both of those force fixtures rather than just the first.
final bool useLiveApiByDefault = !(_fixturesOptIn || isRunningUnderFlutterTest);

/// Resolves one feature's live/fixtures switch from its own tri-state
/// per-feature override string, read at the call site via
/// `const String.fromEnvironment(defineName, defaultValue: '')` (has to be
/// read as a `String`, and has to be read at the call site as a
/// compile-time constant — `String.fromEnvironment`'s flag name argument
/// must itself be a literal, so this function cannot read the define on a
/// feature's behalf, only interpret what the feature already read).
///
/// - `'true'` → forces that feature live regardless of [useLiveApiByDefault].
/// - `'false'` → forces that feature to fixtures regardless of
///   [useLiveApiByDefault].
/// - anything else (in practice only `''`, the default when the define was
///   never passed) → defers to [useLiveApiByDefault].
bool resolveUseLiveApi(String rawOverride) {
  return switch (rawOverride) {
    'true' => true,
    'false' => false,
    _ => useLiveApiByDefault,
  };
}
