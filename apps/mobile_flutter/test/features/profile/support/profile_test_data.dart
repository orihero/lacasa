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
  Map<String, dynamic>? realtor,
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
    'realtor': realtor,
  });
}

/// The `realtor` block `POST /auth/register`'s realtor branch hangs off a
/// brand-new `role: "user"` account (`serializeUser.js`) — the shape
/// `profile-buyer` now branches its Account group on (audit §7.5). Built as
/// wire JSON and decoded by the real [RealtorProfile.fromJson] rather than
/// constructed directly, same rationale as [authUser] itself.
Map<String, dynamic> realtorApplication({
  required String status,
  String kind = 'solo',
  String? agencyName,
  String? officePhone,
  String? teamSize,
  String? appliedAt,
  String? decidedAt,
}) {
  return {
    'kind': kind,
    'status': status,
    'agencyName': agencyName,
    'officePhone': officePhone,
    'teamSize': teamSize,
    'appliedAt': appliedAt,
    'decidedAt': decidedAt,
  };
}
