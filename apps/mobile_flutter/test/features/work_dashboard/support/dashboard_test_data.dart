/// Minimal `Ad`/`Lead` builders for `work_dashboard` widget tests — mirrors
/// `lib/shared/fixtures/work_seed_data.dart`'s own private `_ad`/`_lead`
/// JSON-map helpers, kept local to this test directory rather than reusing
/// the bundled fixtures (this suite must not depend on their exact values
/// staying unchanged).
library;

import 'package:lacasa_mobile/api/api.dart';

Ad testAd({
  required String id,
  String coworkerId = '',
  String stage = '1',
  String agentId = 'agent-1',
}) {
  return Ad.fromJson({
    'id': id,
    'title': 'Test listing $id',
    'city': 'Tashkent',
    'district': 'Chilonzor',
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': 'sale',
    'repairment': null,
    'rooms': 3,
    'area': 60,
    'storey': 2,
    'floors': 9,
    'furniture': null,
    'hashtags': null,
    'price': 100000,
    'priceType': 'usd',
    'stage': stage,
    'description': null,
    'nearPlacesList': const <String>[],
    'optionList': const <Map<String, dynamic>>[],
    'active': true,
    'lat': null,
    'lng': null,
    'tour3dLink': null,
    'agentId': agentId,
    'coworkerId': coworkerId,
    'photos': const <String>[],
    'media': const <Map<String, dynamic>>[],
    'createdAt': {'seconds': 1700000000},
    'updatedAt': {'seconds': 1700000000},
  });
}

ActivityEvent testActivityEvent({
  required String id,
  required String coworkerId,
  int stage = 1, // adCreated
}) {
  return ActivityEvent.fromJson({
    'id': id,
    'agentId': 'agent-1',
    'coworkerId': coworkerId,
    'adId': 'ad-x',
    'leadId': '',
    'stage': stage,
    'createdAt': {'seconds': 1700000000},
  });
}

Lead testLead({
  required String id,
  String coworkerId = '',
  String status = 'new',
  String? callbackIso,
}) {
  return Lead.fromJson({
    'id': id,
    'fullName': 'Test lead $id',
    'phone': '+998901234567',
    'email': null,
    'budget': 50000,
    'comment': 'Looking for a flat',
    'conversationComment': null,
    'status': status,
    'source': null,
    'callbackDate': callbackIso,
    'active': true,
    'agentId': 'agent-1',
    'coworkerId': coworkerId,
    'createdAt': {'seconds': 1700000000},
    'updatedAt': {'seconds': 1700000000},
  });
}
