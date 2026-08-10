/// A wire-shaped [AuthUser] builder for the `work_misc` tests — same
/// rationale as `test/features/profile/support/profile_test_data.dart`,
/// extended with a [tgChatIds] parameter since `TelegramSection` reads it
/// directly and none of the existing builders expose it.
library;

import 'package:lacasa_mobile/api/api.dart';

AuthUser authUser({
  required String id,
  required String fullName,
  required String email,
  required String role,
  List<int> tgChatIds = const [],
}) {
  return AuthUser.fromJson({
    'id': id,
    'fullName': fullName,
    'email': email,
    'role': role,
    'phoneNumber': null,
    'avatar': null,
    'agentId': null,
    'tgChatIds': tgChatIds,
    'igAccounts': <Map<String, dynamic>>[],
    'igAssistConsentAt': null,
    'realtor': null,
  });
}
