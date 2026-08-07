// TokenStorage contract tests, exercised through InMemoryTokenStorage — the
// interface both SecureTokenStorage (the real, platform-keystore-backed
// implementation) and every test fake in this suite implement. Mirrors
// apps/mobile/src/lib/httpTransport.test.ts's secureStoreTokenStorage
// coverage (null before any token is set, round-trip, delete-on-null); the
// platform channel SecureTokenStorage wraps is exercised by platform/
// integration tests, not here.

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';

void main() {
  group('InMemoryTokenStorage', () {
    test('returns null before any token has been set', () async {
      final storage = InMemoryTokenStorage();
      expect(await storage.getToken(), isNull);
    });

    test('round-trips a token through setToken/getToken', () async {
      final storage = InMemoryTokenStorage();
      await storage.setToken('secret-token');
      expect(await storage.getToken(), 'secret-token');
    });

    test('deletes the stored token when set to null', () async {
      final storage = InMemoryTokenStorage('secret-token');
      await storage.setToken(null);
      expect(await storage.getToken(), isNull);
    });
  });
}
