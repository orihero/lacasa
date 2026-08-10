/// Ad builder for the `listing-search` tests. Every field is overridable and
/// every optional one defaults to *absent* — same convention as
/// `test/features/listing_detail/support/listing_detail_test_ads.dart` and
/// `test/features/saved_listings/saved_listings_screen_test.dart`'s local
/// `savedAd`. `createdAtSeconds` is exposed (unlike those two) because the
/// Newest sort in `search_providers.dart` orders on it directly.
library;

import 'package:lacasa_mobile/api/api.dart';

Ad searchAd({
  String id = 'ad-1001',
  String title = 'Bright 3-room apartment in Chilonzor',
  String city = 'Tashkent',
  String district = 'Chilonzor',
  String category = 'sale',
  num price = 78000,
  int? rooms,
  num? area,
  int? storey,
  int? floors,
  String agentId = 'agent-a',
  int createdAtSeconds = 1700000000,
}) {
  return Ad.fromJson({
    'id': id,
    'title': title,
    'city': city,
    'district': district,
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': category,
    'rooms': rooms,
    'area': area,
    'storey': storey,
    'floors': floors,
    'hashtags': null,
    'price': price,
    'priceType': 'usd',
    'stage': '1',
    'description': null,
    'nearPlacesList': const <String>[],
    'optionList': null,
    'active': true,
    'lat': null,
    'lng': null,
    'tour3dLink': null,
    'agentId': agentId,
    'coworkerId': '',
    'photos': const <String>[],
    'media': const <Map<String, dynamic>>[],
    'createdAt': {'seconds': createdAtSeconds},
    'updatedAt': {'seconds': createdAtSeconds},
  });
}
