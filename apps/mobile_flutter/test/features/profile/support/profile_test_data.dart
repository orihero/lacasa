/// A wire-shaped [AuthUser] builder for the profile tests, run through the
/// real `AuthUser.fromJson` rather than hand-built, same rationale as
/// `test/features/agents/support/agent_test_data.dart`.
library;

import 'package:lacasa_mobile/api/api.dart';

AuthUser authUser({
  required String id,
  required String fullName,
  required String email,
  required String role,
  String? phoneNumber,
  String? avatar,
  String? agentId,
}) {
  return AuthUser.fromJson({
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role,
    'phoneNumber': phoneNumber,
    'avatar': avatar,
    'agentId': agentId,
    'tgChatIds': <int>[],
    'igAccounts': <Map<String, dynamic>>[],
    'igAssistConsentAt': null,
    'realtor': null,
  });
}
