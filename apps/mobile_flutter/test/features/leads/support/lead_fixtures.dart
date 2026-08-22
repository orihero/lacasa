/// A small [Lead] builder for widget tests — no coupling to
/// `work_seed_data.dart`, same reasoning as `saved_listings_screen_test
/// .dart`'s own `savedAd()` helper.
library;

import 'package:lacasa_mobile/api/api.dart';

Lead makeLead({
  required String id,
  required String fullName,
  String? phone = '+998901234501',
  String? email,
  double? budget,
  String? comment,
  String? conversationComment,
  LeadStatus status = LeadStatus.newLead,
  String? source,
  DateTime? callbackDate,
  String coworkerId = '',
  int createdAtSeconds = 1700000000,
}) {
  return Lead.fromJson({
    'id': id,
    'fullName': fullName,
    'phone': phone,
    'email': email,
    'budget': budget,
    'comment': comment,
    'conversationComment': conversationComment,
    'status': status.wire,
    'source': source,
    'callbackDate': callbackDate?.toIso8601String(),
    'active': true,
    'agentId': 'agent-a',
    'coworkerId': coworkerId,
    'createdAt': {'seconds': createdAtSeconds},
    'updatedAt': {'seconds': createdAtSeconds},
  });
}
