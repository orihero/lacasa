// Verifies lib/api/app_mode.dart's central claim: that this process is
// reliably detectable as `flutter test`, and that the fixtures/live
// resolution built on top of that detection behaves as documented.

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
      // is the test that catches it instead of every widget test silently
      // starting to fire real HTTP.
      expect(Platform.environment['FLUTTER_TEST'], 'true');
      expect(isRunningUnderFlutterTest, isTrue);
    });
  });

  group('useLiveApiByDefault', () {
    test('is false while running under flutter test', () {
      // No LACASA_USE_FIXTURES define is passed to this test run, so the
      // only thing that could be forcing fixtures here is the FLUTTER_TEST
      // guard itself — which is exactly what this asserts.
      expect(useLiveApiByDefault, isFalse);
    });
  });

  group('resolveUseLiveApi', () {
    test('an unset override ("") defers to useLiveApiByDefault', () {
      expect(resolveUseLiveApi(''), useLiveApiByDefault);
    });

    test('"true" forces live regardless of useLiveApiByDefault', () {
      expect(resolveUseLiveApi('true'), isTrue);
    });

    test('"false" forces fixtures regardless of useLiveApiByDefault', () {
      expect(resolveUseLiveApi('false'), isFalse);
    });

    test('an unrecognized value is treated the same as unset', () {
      expect(resolveUseLiveApi('yes'), useLiveApiByDefault);
      expect(resolveUseLiveApi('1'), useLiveApiByDefault);
    });
  });
}
