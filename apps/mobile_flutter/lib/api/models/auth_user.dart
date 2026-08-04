/// `serializeUser.js`'s `AuthUser` shape — identical object returned by
/// `POST /auth/register`, `POST /auth/login`, and `GET /auth/me`.
///
/// One asymmetry worth knowing: register's `user` is built with no
/// `resolveAgentContext` call, so `igAccounts`/`tgChatIds` are always empty
/// there; login/me populate them. This client doesn't special-case that —
/// it just decodes whatever the response actually contains.
library;

import 'enums.dart';

/// One connected Instagram account (`AuthUser.igAccounts[]`).
class IgAccount {
  final String igUserId;
  final String? username;
  final DateTime? expiresAt;

  const IgAccount({
    required this.igUserId,
    required this.username,
    required this.expiresAt,
  });

  factory IgAccount.fromJson(Map<String, dynamic> json) {
    return IgAccount(
      igUserId: json['igUserId'] as String? ?? '',
      username: json['username'] as String?,
      expiresAt: _parseIso(json['expiresAt']),
    );
  }
}

/// `null` for a plain buyer AND for a coworker (team facts live on their
/// agent's row, not copied down to the coworker).
class RealtorProfile {
  final RealtorKind kind;
  final RealtorStatus status;
  final String? agencyName;
  final String? officePhone;
  final TeamSize? teamSize;
  final DateTime? appliedAt;
  final DateTime? decidedAt;

  const RealtorProfile({
    required this.kind,
    required this.status,
    required this.agencyName,
    required this.officePhone,
    required this.teamSize,
    required this.appliedAt,
    required this.decidedAt,
  });

  factory RealtorProfile.fromJson(Map<String, dynamic> json) {
    return RealtorProfile(
      kind: RealtorKind.fromWire(json['kind'] as String?),
      status: RealtorStatus.fromWire(json['status'] as String?),
      agencyName: json['agencyName'] as String?,
      officePhone: json['officePhone'] as String?,
      teamSize: json['teamSize'] == null
          ? null
          : TeamSize.fromWire(json['teamSize'] as String?),
      appliedAt: _parseIso(json['appliedAt']),
      decidedAt: _parseIso(json['decidedAt']),
    );
  }
}

class AuthUser {
  final String id;
  final String fullName;
  final String email;
  final UserRole role;
  final String? phoneNumber;
  final String? avatar;

  /// Set only for role "coworker".
  final String? agentId;

  /// `BigInt[]` mapped to `Number` server-side.
  final List<int> tgChatIds;
  final List<IgAccount> igAccounts;
  final DateTime? igAssistConsentAt;
  final RealtorProfile? realtor;

  const AuthUser({
    required this.id,
    required this.fullName,
    required this.email,
    required this.role,
    required this.phoneNumber,
    required this.avatar,
    required this.agentId,
    required this.tgChatIds,
    required this.igAccounts,
    required this.igAssistConsentAt,
    required this.realtor,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      email: json['email'] as String? ?? '',
      role: UserRole.fromWire(json['role'] as String?),
      phoneNumber: json['phoneNumber'] as String?,
      avatar: json['avatar'] as String?,
      agentId: json['agentId'] as String?,
      tgChatIds:
          (json['tgChatIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [],
      igAccounts:
          (json['igAccounts'] as List<dynamic>?)
              ?.map((e) => IgAccount.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      igAssistConsentAt: _parseIso(json['igAssistConsentAt']),
      realtor: json['realtor'] == null
          ? null
          : RealtorProfile.fromJson(json['realtor'] as Map<String, dynamic>),
    );
  }
}

class AuthResponse {
  final String token;
  final AuthUser user;

  const AuthResponse({required this.token, required this.user});

  factory AuthResponse.fromJson(Map<String, dynamic> json) {
    return AuthResponse(
      token: json['token'] as String? ?? '',
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

class MeResponse {
  final AuthUser user;

  const MeResponse({required this.user});

  factory MeResponse.fromJson(Map<String, dynamic> json) {
    return MeResponse(
      user: AuthUser.fromJson(json['user'] as Map<String, dynamic>),
    );
  }
}

DateTime? _parseIso(dynamic value) {
  if (value is! String || value.isEmpty) return null;
  return DateTime.tryParse(value);
}
