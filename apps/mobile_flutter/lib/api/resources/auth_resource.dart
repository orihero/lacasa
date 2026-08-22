/// `/api/auth/*` — register, login, and the current-user lookup. No
/// refresh-token scheme exists: one JWT (`Authorization: Bearer <token>`),
/// no rotation/refresh endpoint, `exp` set server-side by `JWT_EXPIRES_IN`.
library;

import '../api_client.dart';
import '../models/auth_user.dart';
import '../models/enums.dart';

/// The realtor half of a registration payload
/// (`registerSchema`'s `realtor` field): either `{ kind: "solo" }` or a full
/// agency application. Buyers pass `null` for [AuthResource.register]'s
/// `realtor` argument instead of constructing one of these.
sealed class RealtorApplicationInput {
  const RealtorApplicationInput();

  const factory RealtorApplicationInput.solo() = _SoloRealtorApplication;

  const factory RealtorApplicationInput.agency({
    required String agencyName,
    String? officePhone,
    required TeamSize teamSize,
  }) = _AgencyRealtorApplication;

  Map<String, Object?> toJson();
}

class _SoloRealtorApplication extends RealtorApplicationInput {
  const _SoloRealtorApplication();

  @override
  Map<String, Object?> toJson() => {'kind': 'solo'};
}

class _AgencyRealtorApplication extends RealtorApplicationInput {
  final String agencyName;
  final String? officePhone;
  final TeamSize teamSize;

  const _AgencyRealtorApplication({
    required this.agencyName,
    this.officePhone,
    required this.teamSize,
  });

  @override
  Map<String, Object?> toJson() => {
    'kind': 'agency',
    'agencyName': agencyName,
    'officePhone': ?officePhone,
    'teamSize': teamSize.wire,
  };
}

class AuthResource {
  final ApiClient _client;

  const AuthResource(this._client);

  /// `POST /api/auth/register`. The account is always created with
  /// `role: "user"` — a [realtor] block only sets `realtorStatus:
  /// "pending"`, it never grants `role: "agent"` at signup. Throws
  /// [ApiErrorException] with `code: emailTaken` (409) if [email] is
  /// already registered, or `code: validation` (400) for a bad payload.
  Future<AuthResponse> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    RealtorApplicationInput? realtor,
  }) async {
    final json = await _client.request(
      method: 'POST',
      path: '/auth/register',
      body: {
        'fullName': fullName,
        'email': email,
        'password': password,
        'phoneNumber': ?phoneNumber,
        if (realtor != null) 'realtor': realtor.toJson(),
      },
    );
    return AuthResponse.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /api/auth/login`. Throws [ApiErrorException] with
  /// `code: invalidCredentials` (401) on a wrong email/password.
  Future<AuthResponse> login({
    required String email,
    required String password,
  }) async {
    final json = await _client.request(
      method: 'POST',
      path: '/auth/login',
      body: {'email': email, 'password': password},
    );
    return AuthResponse.fromJson(json as Map<String, dynamic>);
  }

  /// `GET /api/auth/me`. Requires a token already stored via this client's
  /// [TokenStorage]; throws [ApiErrorException] with `code: unauthorized`
  /// (401) if there isn't one, or it's expired/invalid.
  Future<MeResponse> me() async {
    final json = await _client.request(method: 'GET', path: '/auth/me');
    return MeResponse.fromJson(json as Map<String, dynamic>);
  }
}
