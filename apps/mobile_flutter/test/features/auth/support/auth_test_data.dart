/// Minimal [AuthUser] builders for `lib/features/auth/` tests — every field
/// [AuthUser.fromJson] requires, with sensible defaults so a test only
/// names what it cares about.
library;

import 'package:lacasa_mobile/api/api.dart';

AuthUser authUser({
  String id = 'user-1',
  String fullName = 'Test User',
  String email = 'test@example.com',
  UserRole role = UserRole.user,
  String? agentId,
}) {
  return AuthUser.fromJson({
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': switch (role) {
      UserRole.user => 'user',
      UserRole.agent => 'agent',
      UserRole.coworker => 'coworker',
      UserRole.unknown => 'something-new',
    },
    'phoneNumber': null,
    'avatar': null,
    'agentId': agentId,
    'tgChatIds': <int>[],
    'igAccounts': <Map<String, dynamic>>[],
    'igAssistConsentAt': null,
    'realtor': null,
  });
}
