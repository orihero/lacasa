import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/shared/shared.dart';

Map<String, dynamic> _adJson({required num price, required String category}) {
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
    'priceType': 'usd',
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
    test('a sale ad has no suffix', () {
      final ad = Ad.fromJson(_adJson(price: 78000, category: 'sale'));
      expect(Formatters.price(ad), r'$ 78,000');
    });

    test('a rent ad gets a /month suffix', () {
      final ad = Ad.fromJson(_adJson(price: 900, category: 'rent'));
      expect(Formatters.price(ad), r'$ 900/month');
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
}
