import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
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
  group('Formatters.groupedPrice', () {
    test('groups thousands with commas for a sale price', () {
      final ad = Ad.fromJson(_adJson(price: 78000, category: 'sale'));
      expect(Formatters.groupedPrice(ad), '78,000');
    });

    test('groups a 7-figure price with two commas', () {
      final ad = Ad.fromJson(_adJson(price: 1200000, category: 'sale'));
      expect(Formatters.groupedPrice(ad), '1,200,000');
    });

    test('leaves a sub-1000 price ungrouped', () {
      final ad = Ad.fromJson(_adJson(price: 900, category: 'rent'));
      expect(Formatters.groupedPrice(ad), '900');
    });

    test('rounds a decimal price defensively', () {
      final ad = Ad.fromJson(_adJson(price: 1999.6, category: 'sale'));
      expect(Formatters.groupedPrice(ad), '2,000');
    });
  });

  group('Formatters.price', () {
    test('a USD sale ad has no suffix', () {
      final ad = Ad.fromJson(_adJson(price: 78000, category: 'sale'));
      expect(Formatters.price(ad), r'$78,000');
    });

    test('a USD rent ad gets a /month suffix', () {
      final ad = Ad.fromJson(_adJson(price: 900, category: 'rent'));
      expect(Formatters.price(ad), r'$900/month');
    });

    // Regression coverage for finding M1: a UZS ad must never render with
    // the `$` prefix — 800,000 so'm read as $800,000 overstates the price
    // roughly 13x. See Formatters.price's doc comment for why the fix is a
    // suffix ("so'm"), not a different prefix symbol.
    test('a UZS sale ad gets a so\'m suffix, never a \$ prefix', () {
      final ad = Ad.fromJson(
        _adJson(price: 800000, category: 'sale', priceType: 'uzs'),
      );
      expect(Formatters.price(ad), "800,000 so'm");
    });

    test('a UZS rent ad keeps the /month suffix after the so\'m suffix', () {
      final ad = Ad.fromJson(
        _adJson(price: 800000, category: 'rent', priceType: 'uzs'),
      );
      expect(Formatters.price(ad), "800,000 so'm/month");
    });

    test('an unrecognised priceType falls back to the \$ prefix', () {
      // Mirrors this method's pre-fix behaviour for every ad: a currency
      // the wire didn't say is not grounds to guess "so'm" over USD.
      final ad = Ad.fromJson(
        _adJson(price: 100, category: 'sale', priceType: 'not-a-currency'),
      );
      expect(Formatters.price(ad), r'$100');
    });
  });

  // The map pin's label: rounded to fit a 30dp capsule, and — unlike
  // Formatters.price — deliberately lossy, which is why the pin keeps the
  // exact string for its semantics label.
  group('Formatters.abbreviatedPrice', () {
    test('thousands abbreviate to k, with no /month suffix on a rent ad', () {
      final sale = Ad.fromJson(_adJson(price: 78000, category: 'sale'));
      final rent = Ad.fromJson(_adJson(price: 1200, category: 'rent'));
      expect(Formatters.abbreviatedPrice(sale), r'$78k');
      expect(Formatters.abbreviatedPrice(rent), r'$1.2k');
    });

    test('under a thousand stays whole; millions abbreviate to M', () {
      final small = Ad.fromJson(_adJson(price: 350, category: 'rent'));
      final big = Ad.fromJson(_adJson(price: 1250000, category: 'sale'));
      expect(Formatters.abbreviatedPrice(small), r'$350');
      expect(Formatters.abbreviatedPrice(big), r'$1.3M');
    });

    test('a UZS ad abbreviates with the so\'m suffix, never a \$ prefix', () {
      final ad = Ad.fromJson(
        _adJson(price: 800000, category: 'sale', priceType: 'uzs'),
      );
      expect(Formatters.abbreviatedPrice(ad), "800k so'm");
    });
  });

  group('Formatters.date', () {
    test('formats DD.MM.YYYY | HH:MM, zero-padded', () {
      final dt = DateTime(2026, 3, 7, 9, 5);
      expect(Formatters.date(dt), '07.03.2026 | 09:05');
    });

    test('does not confuse day and month for a double-digit day', () {
      final dt = DateTime(2026, 1, 25, 23, 59);
      expect(Formatters.date(dt), '25.01.2026 | 23:59');
    });
  });

  group('Formatters.isValidUzPhone', () {
    test('accepts a well-formed +998 number with 9 trailing digits', () {
      expect(Formatters.isValidUzPhone('+998901234567'), isTrue);
    });

    test('rejects a missing +998 prefix', () {
      expect(Formatters.isValidUzPhone('901234567'), isFalse);
    });

    test('rejects the wrong digit count', () {
      expect(Formatters.isValidUzPhone('+99890123456'), isFalse);
      expect(Formatters.isValidUzPhone('+9989012345678'), isFalse);
    });

    test('rejects a non-Uzbekistan country code', () {
      expect(Formatters.isValidUzPhone('+1234567890'), isFalse);
    });
  });

  group('Formatters.adIdBadge', () {
    test('takes the first 5 characters, prefixed with #', () {
      expect(Formatters.adIdBadge('a1b2c3d4-e5f6'), '#a1b2c');
    });

    test('falls back to the whole id when shorter than 5 characters', () {
      expect(Formatters.adIdBadge('ab'), '#ab');
    });
  });

  // The size/stat rules were private helpers duplicated in FullListingCard
  // and CompactListingCard until listing-detail needed the identical
  // strings. These tests are what keeps the three call sites agreeing.
  group('Formatters size rules', () {
    test('pluralizes rooms, and answers null for an unstated count', () {
      expect(Formatters.rooms(1), '1 room');
      expect(Formatters.rooms(3), '3 rooms');
      // Not "0 rooms" — the caller drops the segment entirely.
      expect(Formatters.rooms(null), isNull);
    });

    test('trims a whole-valued area rather than rendering "65.0 m²"', () {
      expect(Formatters.area(65), '65 m²');
      expect(Formatters.area(64.5), '64.5 m²');
      expect(Formatters.area(null), isNull);
    });

    test('needs both halves of a floor, never rendering "4/" or "/9"', () {
      expect(Formatters.floor(4, 9), '4/9');
      expect(Formatters.floor(4, null), isNull);
      expect(Formatters.floor(null, 9), isNull);
    });

    test('statLine drops absent parts along with their separators', () {
      Ad ad({int? rooms, num? area, int? storey, int? floors}) =>
          Ad.fromJson({
            ..._adJson(price: 1, category: 'sale'),
            'rooms': rooms,
            'area': area,
            'storey': storey,
            'floors': floors,
          });

      expect(
        Formatters.statLine(ad(rooms: 3, area: 65, storey: 4, floors: 9)),
        '3 rooms · 65 m² · 4/9',
      );
      // A sparse ad must not leave a dangling separator.
      expect(Formatters.statLine(ad(area: 65)), '65 m²');
      expect(Formatters.statLine(ad()), '');
    });

    test('statLine omits the floor for the compact card', () {
      final ad = Ad.fromJson({
        ..._adJson(price: 1, category: 'sale'),
        'rooms': 3,
        'area': 65,
        'storey': 4,
        'floors': 9,
      });

      expect(
        Formatters.statLine(ad, includeFloor: false),
        '3 rooms · 65 m²',
      );
    });
  });

  group('Formatters.groupedNumber', () {
    test('applies the price grouping rule to a bare number', () {
      // listing-detail's price-per-m² footer needs this grouping without
      // having an Ad to hand.
      expect(Formatters.groupedNumber(1200), '1,200');
      expect(Formatters.groupedNumber(999), '999');
      expect(Formatters.groupedNumber(1234567), '1,234,567');
    });
  });
}
