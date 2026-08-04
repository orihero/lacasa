/// Token persistence, injected — mirrors
/// `apps/mobile/src/lib/httpTransport.ts`'s `secureStoreTokenStorage`
/// exactly (same key, same null-deletes semantics), swapping Expo's
/// `expo-secure-store` for `flutter_secure_storage`.
///
/// MUST be async: [ApiClient] awaits [TokenStorage.getToken] before
/// building every request's `Authorization` header, so a slow read (a cold
/// keystore/keychain read at app launch) can never race a request out the
/// door without its token attached.
library;

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const String _tokenKey = 'lacasa_token';

abstract class TokenStorage {
  Future<String?> getToken();

  /// Persists [token]; passing `null` deletes whatever was stored, rather
  /// than storing the literal string `"null"`.
  Future<void> setToken(String? token);
}

/// Backed by the platform keystore/keychain via `flutter_secure_storage`.
class SecureTokenStorage implements TokenStorage {
  final FlutterSecureStorage _storage;

  SecureTokenStorage({FlutterSecureStorage? storage})
    : _storage = storage ?? const FlutterSecureStorage();

  @override
  Future<String?> getToken() => _storage.read(key: _tokenKey);

  @override
  Future<void> setToken(String? token) async {
    if (token == null) {
      await _storage.delete(key: _tokenKey);
    } else {
      await _storage.write(key: _tokenKey, value: token);
    }
  }
}

/// An in-memory [TokenStorage] for tests and previews — never persists
/// across process restarts.
class InMemoryTokenStorage implements TokenStorage {
  String? _token;

  InMemoryTokenStorage([this._token]);

  @override
  Future<String?> getToken() async => _token;

  @override
  Future<void> setToken(String? token) async {
    _token = token;
  }
}
