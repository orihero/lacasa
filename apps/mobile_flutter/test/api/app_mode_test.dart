// Verifies lib/api/app_mode.dart's remaining claim: that this process is
// reliably detectable as `flutter test`.
//
// This file used to also cover `useLiveApiByDefault` and
// `resolveUseLiveApi` — the fixtures/live resolution that every feature's
// `data/<feature>_mode.dart` switch read. Those are gone: the bundled
// fixture repositories were deleted, so there is no second data source to
// resolve between and nothing left to test there. What remains is the
// predicate itself, which `shared/map/map_tile_layer_provider.dart` still
// depends on for a reason unrelated to fixtures (serving blank map tiles
// under test instead of fetching real OpenStreetMap ones).

import 'dart:io' show Platform;

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/app_mode.dart';

void main() {
  group('isRunningUnderFlutterTest', () {
    test('is true for this very test process', () {
      // The one fact this whole file exists to nail down: FLUTTER_TEST is
      // actually set (and not 'false') when `flutter test` runs this suite.
      // Asserted against the real Platform.environment, not a fake — if
      // flutter_tools ever stops setting this, or changes its value, this
      // is the test that catches it instead of the map layer silently
      // starting to fetch real tiles over the network.
      expect(Platform.environment['FLUTTER_TEST'], 'true');
      expect(isRunningUnderFlutterTest, isTrue);
    });
  });
}
