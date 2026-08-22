// UX audit §10.3 — "every rental price reads /month in Russian and Uzbek".
//
// `Formatters.price` localized the currency word two lines above and then
// glued a hardcoded English "/month" onto the result, so a Russian rental
// rendered `800,000 so'm/month` — three scripts in one price string, on the
// most-repeated line in the product. The regression this guards is subtle
// in a way a single-locale test cannot see: the English expectation passes
// whether or not the key is wired up at all, because the English value of
// `sharedPricePerMonthSuffix` *is* "/month". So every assertion here is a
// sweep over all three locales, and the ru/uz ones assert against the l10n
// object rather than a literal, plus an explicit "the three are actually
// different strings" check so a locale falling through to English fails.
//
// Lives beside `formatters_test.dart` rather than inside it because these
// need a widget binding (an `AppLocalizations` only exists under a
// `MaterialApp`'s delegates) while that file is a pure unit test.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/shared/shared.dart';

Map<String, dynamic> _adJson({
  required num price,
  required String category,
  String priceType = 'usd',
}) {
  return {
    'id': 'ad-x',
    'title': 't',
    'city': 'Tashkent',
    'district': 'd',
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': category,
    'rooms': 1,
    'area': 10,
    'storey': 1,
    'floors': 1,
    'hashtags': null,
    'price': price,
    'priceType': priceType,
    'stage': '1',
    'description': null,
    'nearPlacesList': <String>[],
    'optionList': null,
    'active': true,
    'lat': null,
    'lng': null,
    'tour3dLink': null,
    'agentId': 'a',
    'coworkerId': '',
    'photos': <String>[],
    'media': <Map<String, dynamic>>[],
    'createdAt': {'seconds': 0},
    'updatedAt': {'seconds': 0},
  };
}

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

  final usdRent = Ad.fromJson(_adJson(price: 900, category: 'rent'));
  final uzsRent = Ad.fromJson(
    _adJson(price: 800000, category: 'rent', priceType: 'uzs'),
  );
  final usdSale = Ad.fromJson(_adJson(price: 78000, category: 'sale'));

  group('Formatters.price with an AppLocalizations', () {
    for (final locale in const [Locale('en'), Locale('uz'), Locale('ru')]) {
      testWidgets('a USD rent ad takes ${locale.languageCode}\'s suffix', (
        tester,
      ) async {
        final l10n = await localizationsFor(tester, locale);
        expect(
          Formatters.price(usdRent, l10n: l10n),
          '\$900${l10n.sharedPricePerMonthSuffix}',
        );
      });

      testWidgets(
        'a UZS rent ad takes ${locale.languageCode}\'s currency AND suffix',
        (tester) async {
          final l10n = await localizationsFor(tester, locale);
          // Both halves through the same layer — the defect was one
          // localized word sitting against one English one.
          expect(
            Formatters.price(uzsRent, l10n: l10n),
            '800,000 ${l10n.listingEditorPriceTypeUzsOption}'
            '${l10n.sharedPricePerMonthSuffix}',
          );
        },
      );

      testWidgets('a sale ad takes no suffix in ${locale.languageCode}', (
        tester,
      ) async {
        final l10n = await localizationsFor(tester, locale);
        expect(Formatters.price(usdSale, l10n: l10n), r'$78,000');
      });
    }

    testWidgets('the three locales produce three different rental strings', (
      tester,
    ) async {
      // The assertions above are all self-referential by construction, so on
      // their own they would still pass if uz and ru fell through to the
      // English ARB value. This is the check that cannot.
      final rendered = <String>{};
      for (final locale in const [Locale('en'), Locale('uz'), Locale('ru')]) {
        final l10n = await localizationsFor(tester, locale);
        rendered.add(Formatters.price(usdRent, l10n: l10n));
      }
      expect(rendered, hasLength(3));
    });
  });

  group('Formatters.price without an AppLocalizations', () {
    test('still falls back to English on both halves', () {
      // The parameter stays optional because six call sites across two
      // features feed this method; the fallback must therefore keep
      // producing exactly the pre-fix string rather than an empty suffix.
      expect(Formatters.price(usdRent), r'$900/month');
      expect(Formatters.price(uzsRent), "800,000 so'm/month");
    });
  });
}
