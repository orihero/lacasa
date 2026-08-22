// AgentsResource's review methods (listReviews/postReview/deleteMyReview) —
// correct method/path/query/body shaping and correct decoding, against a
// FakeTransport (no live network).

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
  group('AgentsResource.listReviews', () {
    test('GETs /agents/:id/reviews with limit/cursor forwarded', () async {
      final transport = FakeTransport(
        (req) async => {
          'reviews': [
            {
              'id': 'review-1',
              'rating': 4,
              'comment': null,
              'createdAt': {'seconds': 1700000000},
              'author': {'id': 'user-1', 'fullName': 'A', 'avatar': null},
            },
          ],
          'nextCursor': null,
        },
      );
      final agents = AgentsResource(buildClient(transport));

      final page = await agents.listReviews(
        'agent-1',
        limit: 10,
        cursor: 'review-0',
      );

      expect(transport.requests.single.method, 'GET');
      expect(
        transport.requests.single.url,
        'https://api.example.com/agents/agent-1/reviews',
      );
      expect(transport.requests.single.query!['limit'], 10);
      expect(transport.requests.single.query!['cursor'], 'review-0');
      expect(page.reviews.single.rating, 4);
      expect(page.nextCursor, isNull);
    });
  });

  group('AgentsResource.postReview', () {
    test(
      'POSTs rating and comment, omitting a null comment entirely',
      () async {
        final transport = FakeTransport(
          (req) async => {
            'id': 'review-2',
            'rating': 5,
            'comment': null,
            'createdAt': {'seconds': 1700000000},
            'author': {'id': 'user-2', 'fullName': 'B', 'avatar': null},
          },
        );
        final agents = AgentsResource(buildClient(transport, token: 'tok'));

        final review = await agents.postReview('agent-1', rating: 5);

        expect(transport.requests.single.method, 'POST');
        expect(transport.requests.single.body, {'rating': 5});
        expect(review.rating, 5);
      },
    );

    test('POSTs a non-null comment alongside rating', () async {
      final transport = FakeTransport(
        (req) async => {
          'id': 'review-3',
          'rating': 3,
          'comment': 'Good, but slow to respond',
          'createdAt': {'seconds': 1700000000},
          'author': {'id': 'user-3', 'fullName': 'C', 'avatar': null},
        },
      );
      final agents = AgentsResource(buildClient(transport, token: 'tok'));

      await agents.postReview(
        'agent-1',
        rating: 3,
        comment: 'Good, but slow to respond',
      );

      expect(transport.requests.single.body, {
        'rating': 3,
        'comment': 'Good, but slow to respond',
      });
    });

    test(
      'rethrows a forbidden (self-review) ApiErrorException unchanged',
      () async {
        final transport = FakeTransport(
          (req) async => throw ApiErrorException(
            body: const ApiErrorBody(
              code: ApiErrorCode.forbidden,
              message: 'You may not review yourself',
            ),
            statusCode: 403,
          ),
        );
        final agents = AgentsResource(buildClient(transport, token: 'tok'));

        await expectLater(
          agents.postReview('agent-1', rating: 5),
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
  });

  group('AgentsResource.deleteMyReview', () {
    test('DELETEs /agents/:id/reviews/me', () async {
      final transport = FakeTransport((req) async => null);
      final agents = AgentsResource(buildClient(transport, token: 'tok'));

      await agents.deleteMyReview('agent-1');

      expect(transport.requests.single.method, 'DELETE');
      expect(
        transport.requests.single.url,
        'https://api.example.com/agents/agent-1/reviews/me',
      );
    });
  });
}
