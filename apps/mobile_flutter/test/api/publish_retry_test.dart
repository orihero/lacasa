// PublishResource.retry — correct path shaping (lower-case :channel
// segment, distinct from Channel.wire's upper-case form), correct
// targetKey/idKey selection per channel, and that every documented retry
// error code round-trips through ApiErrorCode unchanged.

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

Map<String, dynamic> _publicationJson({String channel = 'TELEGRAM'}) => {
  'id': 'pub-1',
  'adId': 'ad-1',
  'channel': channel,
  'status': 'PUBLISHED',
  'externalId': 'ext-1',
  'externalUrl': null,
  'attempts': 2,
  'lastAttemptAt': '2026-08-01T00:00:00.000Z',
  'publishedAt': '2026-08-01T00:00:00.000Z',
  'errorMessage': null,
};

void main() {
  group('PublishResource.retry', () {
    test(
      'telegram: POSTs the lower-case path segment and decodes chatId/messageId results',
      () async {
        final transport = FakeTransport(
          (req) async => {
            'publication': _publicationJson(channel: 'TELEGRAM'),
            'results': [
              {
                'chatId': '123',
                'ok': true,
                'messageId': 'msg-1',
                'error': null,
              },
            ],
          },
        );
        final publish = PublishResource(buildClient(transport, token: 'tok'));

        final result = await publish.retry(
          adId: 'ad-1',
          channel: Channel.telegram,
        );

        expect(transport.requests.single.method, 'POST');
        expect(
          transport.requests.single.url,
          'https://api.example.com/publish/ads/ad-1/telegram/retry',
        );
        expect(result.results.single.target, '123');
        expect(result.results.single.mediaOrMessageId, 'msg-1');
      },
    );

    test(
      'instagram: POSTs the lower-case path segment and decodes igUserId/mediaId results',
      () async {
        final transport = FakeTransport(
          (req) async => {
            'publication': _publicationJson(channel: 'INSTAGRAM'),
            'results': [
              {
                'igUserId': 'ig-1',
                'ok': true,
                'mediaId': 'media-1',
                'error': null,
              },
            ],
          },
        );
        final publish = PublishResource(buildClient(transport, token: 'tok'));

        final result = await publish.retry(
          adId: 'ad-1',
          channel: Channel.instagram,
        );

        expect(
          transport.requests.single.url,
          'https://api.example.com/publish/ads/ad-1/instagram/retry',
        );
        expect(result.results.single.target, 'ig-1');
        expect(result.results.single.mediaOrMessageId, 'media-1');
      },
    );

    test('sends no request body', () async {
      final transport = FakeTransport(
        (req) async => {
          'publication': _publicationJson(),
          'results': <Map<String, dynamic>>[],
        },
      );
      final publish = PublishResource(buildClient(transport, token: 'tok'));

      await publish.retry(adId: 'ad-1', channel: Channel.telegram);

      expect(transport.requests.single.body, isNull);
    });

    for (final entry in {
      'not_retryable': ApiErrorCode.notRetryable,
      'not_failed': ApiErrorCode.notFailed,
      'already_published': ApiErrorCode.alreadyPublished,
      'awaiting_review': ApiErrorCode.awaitingReview,
      'retry_unavailable': ApiErrorCode.retryUnavailable,
      'retry_in_progress': ApiErrorCode.retryInProgress,
      'ad_not_found': ApiErrorCode.adNotFound,
      'unknown_channel': ApiErrorCode.unknownChannel,
      'forbidden': ApiErrorCode.forbidden,
    }.entries) {
      test(
        'rethrows a "${entry.key}" ApiErrorException as ApiErrorCode.${entry.value.name}, unchanged',
        () async {
          final transport = FakeTransport(
            (req) async => throw ApiErrorException(
              body: ApiErrorBody(code: entry.value, message: 'x'),
              statusCode: 400,
            ),
          );
          final publish = PublishResource(buildClient(transport, token: 'tok'));

          await expectLater(
            publish.retry(adId: 'ad-1', channel: Channel.telegram),
            throwsA(
              isA<ApiErrorException>().having(
                (e) => e.code,
                'code',
                entry.value,
              ),
            ),
          );
        },
      );
    }
  });
}
