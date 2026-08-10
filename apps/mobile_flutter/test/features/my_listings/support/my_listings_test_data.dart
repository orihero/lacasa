/// Test-data builders for `test/features/my_listings/`. No coupling to
/// `work_seed_data.dart` — a test hands the fake repository exactly the
/// rows it wants to assert against, matching
/// `test/features/coworkers/support/coworker_test_data.dart`'s own
/// reasoning.
library;

import 'package:lacasa_mobile/api/api.dart';

Ad myListingAd({
  required String id,
  String title = 'Bright 3-room apartment in Chilonzor',
  String city = 'Tashkent',
  String district = 'Chilonzor',
  int? rooms = 3,
  num? area = 65,
  String stage = '1', // '1' active | '2' sold | '3' draft
  num price = 78000,
  String agentId = 'agent-a',
  String coworkerId = '',
  int createdAtSeconds = 1700000800,
}) {
  return Ad.fromJson({
    'id': id,
    'title': title,
    'city': city,
    'district': district,
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': 'sale',
    'rooms': rooms,
    'area': area,
    'storey': 4,
    'floors': 9,
    'hashtags': null,
    'price': price,
    'priceType': 'usd',
    'stage': stage,
    'description': null,
    'nearPlacesList': <String>[],
    'optionList': null,
    'active': true,
    'lat': null,
    'lng': null,
    'tour3dLink': null,
    'agentId': agentId,
    'coworkerId': coworkerId,
    'photos': <String>[],
    'media': <Map<String, dynamic>>[],
    'createdAt': {'seconds': createdAtSeconds},
    'updatedAt': {'seconds': createdAtSeconds},
  });
}

Coworker myListingsCoworker({
  required String id,
  required String fullName,
  String email = 'coworker@lacasa.uz',
  String agentId = 'agent-a',
}) {
  return Coworker(
    id: id,
    fullName: fullName,
    email: email,
    phoneNumber: null,
    avatar: null,
    agentId: agentId,
  );
}

/// Same wire-shaped builder `test/features/work_misc/support/
/// work_misc_test_data.dart` uses — duplicated locally rather than
/// imported cross-feature, matching this codebase's own per-feature test
/// fixture convention.
AuthUser myListingsAuthUser({
  required String id,
  required String fullName,
  String email = 'agent@lacasa.uz',
  String role = 'agent',
}) {
  return AuthUser.fromJson({
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role,
    'phoneNumber': null,
    'avatar': null,
    'agentId': null,
    'tgChatIds': <int>[],
    'igAccounts': <Map<String, dynamic>>[],
    'igAssistConsentAt': null,
    'realtor': null,
  });
}
