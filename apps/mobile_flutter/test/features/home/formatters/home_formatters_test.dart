import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/home/formatters/home_formatters.dart';

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
  group('HomeFormatters.groupedPrice', () {
    test('groups thousands with commas for a sale price', () {
      final ad = Ad.fromJson(_adJson(price: 78000, category: 'sale'));
      expect(HomeFormatters.groupedPrice(ad), '78,000');
    });

    test('groups a 7-figure price with two commas', () {
      final ad = Ad.fromJson(_adJson(price: 1200000, category: 'sale'));
      expect(HomeFormatters.groupedPrice(ad), '1,200,000');
    });

    test('leaves a sub-1000 price ungrouped', () {
      final ad = Ad.fromJson(_adJson(price: 900, category: 'rent'));
      expect(HomeFormatters.groupedPrice(ad), '900');
    });

    test('rounds a decimal price defensively', () {
      final ad = Ad.fromJson(_adJson(price: 1999.6, category: 'sale'));
      expect(HomeFormatters.groupedPrice(ad), '2,000');
    });
  });
}
