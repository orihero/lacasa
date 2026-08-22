// LiveAuthRepository: a thin adapter over LaCasaApi, whose one piece of
// behaviour beyond forwarding is the token lifecycle — login/register write
// the returned token, signOut clears it, currentUser/updateProfile don't
// touch it at all. Exercised against a FakeTransport (no real network) and
// InMemoryTokenStorage (no platform channel).

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/auth/data/live_auth_repository.dart';

import '../../../api/support/fake_transport.dart';

Map<String, dynamic> _userJson({String role = 'user'}) => {
  'id': 'u1',
  'fullName': 'A',
  'email': 'a@example.com',
  'role': role,
  'phoneNumber': null,
  'avatar': null,
  'agentId': null,
  'tgChatIds': <int>[],
  'igAccounts': <Map<String, dynamic>>[],
  'igAssistConsentAt': null,
  'realtor': null,
};

void main() {
  late InMemoryTokenStorage tokenStorage;
  late FakeTransport transport;
  late LiveAuthRepository repository;

  ApiClient buildClient() => ApiClient(
    transport: transport,
    tokenStorage: tokenStorage,
    baseUrl: 'https://api.example.com',
  );

  setUp(() {
    tokenStorage = InMemoryTokenStorage();
  });

  test('login writes the response token into TokenStorage', () async {
    transport = FakeTransport(
      (req) async => {'token': 'jwt-abc', 'user': _userJson()},
    );
    repository = LiveAuthRepository(LaCasaApi(buildClient()));

    final user = await repository.login(
      email: 'a@example.com',
      password: 'secret1',
    );

    expect(user.email, 'a@example.com');
    expect(await tokenStorage.getToken(), 'jwt-abc');
  });

  test('register writes the response token into TokenStorage', () async {
    transport = FakeTransport(
      (req) async => {'token': 'jwt-xyz', 'user': _userJson()},
    );
    repository = LiveAuthRepository(LaCasaApi(buildClient()));

    await repository.register(
      fullName: 'A',
      email: 'a@example.com',
      password: 'secret1',
    );

    expect(await tokenStorage.getToken(), 'jwt-xyz');
  });

  test('a failed login never writes a token', () async {
    transport = FakeTransport(
      (req) async => throw ApiErrorException(
        body: const ApiErrorBody(
          code: ApiErrorCode.invalidCredentials,
          message: 'Invalid email or password',
        ),
        statusCode: 401,
      ),
    );
    repository = LiveAuthRepository(LaCasaApi(buildClient()));

    await expectLater(
      repository.login(email: 'a@example.com', password: 'wrong'),
      throwsA(isA<ApiErrorException>()),
    );
    expect(await tokenStorage.getToken(), isNull);
  });

  test('currentUser GETs /auth/me and does not touch TokenStorage', () async {
    tokenStorage = InMemoryTokenStorage('existing-token');
    transport = FakeTransport(
      (req) async => {'user': _userJson(role: 'agent')},
    );
    repository = LiveAuthRepository(LaCasaApi(buildClient()));

    final user = await repository.currentUser();

    expect(user.role, UserRole.agent);
    expect(transport.requests.single.url, 'https://api.example.com/auth/me');
    // Unchanged — currentUser() only reads a session, it never mutates one.
    expect(await tokenStorage.getToken(), 'existing-token');
  });

  test(
    'updateProfile PATCHes /users/me and returns the updated user',
    () async {
      tokenStorage = InMemoryTokenStorage('existing-token');
      transport = FakeTransport(
        (req) async => {'user': _userJson()..['fullName'] = 'Updated'},
      );
      repository = LiveAuthRepository(LaCasaApi(buildClient()));

      final user = await repository.updateProfile(fullName: 'Updated');

      expect(user.fullName, 'Updated');
      expect(transport.requests.single.url, 'https://api.example.com/users/me');
      expect(transport.requests.single.method, 'PATCH');
    },
  );

  test('signOut clears the stored token without calling the API', () async {
    tokenStorage = InMemoryTokenStorage('existing-token');
    transport = FakeTransport((req) async {
      fail('signOut should not issue any HTTP request');
    });
    repository = LiveAuthRepository(LaCasaApi(buildClient()));

    await repository.signOut();

    expect(await tokenStorage.getToken(), isNull);
    expect(transport.requests, isEmpty);
  });
}
