/// Ad builders for the map tests, wire-shaped and run through the real
/// `Ad.fromJson` so the nullable-coordinate handling under test is the
/// production one.
library;

import 'package:lacasa_mobile/api/api.dart';

Ad mapAd({
  required String id,
  String title = 'Test listing',
  double? lat,
  double? lng,
  int? rooms = 3,
  num price = 90000,
  String category = 'sale',
  List<String> photos = const [],
}) {
  return Ad.fromJson({
    'id': id,
    'title': title,
    'city': 'Tashkent',
    'district': 'Yunusabad',
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': category,
    'rooms': rooms,
    'area': 72,
    'storey': 4,
    'floors': 9,
    'hashtags': null,
    'price': price,
    'priceType': 'usd',
    'stage': '1',
    'description': null,
    'nearPlacesList': <String>[],
    'optionList': null,
    'active': true,
    'lat': lat,
    'lng': lng,
    'tour3dLink': null,
    'agentId': 'agent-a',
    'coworkerId': '',
    'photos': photos,
    'media': <Map<String, dynamic>>[],
    'createdAt': {'seconds': 1700000000},
    'updatedAt': {'seconds': 1700000000},
  });
}
