// Covers the one decision `read_error.dart` exists to make: a read failure
// that never reached the server says so in one shared sentence, and every
// other failure keeps the caller's own per-screen copy. Both halves matter —
// a helper that returned the offline string for everything would be exactly
// as unhelpful as the fixed per-screen strings it replaces, just in the
// other direction (a 500 while online would read "check your network").
//
// The locale sweep is deliberate: this string's whole job is to be the SAME
// sentence on all ten-plus read surfaces, so it has to actually exist in
// uz/ru rather than fall through to English on two thirds of the userbase.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/shared/shared.dart';

void main() {
  Future<AppLocalizations> localizationsFor(
    WidgetTester tester,
    Locale locale,
  ) async {
    late AppLocalizations l10n;
    await tester.pumpWidget(
      MaterialApp(
        locale: locale,
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) {
            l10n = AppLocalizations.of(context);
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    return l10n;
  }

  const fallback = "Couldn't load your ads.";

  group('describeReadError', () {
    testWidgets('a NetworkException becomes the shared offline sentence', (
      tester,
    ) async {
      final l10n = await localizationsFor(tester, const Locale('en'));

      expect(
        describeReadError(
          l10n,
          const NetworkException('Could not connect to the server'),
          fallback: fallback,
        ),
        l10n.sharedOfflineErrorMessage,
      );
    });

    testWidgets('the offline sentence never leaks the transport message', (
      tester,
    ) async {
      // `transport.dart` classifies timeout / connection-error / cancel into
      // three different English strings. They are diagnostics, not copy, and
      // showing one to a user in a Russian build is exactly the half-
      // localized outcome this helper exists to prevent.
      final l10n = await localizationsFor(tester, const Locale('ru'));

      final message = describeReadError(
        l10n,
        const NetworkException('The request timed out'),
        fallback: fallback,
      );

      expect(message, l10n.sharedOfflineErrorMessage);
      expect(message.contains('timed out'), isFalse);
    });

    testWidgets('a decoded server error keeps the caller\'s per-screen copy', (
      tester,
    ) async {
      final l10n = await localizationsFor(tester, const Locale('en'));

      expect(
        describeReadError(
          l10n,
          ApiErrorException(
            statusCode: 500,
            body: const ApiErrorBody(
              code: ApiErrorCode.unknown,
              message: 'Internal server error',
            ),
          ),
          fallback: fallback,
        ),
        fallback,
      );
    });

    testWidgets('a non-API error keeps the caller\'s per-screen copy', (
      tester,
    ) async {
      final l10n = await localizationsFor(tester, const Locale('en'));

      expect(
        describeReadError(l10n, StateError('bad'), fallback: fallback),
        fallback,
      );
    });

    testWidgets('the offline sentence is translated in all three locales', (
      tester,
    ) async {
      final seen = <String>{};
      for (final locale in const [Locale('en'), Locale('uz'), Locale('ru')]) {
        final l10n = await localizationsFor(tester, locale);
        final message = describeReadError(
          l10n,
          const NetworkException('Could not connect to the server'),
          fallback: fallback,
        );
        expect(message.trim(), isNotEmpty);
        seen.add(message);
      }
      // Three distinct sentences: an untranslated key would collapse two of
      // them onto the English one.
      expect(seen, hasLength(3));
    });
  });

  group('readErrorIcon', () {
    test('offline swaps the glyph to wifi_off_rounded', () {
      expect(
        readErrorIcon(const NetworkException('Could not connect')),
        Icons.wifi_off_rounded,
      );
    });

    test('anything else keeps the call site\'s existing glyph', () {
      expect(readErrorIcon(StateError('bad')), Icons.error_outline_rounded);
      expect(
        readErrorIcon(StateError('bad'), fallback: Icons.search_off_rounded),
        Icons.search_off_rounded,
      );
    });
  });

  group('isOfflineReadError', () {
    test('is true only for NetworkException', () {
      expect(isOfflineReadError(const NetworkException('x')), isTrue);
      expect(isOfflineReadError(StateError('x')), isFalse);
      expect(
        isOfflineReadError(
          const MalformedResponseException('not json'),
        ),
        isFalse,
      );
    });
  });
}
