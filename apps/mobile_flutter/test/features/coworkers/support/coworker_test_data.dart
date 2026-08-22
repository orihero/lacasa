/// Test-data builders for `test/features/coworkers/`. No coupling to
/// `work_seed_data.dart` — a test hands the fake repository exactly the
/// rows it wants to assert against, matching
/// `test/features/agents/support/agent_test_data.dart`'s own reasoning.
library;

import 'package:lacasa_mobile/api/api.dart';

Coworker coworker({
  required String id,
  String fullName = 'Sardor Abdullayev',
  String email = 'sardor@lacasa.uz',
  String? phoneNumber = '+998901112233',
  String? avatar,
  String agentId = 'agent-a',
}) {
  return Coworker(
    id: id,
    fullName: fullName,
    email: email,
    phoneNumber: phoneNumber,
    avatar: avatar,
    agentId: agentId,
  );
}

/// A minimal [Ad], just enough shape for [Ad.coworkerId]-based derivation —
/// mirrors `test/features/saved_listings/saved_listings_screen_test.dart`'s
/// own `savedAd` helper.
Ad coworkerAd({
  required String id,
  required String coworkerId,
  String agentId = 'agent-a',
  String title = 'Retail space near Chorsu bazaar',
}) {
  return Ad.fromJson({
    'id': id,
    'title': title,
    'city': 'Tashkent',
    'district': 'Chilonzor',
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': 'sale',
    'rooms': 2,
    'area': 48,
    'storey': 1,
    'floors': 1,
    'hashtags': null,
    'price': 1000,
    'priceType': 'usd',
    'stage': '1',
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
    'createdAt': {'seconds': 1700000000},
    'updatedAt': {'seconds': 1700000000},
  });
}

ActivityEvent activityEvent({
  required String id,
  required String coworkerId,
  required int createdAtSeconds,
  String agentId = 'agent-a',
}) {
  return ActivityEvent.fromJson({
    'id': id,
    'agentId': agentId,
    'coworkerId': coworkerId,
    'adId': '',
    'leadId': '',
    'stage': 1,
    'createdAt': {'seconds': createdAtSeconds},
  });
}

AuthUser authUser({
  required String id,
  String fullName = 'Javlon Rustamov',
  String email = 'javlon@lacasa.uz',
  required UserRole role,
  RealtorKind? realtorKind,
}) {
  return AuthUser.fromJson({
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': switch (role) {
      UserRole.agent => 'agent',
      UserRole.coworker => 'coworker',
      UserRole.user => 'user',
      UserRole.unknown => 'unknown',
    },
    'phoneNumber': null,
    'avatar': null,
    'agentId': role == UserRole.coworker ? 'agent-a' : null,
    'tgChatIds': <int>[],
    'igAccounts': <Map<String, dynamic>>[],
    'igAssistConsentAt': null,
    'realtor': realtorKind == null
        ? null
        : {
            'kind': switch (realtorKind) {
              RealtorKind.solo => 'solo',
              RealtorKind.agency => 'agency',
              RealtorKind.unknown => 'unknown',
            },
            'status': 'approved',
            'agencyName': null,
            'officePhone': null,
            'teamSize': null,
            'appliedAt': null,
            'decidedAt': null,
          },
  });
}
