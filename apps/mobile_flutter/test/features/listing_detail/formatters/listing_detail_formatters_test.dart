// Unit tests for listing-detail's own display rules. The interesting half
// is `additionalInfo`, which parses an untyped wire field the server never
// re-validates — every shape a malformed `optionList` can take has to
// degrade rather than throw, because one bad array must not blank a screen
// whose other nine sections are fine.

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/listing_detail/formatters/listing_detail_formatters.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

import '../support/listing_detail_test_ads.dart';

void main() {
  // typeLabel/categoryLabel/repairmentLabel/furnitureLabel take an
  // AppLocalizations rather than a BuildContext (see the formatter file's
  // own doc comment on why) — `lookupAppLocalizations` resolves one
  // synchronously, without pumping a widget tree, exactly what a plain unit
  // test needs.
  final l10n = lookupAppLocalizations(const Locale('en'));

  group('info tag labels (SCREENS.md §3.7)', () {
    test('map each enum to the display label the spec fixes', () {
      expect(
        ListingDetailFormatters.typeLabel(l10n, AdType.residential),
        'Residential',
      );
      expect(
        ListingDetailFormatters.typeLabel(l10n, AdType.nonresidential),
        'Nonresidential',
      );
      expect(
        ListingDetailFormatters.categoryLabel(l10n, AdCategory.sale),
        'Sale',
      );
      expect(
        ListingDetailFormatters.categoryLabel(l10n, AdCategory.rent),
        'Rent',
      );
      expect(
        ListingDetailFormatters.repairmentLabel(l10n, Repairment.notRepaired),
        'Not repaired',
      );
      expect(
        ListingDetailFormatters.repairmentLabel(l10n, Repairment.excellent),
        'Excellent',
      );
      // The mixed capitalization is the spec's own, reproduced deliberately
      // so three implementations render identical strings.
      expect(
        ListingDetailFormatters.furnitureLabel(l10n, Furniture.withFurniture),
        'With furniture',
      );
      expect(
        ListingDetailFormatters.furnitureLabel(
          l10n,
          Furniture.withoutFurniture,
        ),
        'Without Furniture',
      );
    });

    test('answer null rather than inventing a label', () {
      // An unstated attribute and one this build doesn't recognize are the
      // same thing to a reader: no tag at all.
      expect(ListingDetailFormatters.repairmentLabel(l10n, null), isNull);
      expect(ListingDetailFormatters.furnitureLabel(l10n, null), isNull);
      expect(
        ListingDetailFormatters.repairmentLabel(l10n, Repairment.unknown),
        isNull,
      );
      expect(
        ListingDetailFormatters.furnitureLabel(l10n, Furniture.unknown),
        isNull,
      );
      expect(ListingDetailFormatters.typeLabel(l10n, AdType.unknown), isNull);
      expect(
        ListingDetailFormatters.categoryLabel(l10n, AdCategory.unknown),
        isNull,
      );
    });
  });

  group('additionalInfo', () {
    test('parses a well-formed key/value array', () {
      final entries = ListingDetailFormatters.additionalInfo(const [
        {'key': 'Parking', 'value': 'Yes'},
        {'key': 'Balcony', 'value': '2'},
      ]);

      expect(entries, hasLength(2));
      expect(entries.first.key, 'Parking');
      expect(entries.first.value, 'Yes');
      expect(entries.last.key, 'Balcony');
      expect(entries.last.value, '2');
    });

    test('stringifies non-string values instead of dropping them', () {
      // The write side never promised a string, and "Balcony: 2" is a
      // perfectly sensible option to carry as a number.
      final entries = ListingDetailFormatters.additionalInfo(const [
        {'key': 'Balcony', 'value': 2},
        {'key': 'Lift', 'value': true},
      ]);

      expect(entries.map((e) => e.value), ['2', 'true']);
    });

    test('degrades to empty for every malformed shape, never throwing', () {
      // Each of these is a shape the untyped wire field can actually
      // deliver; all of them mean "no additional information".
      for (final malformed in <Object?>[
        null,
        'malformed-not-a-list',
        42,
        {'key': 'not', 'value': 'a list'},
      ]) {
        expect(
          ListingDetailFormatters.additionalInfo(malformed),
          isEmpty,
          reason: 'optionList = $malformed',
        );
      }
    });

    test('drops individual bad entries but keeps the good ones', () {
      final entries = ListingDetailFormatters.additionalInfo(const [
        {'key': 'Parking', 'value': 'Yes'},
        'not a map',
        {'key': '', 'value': 'blank key'},
        {'key': 'Heating'}, // no value
        {'key': 'Balcony', 'value': '   '}, // blank value
        {'key': '  Lift  ', 'value': '  Yes  '}, // trimmed
      ]);

      expect(entries.map((e) => e.key), ['Parking', 'Lift']);
      expect(entries.last.value, 'Yes');
    });
  });

  group('coordinates', () {
    test('formats a real pin to 4 decimal places', () {
      expect(
        ListingDetailFormatters.coordinates(
          testAd(lat: 41.281, lng: 69.205),
        ),
        '41.2810, 69.2050',
      );
    });

    test('is null unless both halves are present', () {
      expect(ListingDetailFormatters.coordinates(testAd()), isNull);
      expect(
        ListingDetailFormatters.coordinates(testAd(lat: 41.281)),
        isNull,
      );
    });

    test('renders a pin at latitude 0 rather than treating it as absent', () {
      // `Ad.lat`'s doc comment calls this out: 0 is falsy-looking and valid.
      expect(
        ListingDetailFormatters.coordinates(testAd(lat: 0, lng: 69.205)),
        '0.0000, 69.2050',
      );
    });
  });

  group('pricePerSqm', () {
    test('groups thousands the same way a price does', () {
      // 120000 / 100 = 1200.
      expect(
        ListingDetailFormatters.pricePerSqm(
          l10n,
          testAd(price: 120000, area: 100),
        ),
        r'$1,200 / m²',
      );
    });

    // Regression test for the bug this fix closes: `pricePerSqm` computes
    // off `Ad.pricePerSqm` (a currency-agnostic `price / area`) but used to
    // hardcode the `$` prefix regardless of `Ad.priceType`, so a UZS ad's
    // secondary figure misstated its own currency even after
    // `Formatters.price` (the headline a few pixels above it, in
    // `listing_price_footer.dart`) had already been fixed to say "so'm" —
    // the two halves of one line disagreeing, confirmed on device on the
    // Chilonzor commercial UZS listing before this change
    // ("3,650,000,000 so'm · $ 6,083,333 / m²"). A prior pass's version of
    // this test only ever constructed USD ads (`testAd`'s `priceType`
    // defaulted to `'usd'` with no override available at all), so it stayed
    // green through that bug — asserting only the USD branch can never
    // catch a missing UZS branch.
    test('uses the UZS suffix instead of "\$" for a UZS ad', () {
      // 3650000000 / 600 = 6083333.33.. -> rounds to 6,083,333 (see
      // Ad.pricePerSqm / computePricePerSqm's own rounding rule).
      expect(
        ListingDetailFormatters.pricePerSqm(
          l10n,
          testAd(price: 3650000000, area: 600, priceType: 'uzs'),
        ),
        "6,083,333 so'm / m²",
      );
    });

    test('is null when the ad states no usable area', () {
      expect(ListingDetailFormatters.pricePerSqm(l10n, testAd()), isNull);
      expect(
        ListingDetailFormatters.pricePerSqm(l10n, testAd(area: 0)),
        isNull,
      );
    });
  });
}
