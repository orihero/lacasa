// FixtureAgentsRepository's review methods — the part of this task's fixture
// story that isn't a thin passthrough: upsert-by-author, self-review
// rejection, rating recomputation, and cursor paging all have real logic to
// get wrong. Deliberately does not assert on the specific seed reviews
// `agents_fixtures.dart` ships (that data can change); it asserts on the
// *behavior* those seeds exercise.

import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/agents/data/fixture_agents_repository.dart';

void main() {
  const buyer = ReviewAuthor(id: 'buyer-1', fullName: 'A Buyer', avatar: null);
  const otherBuyer = ReviewAuthor(
    id: 'buyer-2',
    fullName: 'Another Buyer',
    avatar: null,
  );

  group('postAgentReview', () {
    test(
      'a second post from the same author edits the first rather than stacking',
      () async {
        final repo = FixtureAgentsRepository();

        await repo.postAgentReview(
          'agent-otabek',
          rating: 3,
          comment: 'Fine.',
          actingAs: buyer,
        );
        await repo.postAgentReview(
          'agent-otabek',
          rating: 5,
          comment: 'Actually great.',
          actingAs: buyer,
        );

        final page = await repo.fetchAgentReviews('agent-otabek');
        expect(page.reviews.length, 1);
        expect(page.reviews.single.rating, 5);
        expect(page.reviews.single.comment, 'Actually great.');
      },
    );

    test('two different authors both land as separate reviews', () async {
      final repo = FixtureAgentsRepository();

      await repo.postAgentReview('agent-otabek', rating: 4, actingAs: buyer);
      await repo.postAgentReview(
        'agent-otabek',
        rating: 2,
        actingAs: otherBuyer,
      );

      final page = await repo.fetchAgentReviews('agent-otabek');
      expect(page.reviews.length, 2);
    });

    test('rejects self-review with 403 forbidden', () async {
      final repo = FixtureAgentsRepository();

      await expectLater(
        repo.postAgentReview(
          'agent-otabek',
          rating: 5,
          actingAs: const ReviewAuthor(
            id: 'agent-otabek',
            fullName: 'Otabek',
            avatar: null,
          ),
        ),
        throwsA(
          isA<ApiErrorException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.forbidden,
          ),
        ),
      );
    });

    test(
      'rejects an id that is not a real fixture agent with 404 not_found',
      () async {
        final repo = FixtureAgentsRepository();

        await expectLater(
          repo.postAgentReview(
            'agent-does-not-exist',
            rating: 5,
            actingAs: buyer,
          ),
          throwsA(
            isA<ApiErrorException>().having(
              (e) => e.code,
              'code',
              ApiErrorCode.notFound,
            ),
          ),
        );
      },
    );

    test('rejects an out-of-range rating with validation', () async {
      final repo = FixtureAgentsRepository();

      await expectLater(
        repo.postAgentReview('agent-otabek', rating: 6, actingAs: buyer),
        throwsA(
          isA<ApiErrorException>().having(
            (e) => e.code,
            'code',
            ApiErrorCode.validation,
          ),
        ),
      );
    });

    test(
      'a posted review immediately updates the agent\'s ratingAverage/ratingCount',
      () async {
        final repo = FixtureAgentsRepository();

        final before = await repo.fetchAgent('agent-otabek');
        expect(before.ratingAverage, isNull); // seeded with zero reviews
        expect(before.ratingCount, 0);

        await repo.postAgentReview('agent-otabek', rating: 4, actingAs: buyer);
        await repo.postAgentReview(
          'agent-otabek',
          rating: 5,
          actingAs: otherBuyer,
        );

        final after = await repo.fetchAgent('agent-otabek');
        expect(after.ratingAverage, 4.5);
        expect(after.ratingCount, 2);

        // The directory summary must agree with the profile detail — same
        // rule `agent_card.dart`/`agent_info_block.dart` both render from.
        final summary = (await repo.fetchAgents()).firstWhere(
          (a) => a.id == 'agent-otabek',
        );
        expect(summary.ratingAverage, 4.5);
        expect(summary.ratingCount, 2);
      },
    );
  });

  group('deleteMyAgentReview', () {
    test(
      'removes the caller\'s own review and recomputes the rating',
      () async {
        final repo = FixtureAgentsRepository();
        await repo.postAgentReview('agent-otabek', rating: 2, actingAs: buyer);

        await repo.deleteMyAgentReview('agent-otabek', actingAs: buyer);

        final page = await repo.fetchAgentReviews('agent-otabek');
        expect(page.reviews, isEmpty);
        final agent = await repo.fetchAgent('agent-otabek');
        expect(
          agent.ratingAverage,
          isNull,
          reason: 'zero reviews must read null, never 0.0',
        );
        expect(agent.ratingCount, 0);
      },
    );

    test(
      'deleting a review that was never posted is a no-op, not an error',
      () async {
        final repo = FixtureAgentsRepository();

        await repo.deleteMyAgentReview('agent-otabek', actingAs: buyer);
        // No throw is the assertion.
      },
    );
  });

  group('fetchAgentReviews paging', () {
    test('respects limit and returns a nextCursor when more remain', () async {
      final repo = FixtureAgentsRepository();
      for (var i = 0; i < 5; i++) {
        await repo.postAgentReview(
          'agent-otabek',
          rating: 3,
          actingAs: ReviewAuthor(
            id: 'buyer-$i',
            fullName: 'Buyer $i',
            avatar: null,
          ),
        );
      }

      final firstPage = await repo.fetchAgentReviews('agent-otabek', limit: 2);
      expect(firstPage.reviews.length, 2);
      expect(firstPage.nextCursor, isNotNull);

      final secondPage = await repo.fetchAgentReviews(
        'agent-otabek',
        limit: 2,
        cursor: firstPage.nextCursor,
      );
      expect(secondPage.reviews.length, 2);
      expect(
        secondPage.reviews.map((r) => r.id),
        isNot(containsAll(firstPage.reviews.map((r) => r.id))),
      );

      final lastPage = await repo.fetchAgentReviews(
        'agent-otabek',
        limit: 2,
        cursor: secondPage.nextCursor,
      );
      expect(lastPage.reviews.length, 1);
      expect(lastPage.nextCursor, isNull);
    });

    test('does not throw for an agent id with no reviews at all', () async {
      final repo = FixtureAgentsRepository();

      final page = await repo.fetchAgentReviews('agent-does-not-exist');
      expect(page.reviews, isEmpty);
      expect(page.nextCursor, isNull);
    });

    test('seeded reviews come back newest-first', () async {
      final repo = FixtureAgentsRepository();

      final page = await repo.fetchAgentReviews('agent-javlon');
      expect(page.reviews.length, 2);
      expect(
        page.reviews[0].createdAt.isAfter(page.reviews[1].createdAt),
        isTrue,
      );
    });
  });
}
