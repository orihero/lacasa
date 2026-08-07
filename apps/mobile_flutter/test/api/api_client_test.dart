// ApiClient tests: baseUrl+path joining, Authorization-header injection
// (present only when a token exists), and — mirroring
// packages/api-client/src/core/client.test.ts's "delayed-resolve
// TokenStorage" test — that ApiClient AWAITS tokenStorage.getToken() before
// ever invoking the transport, so a slow token read can never race a
// request out the door without its token attached.

import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';

import 'support/fake_transport.dart';

class DelayedTokenStorage implements TokenStorage {
  final Completer<String?> _completer = Completer<String?>();
  bool getTokenCalled = false;

  @override
  Future<String?> getToken() {
    getTokenCalled = true;
    return _completer.future;
  }

  @override
  Future<void> setToken(String? token) async {}

  void resolve(String? token) => _completer.complete(token);
}

void main() {
  test('prepends baseUrl to path and forwards query/body', () async {
    final transport = FakeTransport((req) async => {'ok': true});
    final client = ApiClient(
      transport: transport,
      tokenStorage: InMemoryTokenStorage(),
      baseUrl: 'https://api.example.com',
    );

    await client.request(
      method: 'GET',
      path: '/ads/1',
      query: const {'city': 'Tashkent'},
    );

    expect(transport.requests, hasLength(1));
    final sent = transport.requests.single;
    expect(sent.method, 'GET');
    expect(sent.url, 'https://api.example.com/ads/1');
    expect(sent.query, const {'city': 'Tashkent'});
  });

  test('adds an Authorization header when a token is stored', () async {
    final transport = FakeTransport((req) async => null);
    final client = ApiClient(
      transport: transport,
      tokenStorage: InMemoryTokenStorage('secret-token'),
      baseUrl: 'https://api.example.com',
    );

    await client.request(method: 'GET', path: '/auth/me');

    expect(transport.requests.single.headers, {
      'Authorization': 'Bearer secret-token',
    });
  });

  test('sends no Authorization header when no token is stored', () async {
    final transport = FakeTransport((req) async => null);
    final client = ApiClient(
      transport: transport,
      tokenStorage: InMemoryTokenStorage(),
      baseUrl: 'https://api.example.com',
    );

    await client.request(method: 'GET', path: '/ads');

    expect(transport.requests.single.headers, isEmpty);
  });

  test(
    'awaits tokenStorage.getToken() before invoking the transport',
    () async {
      final transport = FakeTransport((req) async => null);
      final tokenStorage = DelayedTokenStorage();
      final client = ApiClient(
        transport: transport,
        tokenStorage: tokenStorage,
        baseUrl: 'https://api.example.com',
      );

      final pending = client.request(method: 'GET', path: '/ads');

      // getToken() was called, but hasn't resolved yet — the transport must
      // not have been invoked out from under it.
      await Future<void>.delayed(Duration.zero);
      expect(tokenStorage.getTokenCalled, true);
      expect(transport.requests, isEmpty);

      tokenStorage.resolve('late-token');
      await pending;

      expect(transport.requests.single.headers, {
        'Authorization': 'Bearer late-token',
      });
    },
  );
}
