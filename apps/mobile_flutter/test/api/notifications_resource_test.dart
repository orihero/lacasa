// NotificationsResource — correct method/path/query shaping and correct
// decoding, against a FakeTransport (no live network).

import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/api/api.dart';

import 'support/fake_transport.dart';

ApiClient buildClient(FakeTransport transport, {String? token}) {
  return ApiClient(
    transport: transport,
    tokenStorage: InMemoryTokenStorage(token),
    baseUrl: 'https://api.example.com',
  );
}

void main() {
  group('NotificationsResource', () {
    test(
      'fetch GETs /notifications with no query when since/limit are omitted',
      () async {
        final transport = FakeTransport(
          (req) async => <Map<String, dynamic>>[],
        );
        final notifications = NotificationsResource(
          buildClient(transport, token: 'tok'),
        );

        final result = await notifications.fetch();

        expect(transport.requests.single.method, 'GET');
        expect(
          transport.requests.single.url,
          'https://api.example.com/notifications',
        );
        expect(transport.requests.single.query!['since'], isNull);
        expect(transport.requests.single.query!['limit'], isNull);
        expect(result, isEmpty);
      },
    );

    test('fetch sends since as ISO-8601 and limit verbatim', () async {
      final transport = FakeTransport(
        (req) async => [
          {
            'id': 'sold:ad-1:event-1',
            'kind': 'sold',
            'title': 'Listing sold — Flat marked as Sold',
            'createdAt': {'seconds': 1700000000},
            'unread': false,
            'targetId': 'ad-1',
          },
        ],
      );
      final notifications = NotificationsResource(
        buildClient(transport, token: 'tok'),
      );
      final since = DateTime.utc(2026, 8, 1, 12, 0, 0);

      final result = await notifications.fetch(since: since, limit: 20);

      final query = transport.requests.single.query!;
      expect(query['since'], since.toIso8601String());
      expect(query['limit'], 20);
      expect(result, hasLength(1));
      expect(result.single.kind, NotificationKind.sold);
      expect(result.single.unread, isFalse);
    });

    test('fetch rethrows a validation ApiErrorException unchanged', () async {
      final transport = FakeTransport(
        (req) async => throw ApiErrorException(
          body: const ApiErrorBody(
            code: ApiErrorCode.validation,
            message: 'since must be a valid ISO 8601 timestamp',
          ),
          statusCode: 400,
        ),
      );
      final notifications = NotificationsResource(
        buildClient(transport, token: 'tok'),
      );

      await expectLater(
        notifications.fetch(),
        throwsA(
          isA<ApiErrorException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.validation,
          ),
        ),
      );
    });
  });
}
