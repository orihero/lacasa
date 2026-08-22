/// Whether this process is a `flutter test` run.
///
/// **What used to live here.** This library was the single source of truth
/// for a fixtures/live switch: every feature carried a
/// `data/<feature>_mode.dart` that resolved a `--dart-define` through
/// `resolveUseLiveApi`, and every `state/<feature>_repository_provider.dart`
/// branched between a `Fixture<Feature>Repository` (hand-written seed rows
/// bundled into the shipped app) and the real `Live<Feature>Repository`.
/// That whole mechanism is gone: the bundled fixture repositories and their
/// seed data have been deleted, so there is no second data source left to
/// switch between and every provider now constructs its live repository
/// unconditionally. The `LACASA_USE_FIXTURES` and per-feature
/// `LACASA_<FEATURE>_LIVE_API` defines no longer exist — passing them has no
/// effect. Where the app points is still configurable, via
/// `lib/api/env.dart`'s `LACASA_API_BASE_URL`; *whether* it talks to a real
/// backend is no longer a question the app asks.
///
/// **Why the predicate survived the removal.** It was never only about
/// fixtures. `lib/shared/map/map_tile_layer_provider.dart` reads it for an
/// unrelated reason — to serve blank map tiles under test instead of
/// fetching real OpenStreetMap tiles over the network — and that need is
/// untouched by the data-source change. See that file's doc comment.
///
/// [isRunningUnderFlutterTest] mirrors the exact predicate the Flutter
/// framework itself uses to decide `AutomatedTestWidgetsFlutterBinding` vs.
/// `LiveTestWidgetsFlutterBinding` —
/// `packages/flutter_test/lib/src/_binding_io.dart#ensureInitialized`:
/// `environment.containsKey('FLUTTER_TEST') && environment['FLUTTER_TEST']
/// != 'false'`. Verified against the Flutter SDK installed for this project,
/// not assumed: `flutter_tools` sets `FLUTTER_TEST=true` in the child
/// process environment for every `flutter test` invocation
/// (`packages/flutter_tools/lib/src/test/*.dart`), and the framework's own
/// binding selection reads it with precisely this
/// containsKey-and-not-`'false'` check — copied verbatim here rather than
/// imported, because `flutter_test` is a `dev_dependency` (see
/// `pubspec.yaml`) and must never end up linked into the shipped app; this
/// file needs the same true/false answer without acquiring that dependency.
/// `test/api/app_mode_test.dart` asserts this resolves to `true` when the
/// test suite itself runs, which is the one environment this predicate
/// actually has to get right.
///
/// **A test that pumps a screen must now override that screen's repository
/// provider.** Previously a widget test could pump a feature with no
/// override and silently get fixtures, because this library forced fixtures
/// under `flutter test`. With the fixture repositories deleted there is no
/// such fallback: an un-overridden provider builds a real repository around
/// `LaCasaApi.create()` and the screen fires real HTTP out of the test
/// process. Every widget test therefore injects an explicit fake from that
/// feature's `test/features/<feature>/support/` directory — which is where
/// test-only seed data belongs, and where most of it already lived.
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
