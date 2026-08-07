// Resource-class tests (AuthResource, AdsResource, SavedAdsResource,
// AgentsResource): correct method/path/query/body shaping, correct
// decoding of the transport's raw JSON into typed models, and that a
// thrown ApiException passes through a resource call unchanged rather than
// being swallowed or rewrapped. All exercised against a FakeTransport — no
// live network, matching the task's instruction.

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';

import 'support/fake_transport.dart';
import 'support/fixtures.dart';

ApiClient buildClient(FakeTransport transport, {String? token}) {
  return ApiClient(
    transport: transport,
    tokenStorage: InMemoryTokenStorage(token),
    baseUrl: 'https://api.example.com',
  );
}

void main() {
  group('AuthResource', () {
    test(
      'register posts fullName/email/password and decodes AuthResponse',
      () async {
        final transport = FakeTransport(
          (req) async => {
            'token': 'jwt-token',
            'user': {
              'id': 'user-1',
              'fullName': 'Dilnoza Yusupova',
              'email': 'dilnoza@example.com',
              'role': 'user',
              'phoneNumber': null,
              'avatar': null,
              'agentId': null,
              'tgChatIds': <int>[],
              'igAccounts': <Map<String, dynamic>>[],
              'igAssistConsentAt': null,
              'realtor': null,
            },
          },
        );
        final auth = AuthResource(buildClient(transport));

        final result = await auth.register(
          fullName: 'Dilnoza Yusupova',
          email: 'dilnoza@example.com',
          password: 'secret1',
        );

        expect(transport.requests.single.method, 'POST');
        expect(
          transport.requests.single.url,
          'https://api.example.com/auth/register',
        );
        expect(transport.requests.single.body, {
          'fullName': 'Dilnoza Yusupova',
          'email': 'dilnoza@example.com',
          'password': 'secret1',
        });
        expect(result.token, 'jwt-token');
        expect(result.user.role, UserRole.user);
      },
    );

    test(
      'register with an agency realtor block nests kind/agencyName/teamSize in the body',
      () async {
        final transport = FakeTransport(
          (req) async => {
            'token': 't',
            'user': {
              'id': 'u1',
              'fullName': 'A',
              'email': 'a@example.com',
              'role': 'user',
              'phoneNumber': null,
              'avatar': null,
              'agentId': null,
              'tgChatIds': <int>[],
              'igAccounts': <Map<String, dynamic>>[],
              'igAssistConsentAt': null,
              'realtor': null,
            },
          },
        );
        final auth = AuthResource(buildClient(transport));

        await auth.register(
          fullName: 'A',
          email: 'a@example.com',
          password: 'secret1',
          realtor: const RealtorApplicationInput.agency(
            agencyName: 'La Casa Realty',
            teamSize: TeamSize.twoToFive,
          ),
        );

        expect(transport.requests.single.body, {
          'fullName': 'A',
          'email': 'a@example.com',
          'password': 'secret1',
          'realtor': {
            'kind': 'agency',
            'agencyName': 'La Casa Realty',
            'teamSize': 'two_to_five',
          },
        });
      },
    );

    test('login posts email/password and decodes AuthResponse', () async {
      final transport = FakeTransport(
        (req) async => {
          'token': 'jwt',
          'user': {
            'id': 'u1',
            'fullName': 'A',
            'email': 'a@example.com',
            'role': 'agent',
            'phoneNumber': null,
            'avatar': null,
            'agentId': null,
            'tgChatIds': <int>[],
            'igAccounts': <Map<String, dynamic>>[],
            'igAssistConsentAt': null,
            'realtor': null,
          },
        },
      );
      final auth = AuthResource(buildClient(transport));

      final result = await auth.login(
        email: 'a@example.com',
        password: 'secret1',
      );

      expect(transport.requests.single.method, 'POST');
      expect(
        transport.requests.single.url,
        'https://api.example.com/auth/login',
      );
      expect(result.user.role, UserRole.agent);
    });

    test(
      'login rethrows the ApiException the transport throws, unchanged',
      () async {
        final transport = FakeTransport(
          (req) async => throw ApiErrorException(
            body: const ApiErrorBody(
              code: ApiErrorCode.invalidCredentials,
              message: 'Invalid email or password',
            ),
            statusCode: 401,
          ),
        );
        final auth = AuthResource(buildClient(transport));

        await expectLater(
          auth.login(email: 'a@example.com', password: 'wrong'),
          throwsA(
            isA<ApiErrorException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.invalidCredentials,
            ),
          ),
        );
      },
    );

    test('me GETs /auth/me and decodes MeResponse', () async {
      final transport = FakeTransport(
        (req) async => {
          'user': {
            'id': 'u1',
            'fullName': 'A',
            'email': 'a@example.com',
            'role': 'coworker',
            'phoneNumber': null,
            'avatar': null,
            'agentId': 'agent-9',
            'tgChatIds': <int>[],
            'igAccounts': <Map<String, dynamic>>[],
            'igAssistConsentAt': null,
            'realtor': null,
          },
        },
      );
      final auth = AuthResource(buildClient(transport, token: 'tok'));

      final result = await auth.me();

      expect(transport.requests.single.method, 'GET');
      expect(transport.requests.single.url, 'https://api.example.com/auth/me');
      expect(result.user.agentId, 'agent-9');
    });
  });

  group('AdsResource', () {
    // Unset filter fields still show up as null-valued query entries here —
    // AdsResource hands the full filter map to the transport as-is;
    // stripping null entries out of the query string is DioTransport's job
    // (see transport_test.dart's "sends method, absolute url, headers,
    // query and body" test), so it only needs to exist in one place.
    test(
      'list GETs /ads with the filter map (incl. agentId) forwarded to the transport',
      () async {
        final transport = FakeTransport((req) async => [fullAdJson()]);
        final ads = AdsResource(buildClient(transport));

        final result = await ads.list(
          filters: const AdFilters(
            city: 'Tashkent',
            category: AdCategory.sale,
            priceMin: 50000,
          ),
          agentId: 'agent-1',
        );

        expect(transport.requests.single.method, 'GET');
        expect(transport.requests.single.url, 'https://api.example.com/ads');
        final query = transport.requests.single.query!;
        expect(query['city'], 'Tashkent');
        expect(query['category'], 'sale');
        expect(query['priceMin'], 50000);
        expect(query['agentId'], 'agent-1');
        expect(query['district'], isNull);
        expect(result, hasLength(1));
        expect(result.single, isA<Ad>());
      },
    );

    test(
      'list maps an unknown-enum filter to a null query value, never the literal "unknown"',
      () async {
        final transport = FakeTransport(
          (req) async => <Map<String, dynamic>>[],
        );
        final ads = AdsResource(buildClient(transport));

        await ads.list(filters: const AdFilters(category: AdCategory.unknown));

        expect(transport.requests.single.query!['category'], isNull);
      },
    );

    test('getById GETs /ads/:id and decodes a single Ad', () async {
      final transport = FakeTransport((req) async => fullAdJson());
      final ads = AdsResource(buildClient(transport));

      final ad = await ads.getById('ad-1');

      expect(transport.requests.single.url, 'https://api.example.com/ads/ad-1');
      expect(ad.id, 'ad-1');
    });

    test('getById rethrows a 404 ApiErrorException unchanged', () async {
      final transport = FakeTransport(
        (req) async => throw ApiErrorException(
          body: const ApiErrorBody(
            code: ApiErrorCode.notFound,
            message: 'Ad not found',
          ),
          statusCode: 404,
        ),
      );
      final ads = AdsResource(buildClient(transport));

      await expectLater(
        ads.getById('missing'),
        throwsA(
          isA<ApiErrorException>().having(
            (e) => e.statusCode,
            'statusCode',
            404,
          ),
        ),
      );
    });
  });

  group('SavedAdsResource', () {
    test('list GETs /saved-ads and decodes SavedAd rows', () async {
      final transport = FakeTransport(
        (req) async => [
          {...fullAdJson(), 'saved': true},
        ],
      );
      final savedAds = SavedAdsResource(buildClient(transport, token: 'tok'));

      final result = await savedAds.list();

      expect(
        transport.requests.single.url,
        'https://api.example.com/saved-ads',
      );
      expect(result.single.saved, true);
    });

    test('save POSTs /saved-ads/:adId', () async {
      final transport = FakeTransport((req) async => {'ok': true});
      final savedAds = SavedAdsResource(buildClient(transport, token: 'tok'));

      await savedAds.save('ad-1');

      expect(transport.requests.single.method, 'POST');
      expect(
        transport.requests.single.url,
        'https://api.example.com/saved-ads/ad-1',
      );
    });

    test(
      'save rethrows a forbidden ApiErrorException for a non-buyer role',
      () async {
        final transport = FakeTransport(
          (req) async => throw ApiErrorException(
            body: const ApiErrorBody(
              code: ApiErrorCode.forbidden,
              message: 'Not allowed for this role',
            ),
            statusCode: 403,
          ),
        );
        final savedAds = SavedAdsResource(buildClient(transport, token: 'tok'));

        await expectLater(
          savedAds.save('ad-1'),
          throwsA(
            isA<ApiErrorException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.forbidden,
            ),
          ),
        );
      },
    );

    test('unsave DELETEs /saved-ads/:adId', () async {
      final transport = FakeTransport((req) async => null);
      final savedAds = SavedAdsResource(buildClient(transport, token: 'tok'));

      await savedAds.unsave('ad-1');

      expect(transport.requests.single.method, 'DELETE');
      expect(
        transport.requests.single.url,
        'https://api.example.com/saved-ads/ad-1',
      );
    });
  });

  group('AgentsResource', () {
    test('list GETs /agents and decodes AgentSummary rows', () async {
      final transport = FakeTransport(
        (req) async => [
          {
            'id': 'agent-1',
            'fullName': 'A',
            'email': 'a@example.com',
            'phoneNumber': null,
            'avatar': null,
            'adsCount': 4,
          },
        ],
      );
      final agents = AgentsResource(buildClient(transport));

      final result = await agents.list();

      expect(transport.requests.single.url, 'https://api.example.com/agents');
      expect(result.single.adsCount, 4);
    });

    test('getById GETs /agents/:id and decodes AgentDetail', () async {
      final transport = FakeTransport(
        (req) async => {
          'id': 'agent-1',
          'fullName': 'A',
          'email': 'a@example.com',
          'phoneNumber': null,
          'avatar': null,
          'adsCount': 4,
          'dealsClosedCount': 1,
        },
      );
      final agents = AgentsResource(buildClient(transport));

      final agent = await agents.getById('agent-1');

      expect(
        transport.requests.single.url,
        'https://api.example.com/agents/agent-1',
      );
      expect(agent.dealsClosedCount, 1);
    });

    test('getById rethrows a 404 ApiErrorException unchanged', () async {
      final transport = FakeTransport(
        (req) async => throw ApiErrorException(
          body: const ApiErrorBody(
            code: ApiErrorCode.notFound,
            message: 'Agent not found',
          ),
          statusCode: 404,
        ),
      );
      final agents = AgentsResource(buildClient(transport));

      await expectLater(
        agents.getById('missing'),
        throwsA(isA<ApiErrorException>()),
      );
    });
  });

  group('UsersResource', () {
    test(
      'updateMe PATCHes /users/me with only the provided fields',
      () async {
        final transport = FakeTransport(
          (req) async => {
            'user': {
              'id': 'u1',
              'fullName': 'Updated Name',
              'email': 'a@example.com',
              'role': 'user',
              'phoneNumber': null,
              'avatar': null,
              'agentId': null,
              'tgChatIds': <int>[],
              'igAccounts': <Map<String, dynamic>>[],
              'igAssistConsentAt': null,
              'realtor': null,
            },
          },
        );
        final users = UsersResource(buildClient(transport, token: 'tok'));

        final result = await users.updateMe(fullName: 'Updated Name');

        expect(transport.requests.single.method, 'PATCH');
        expect(
          transport.requests.single.url,
          'https://api.example.com/users/me',
        );
        // email/phoneNumber/avatar/password were never passed — the null-aware
        // map entries (`'key': ?value`) must omit them entirely rather than
        // sending explicit `null`s the server would happily accept but that
        // don't reflect "leave this column untouched".
        expect(transport.requests.single.body, {'fullName': 'Updated Name'});
        expect(result.user.fullName, 'Updated Name');
      },
    );

    test(
      'updateMe rethrows a 409 email_taken ApiErrorException unchanged',
      () async {
        final transport = FakeTransport(
          (req) async => throw ApiErrorException(
            body: const ApiErrorBody(
              code: ApiErrorCode.emailTaken,
              message: 'Email is already registered',
            ),
            statusCode: 409,
          ),
        );
        final users = UsersResource(buildClient(transport, token: 'tok'));

        await expectLater(
          users.updateMe(email: 'taken@example.com'),
          throwsA(
            isA<ApiErrorException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.emailTaken,
            ),
          ),
        );
      },
    );
  });
}
