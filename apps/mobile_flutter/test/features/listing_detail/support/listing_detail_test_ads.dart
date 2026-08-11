/// Ad/agent builders for the listing-detail tests. Every field is
/// overridable and every optional one defaults to *absent*, so a test that
/// cares about one attribute states only that attribute and the rest of the
/// screen is in its honest-gap state by default — which is also the harder
/// case to render correctly.
library;

import 'package:lacasa_mobile/api/api.dart';

Ad testAd({
  String id = 'ad-1001',
  String title = 'Bright 3-room apartment in Chilonzor',
  String city = 'Tashkent',
  String district = 'Chilonzor',
  String type = 'residential',
  String category = 'sale',
  num price = 78000,
  int? rooms,
  num? area,
  int? storey,
  int? floors,
  String? repairment,
  String? furniture,
  String? description,
  List<String> nearPlacesList = const [],
  Object? optionList,
  double? lat,
  double? lng,
  String agentId = 'agent-javlon',
  List<String> photos = const [],
  String? tour3dLink,
}) {
  return Ad.fromJson({
    'id': id,
    'title': title,
    'city': city,
    'district': district,
    'address': null,
    'reference': null,
    'type': type,
    'category': category,
    'rooms': rooms,
    'area': area,
    'storey': storey,
    'floors': floors,
    'hashtags': null,
    'price': price,
    'priceType': 'usd',
    'stage': '1',
    'description': description,
    'nearPlacesList': nearPlacesList,
    'optionList': optionList,
    'active': true,
    'lat': lat,
    'lng': lng,
    'tour3dLink': tour3dLink,
    'agentId': agentId,
    'coworkerId': '',
    'photos': photos,
    'media': const <Map<String, dynamic>>[],
    'createdAt': {'seconds': 1700000000},
    'updatedAt': {'seconds': 1700000000},
    // Absent-not-null is the wire's own shape for these two (see
    // `Ad.repairment`'s doc comment), so the keys are omitted rather than
    // sent as null when the caller states nothing.
    'repairment': ?repairment,
    'furniture': ?furniture,
  });
}

AgentDetail testAgent({
  String id = 'agent-javlon',
  String fullName = 'Javlon Rustamov',
  String? phoneNumber = '+998901112233',
  int adsCount = 24,
  int dealsClosedCount = 9,
}) {
  return AgentDetail.fromJson({
    'id': id,
    'fullName': fullName,
    'email': '$id@lacasa.uz',
    'phoneNumber': phoneNumber,
    'avatar': null,
    'adsCount': adsCount,
    'dealsClosedCount': dealsClosedCount,
  });
}
