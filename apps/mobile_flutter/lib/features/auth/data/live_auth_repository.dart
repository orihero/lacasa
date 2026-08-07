/// The real, network-backed [AuthRepository] — a thin adapter over
/// [LaCasaApi] that adds no wire shapes of its own, the same rule
/// `live_agents_repository.dart` and `live_contact_repository.dart` follow.
///
/// **Token lifecycle lives here, not in `auth_session.dart`.** [login] and
/// [register] write the token their response carries through
/// `LaCasaApi.client.tokenStorage` immediately after a successful call, and
/// [signOut] clears it. `AuthSessionNotifier`
/// (`lib/navigation/auth_session.dart`) never touches [TokenStorage] itself
/// — it only reacts to the [AuthUser] this repository hands back — so there
/// is exactly one place in the app responsible for "what's in the
/// keystore."
///
/// **That token is visible to every other feature's `LaCasaApi` instance,
/// not just this one.** [TokenStorage] here is `_api.client.tokenStorage`,
/// but the thing that actually makes this work is [SecureTokenStorage]
/// (`lib/api/token_storage.dart`) itself: it holds no in-memory state of its
/// own, it is a thin wrapper over `flutter_secure_storage`'s platform
/// keystore/keychain, read and written under one fixed key
/// (`'lacasa_token'`). Two separate `SecureTokenStorage()` instances — this
/// repository's `LaCasaApi.create()` here, and whatever
/// `agents_repository_provider.dart` (or any other feature's live mode)
/// builds for itself — are two handles onto the exact same persisted value,
/// the same way two `File('x.txt')` objects both read/write the same file
/// on disk. A token written by [login] is therefore visible to the very
/// next request any other feature's live [LaCasaApi] makes, with no shared
/// Dart object required. `test/api/token_storage_test.dart` covers
/// [TokenStorage]'s read/write contract that this claim rests on.
library;

import '../../../api/api.dart';
import 'auth_repository.dart';

class LiveAuthRepository implements AuthRepository {
  const LiveAuthRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<AuthUser> login({
    required String email,
    required String password,
  }) async {
    final response = await _api.auth.login(email: email, password: password);
    await _api.client.tokenStorage.setToken(response.token);
    return response.user;
  }

  @override
  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    RealtorApplicationInput? realtor,
  }) async {
    final response = await _api.auth.register(
      fullName: fullName,
      email: email,
      password: password,
      phoneNumber: phoneNumber,
      realtor: realtor,
    );
    await _api.client.tokenStorage.setToken(response.token);
    return response.user;
  }

  @override
  Future<AuthUser> currentUser() async => (await _api.auth.me()).user;

  @override
  Future<AuthUser> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? avatar,
    String? password,
  }) async {
    final response = await _api.users.updateMe(
      fullName: fullName,
      phoneNumber: phoneNumber,
      email: email,
      avatar: avatar,
      password: password,
    );
    return response.user;
  }

  @override
  Future<void> signOut() => _api.client.tokenStorage.setToken(null);
}
