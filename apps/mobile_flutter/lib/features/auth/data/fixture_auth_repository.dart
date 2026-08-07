/// Offline stand-in for [AuthRepository] — no [LaCasaApi], no network. This
/// is what the app runs on by default (see `auth_mode.dart`), which is how
/// the build's "must render sensibly with NO network available" rule
/// extends to the auth slice.
///
/// **Seeded accounts, any password.** [login] accepts exactly these three
/// emails with *any* non-empty-check on the password — there is no
/// credential store to check against, so the password argument is read but
/// never compared:
///
/// | email               | role       | notes                              |
/// |---------------------|------------|-------------------------------------|
/// | `buyer@lacasa.uz`    | `user`     | plain buyer                        |
/// | `agent@lacasa.uz`    | `agent`    | solo, already-approved realtor     |
/// | `coworker@lacasa.uz` | `coworker` | reports to `agent@lacasa.uz`       |
///
/// **Unknown credentials throw the *same* [ApiErrorException] shape the
/// live endpoint would** (`invalidCredentials`, 401) — a fixture whose
/// failure mode differs from production is a fixture that hides the bug it
/// was meant to reveal, same rule `fixture_agents_repository.dart` follows
/// for its 404.
///
/// **This fixture still persists a real session, through the [TokenStorage]
/// it's constructed with.** That is a deliberate departure from most other
/// fixtures here (which are pure in-memory data with no storage side
/// effects at all): auth is the one feature where "does a session survive
/// an app relaunch" is itself part of what SCREENS.md's flows assume, and a
/// fixture that forgot the session on every cold start would never exercise
/// `lib/navigation/auth_session.dart`'s restore path in a build that has no
/// server to talk to. Since there is no real JWT to store, [_persistJson]
/// writes the signed-in account's own JSON, prefixed so it can never be
/// mistaken for (or crash on) a real JWT left over from a build that had
/// `LACASA_AUTH_LIVE_API` on — [_decode] rejects anything without that
/// prefix as `unauthorized`, the same "reject, don't crash" contract a real
/// expired/invalid token gets.
///
/// The alternative — an in-memory "currently signed in" field on this class
/// — was rejected: this repository is rebuilt fresh by
/// `auth_repository_provider.dart` on every app start (it is not a
/// singleton kept alive across relaunches), so an in-memory field would
/// silently make every fixture-mode session start signed out on relaunch,
/// which is the exact bug this task exists to prevent.
library;

import 'dart:convert';

import '../../../api/api.dart';
import 'auth_repository.dart';

/// Raw `AuthUser.fromJson`-shaped maps, hand-built rather than routed
/// through [AuthUser] and back — this file only ever needs to construct or
/// pattern-match on JSON, never to read a field off a decoded [AuthUser],
/// so there is nothing an intermediate typed object would buy here.
final List<Map<String, dynamic>> _seedAccounts = [
  {
    'id': 'fixture-user-buyer',
    'fullName': 'Dilnoza Yusupova',
    'email': 'buyer@lacasa.uz',
    'role': 'user',
    'phoneNumber': '+998901112233',
    'avatar': null,
    'agentId': null,
    'tgChatIds': <int>[],
    'igAccounts': <Map<String, dynamic>>[],
    'igAssistConsentAt': null,
    'realtor': null,
  },
  {
    'id': 'fixture-user-agent',
    'fullName': 'Javlon Rustamov',
    'email': 'agent@lacasa.uz',
    'role': 'agent',
    'phoneNumber': '+998901234567',
    'avatar': null,
    'agentId': null,
    'tgChatIds': <int>[],
    'igAccounts': <Map<String, dynamic>>[],
    'igAssistConsentAt': null,
    'realtor': {
      'kind': 'solo',
      'status': 'approved',
      'agencyName': null,
      'officePhone': null,
      'teamSize': null,
      'appliedAt': '2026-01-05T09:00:00.000Z',
      'decidedAt': '2026-01-06T09:00:00.000Z',
    },
  },
  {
    'id': 'fixture-user-coworker',
    'fullName': 'Sardor Abdullayev',
    'email': 'coworker@lacasa.uz',
    'role': 'coworker',
    'phoneNumber': '+998907654321',
    'avatar': null,
    'agentId': 'fixture-user-agent',
    'tgChatIds': <int>[],
    'igAccounts': <Map<String, dynamic>>[],
    'igAssistConsentAt': null,
    'realtor': null,
  },
];

const String _tokenPrefix = 'fixture-session:';

class FixtureAuthRepository implements AuthRepository {
  // Not `{required this._tokenStorage}`: that would make the constructor's
  // named parameter itself private (`_tokenStorage`), unusable by callers
  // outside this library — `auth_repository_provider.dart` needs to write
  // `FixtureAuthRepository(tokenStorage: ...)`.
  FixtureAuthRepository({required TokenStorage tokenStorage})
    // ignore: prefer_initializing_formals
    : _tokenStorage = tokenStorage;

  final TokenStorage _tokenStorage;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final normalized = email.trim().toLowerCase();
    Map<String, dynamic>? account;
    for (final candidate in _seedAccounts) {
      if ((candidate['email'] as String).toLowerCase() == normalized) {
        account = candidate;
        break;
      }
    }
    if (account == null) {
      throw ApiErrorException(
        statusCode: 401,
        body: const ApiErrorBody(
          code: ApiErrorCode.invalidCredentials,
          message: 'Invalid email or password',
        ),
      );
    }
    await _persistJson(account);
    return AuthUser.fromJson(account);
  }

  @override
  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    RealtorApplicationInput? realtor,
  }) async {
    // Mirrors POST /auth/register exactly (apps/api/src/routes/auth.js):
    // role is always "user" at signup, even with a realtor block — that
    // block only records a PENDING application. Promoting to "agent" is a
    // manual, back-office approval this fixture has no way to simulate, so
    // a fixture-mode realtor signup stays "pending" forever, same as it
    // would against a real API with nobody watching the queue.
    final realtorJson = realtor?.toJson();
    final json = <String, dynamic>{
      'id': 'fixture-register-${DateTime.now().microsecondsSinceEpoch}',
      'fullName': fullName,
      'email': email,
      'role': 'user',
      'phoneNumber': phoneNumber,
      'avatar': null,
      'agentId': null,
      'tgChatIds': <int>[],
      'igAccounts': <Map<String, dynamic>>[],
      'igAssistConsentAt': null,
      'realtor': realtorJson == null
          ? null
          : {
              'kind': realtorJson['kind'],
              'status': 'pending',
              'agencyName': realtorJson['agencyName'],
              'officePhone': realtorJson['officePhone'],
              'teamSize': realtorJson['teamSize'],
              'appliedAt': DateTime.now().toIso8601String(),
              'decidedAt': null,
            },
    };
    await _persistJson(json);
    return AuthUser.fromJson(json);
  }

  @override
  Future<AuthUser> currentUser() async =>
      AuthUser.fromJson(await _requireStoredAccount());

  @override
  Future<AuthUser> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? avatar,
    String? password,
  }) async {
    final json = Map<String, dynamic>.from(await _requireStoredAccount());
    if (fullName != null) json['fullName'] = fullName;
    if (phoneNumber != null) json['phoneNumber'] = phoneNumber;
    if (email != null) json['email'] = email;
    if (avatar != null) json['avatar'] = avatar;
    // password is accepted and silently discarded — there is no credential
    // store here to update, matching login()'s "any password" contract.
    await _persistJson(json);
    return AuthUser.fromJson(json);
  }

  @override
  Future<void> signOut() => _tokenStorage.setToken(null);

  Future<Map<String, dynamic>> _requireStoredAccount() async {
    final token = await _tokenStorage.getToken();
    if (token == null) {
      throw ApiErrorException(
        statusCode: 401,
        body: const ApiErrorBody(
          code: ApiErrorCode.unauthorized,
          message: 'Missing token',
        ),
      );
    }
    final decoded = _decode(token);
    if (decoded == null) {
      throw ApiErrorException(
        statusCode: 401,
        body: const ApiErrorBody(
          code: ApiErrorCode.unauthorized,
          message: 'Invalid or expired token',
        ),
      );
    }
    return decoded;
  }

  Future<void> _persistJson(Map<String, dynamic> json) =>
      _tokenStorage.setToken('$_tokenPrefix${jsonEncode(json)}');

  Map<String, dynamic>? _decode(String token) {
    if (!token.startsWith(_tokenPrefix)) return null;
    try {
      final decoded = jsonDecode(token.substring(_tokenPrefix.length));
      return decoded is Map<String, dynamic> ? decoded : null;
    } on FormatException {
      return null;
    }
  }
}
