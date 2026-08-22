// Widget tests for `agent_reviews_section.dart` — the leave/edit/delete
// review surface this task adds beyond SCREENS.md. Covers the three
// call-to-action states (signed out, self, ordinary signed-in caller) and
// the full leave -> edit -> delete round trip against FakeAgentsRepository.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/agents/state/agents_repository_provider.dart';
import 'package:lacasa_mobile/features/agents/widgets/agent_reviews_section.dart';
import 'package:lacasa_mobile/features/agents/widgets/rating_input.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../auth/support/auth_test_data.dart';
import '../support/agent_test_data.dart';
import '../support/fake_agents_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<ProviderContainer> pumpSection(
    WidgetTester tester, {
    required FakeAgentsRepository repository,
    String agentId = 'agent-otabek',
    double? ratingAverage,
    int ratingCount = 0,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [agentsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/profile-stub',
      routes: [
        GoRoute(
          path: '/profile-stub',
          builder: (context, state) => Scaffold(
            body: SingleChildScrollView(
              child: AgentReviewsSection(
                agent: agentDetail(
                  id: agentId,
                  fullName: 'Otabek Yusupov',
                  ratingAverage: ratingAverage,
                  ratingCount: ratingCount,
                ),
              ),
            ),
          ),
        ),
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const Scaffold(body: Text('login-stub')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  group('signed out', () {
    testWidgets('shows the sign-in prompt, not a form', (tester) async {
      await pumpSection(tester, repository: FakeAgentsRepository());

      expect(find.text('Sign in to leave a review.'), findsOneWidget);
      expect(find.text('Leave a review'), findsNothing);
    });

    testWidgets('Sign In pushes the login route', (tester) async {
      await pumpSection(tester, repository: FakeAgentsRepository());

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('login-stub'), findsOneWidget);
    });
  });

  group('self-review', () {
    testWidgets('viewing your own profile shows an explanation, no button', (
      tester,
    ) async {
      final container = await pumpSection(
        tester,
        repository: FakeAgentsRepository(),
        agentId: 'agent-otabek',
      );
      container
          .read(authSessionProvider.notifier)
          .signIn(authUser(id: 'agent-otabek', role: UserRole.agent));
      await tester.pumpAndSettle();

      expect(find.text("You can't review your own profile."), findsOneWidget);
      expect(find.text('Leave a review'), findsNothing);
      expect(find.text('Edit your review'), findsNothing);
    });
  });

  group('empty state', () {
    testWidgets('no reviews shows "No reviews yet."', (tester) async {
      await pumpSection(
        tester,
        repository: FakeAgentsRepository(reviews: const []),
      );

      expect(find.text('No reviews yet.'), findsOneWidget);
    });
  });

  group('leave a review', () {
    testWidgets(
      'posting opens the sheet, submits, and flips to "Edit your review"',
      (tester) async {
        final repo = FakeAgentsRepository(reviews: const []);
        final container = await pumpSection(tester, repository: repo);
        container
            .read(authSessionProvider.notifier)
            .signIn(authUser(id: 'buyer-1', fullName: 'A Buyer'));
        await tester.pumpAndSettle();

        expect(find.text('Leave a review'), findsOneWidget);
        await tester.tap(find.text('Leave a review'));
        await tester.pumpAndSettle();

        expect(find.text('Leave a Review'), findsOneWidget); // sheet title

        // Pick 4 stars — the 4th of the five tappable star icons.
        await tester.tap(find.byIcon(Icons.star_outline_rounded).at(3));
        await tester.pump();
        await tester.enterText(find.byType(TextField), 'Great to work with.');
        await tester.tap(find.text('Post review'));
        await tester.pumpAndSettle();

        expect(repo.postAgentReviewCallCount, 1);
        expect(find.text('Review posted.'), findsOneWidget);
        expect(find.text('Edit your review'), findsOneWidget);
        expect(find.text('A Buyer'), findsOneWidget); // now in the reviews list
      },
    );

    testWidgets('choosing no rating blocks submit with an inline error', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(reviews: const []);
      final container = await pumpSection(tester, repository: repo);
      container
          .read(authSessionProvider.notifier)
          .signIn(authUser(id: 'buyer-1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leave a review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Post review'));
      await tester.pump();

      expect(find.text('Please choose a rating.'), findsOneWidget);
      expect(repo.postAgentReviewCallCount, 0);
    });
  });

  // `agent_review_sheet.dart`'s `_messageFor` turns a failed post or delete
  // into the sentence the user actually reads, and every one of its branches
  // was unexercised — including the `forbidden` one, which is the server-side
  // backstop for a self-review the client-side check can lose a race to (the
  // caller signs in as the agent in another tab between the sheet opening and
  // Post being tapped). A mapping nothing asserts is a mapping free to drift
  // into a single generic "something went wrong", which is exactly what this
  // sheet was built not to say.
  group('failure messages', () {
    Future<void> submitAReview(
      WidgetTester tester,
      ProviderContainer container,
    ) async {
      container
          .read(authSessionProvider.notifier)
          .signIn(authUser(id: 'buyer-1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Leave a review'));
      await tester.pumpAndSettle();
      // Fifth star — any rating will do, this just clears the inline
      // "Please choose a rating." guard so the repository actually gets called.
      await tester.tap(
        find
            .descendant(
              of: find.byType(RatingInput),
              matching: find.byIcon(Icons.star_outline_rounded),
            )
            .last,
      );
      await tester.pumpAndSettle();
      await tester.tap(find.text('Post review'));
      await tester.pumpAndSettle();
    }

    ApiErrorException apiError(
      ApiErrorCode code, {
      String message = 'server text',
      int status = 400,
    }) => ApiErrorException(
      body: ApiErrorBody(code: code, message: message),
      statusCode: status,
    );

    for (final (code, status, expected) in const [
      (ApiErrorCode.forbidden, 403, "You can't review yourself."),
      (ApiErrorCode.notFound, 404, 'This agent is no longer available.'),
    ]) {
      testWidgets(
        'a ${code.name} post failure shows its own specific message',
        (tester) async {
          final repo = FakeAgentsRepository(
            reviews: const [],
            postReviewError: apiError(code, status: status),
          );
          final container = await pumpSection(tester, repository: repo);
          await submitAReview(tester, container);

          expect(find.text(expected), findsOneWidget);
          // The sheet stays open on failure — closing it would discard what
          // the user just typed for an error they may be able to act on.
          expect(find.text('Post review'), findsOneWidget);
        },
      );
    }

    testWidgets(
      'a validation failure passes the server message straight through',
      (tester) async {
        final repo = FakeAgentsRepository(
          reviews: const [],
          postReviewError: apiError(
            ApiErrorCode.validation,
            message: 'Comment must be 2000 characters or fewer.',
          ),
        );
        final container = await pumpSection(tester, repository: repo);
        await submitAReview(tester, container);

        // Deliberately the server's own wording, not a client rewrite: only
        // the server knows which field it rejected and why.
        expect(
          find.text('Comment must be 2000 characters or fewer.'),
          findsOneWidget,
        );
      },
    );

    testWidgets('an unrecognised code falls back to the generic message', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        reviews: const [],
        postReviewError: apiError(
          ApiErrorCode.unknown,
          message: 'boom',
          status: 500,
        ),
      );
      final container = await pumpSection(tester, repository: repo);
      await submitAReview(tester, container);

      expect(
        find.text("Couldn't save your review right now. Please try again."),
        findsOneWidget,
      );
    });

    testWidgets(
      'a failed delete surfaces through the same mapping and reopens the sheet',
      (tester) async {
        final repo = FakeAgentsRepository(
          reviews: [
            agentReview(
              id: 'review-1',
              rating: 3,
              comment: 'It was okay.',
              authorId: 'buyer-1',
              authorFullName: 'A Buyer',
            ),
          ],
          deleteReviewError: apiError(ApiErrorCode.notFound, status: 404),
        );
        final container = await pumpSection(tester, repository: repo);
        container
            .read(authSessionProvider.notifier)
            .signIn(authUser(id: 'buyer-1'));
        await tester.pumpAndSettle();

        await tester.tap(find.text('Edit your review'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Delete review'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('deleteConfirmDelete')));
        await tester.pumpAndSettle();

        expect(repo.deleteMyAgentReviewCallCount, 1);
        expect(find.text('This agent is no longer available.'), findsOneWidget);
        // The review survives a failed delete — a sheet that closed here would
        // imply the delete worked.
        expect(find.text('Edit Your Review'), findsOneWidget);
      },
    );
  });

  group('editing an existing review', () {
    testWidgets('the sheet pre-fills the caller\'s own rating and comment', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        reviews: [
          agentReview(
            id: 'review-1',
            rating: 3,
            comment: 'It was okay.',
            authorId: 'buyer-1',
            authorFullName: 'A Buyer',
          ),
        ],
      );
      final container = await pumpSection(tester, repository: repo);
      container
          .read(authSessionProvider.notifier)
          .signIn(authUser(id: 'buyer-1'));
      await tester.pumpAndSettle();

      expect(find.text('Edit your review'), findsOneWidget);
      await tester.tap(find.text('Edit your review'));
      await tester.pumpAndSettle();

      final commentField = tester.widget<TextField>(find.byType(TextField));
      expect(commentField.controller!.text, 'It was okay.');
      // Scoped to the picker specifically — the review tile behind the
      // sheet renders its own (non-interactive) stars for the same review
      // and is still in the tree underneath a modal bottom sheet, so an
      // unscoped icon count would double-count both rows.
      final picker = find.byType(RatingInput);
      expect(
        find.descendant(of: picker, matching: find.byIcon(Icons.star_rounded)),
        findsNWidgets(3),
      );
      expect(
        find.descendant(
          of: picker,
          matching: find.byIcon(Icons.star_outline_rounded),
        ),
        findsNWidgets(2),
      );

      await tester.tap(find.text('Update review'));
      await tester.pumpAndSettle();

      expect(repo.postAgentReviewCallCount, 1);
      expect(find.text('Review updated.'), findsOneWidget);
    });

    testWidgets('Delete review removes it after confirmation', (tester) async {
      final repo = FakeAgentsRepository(
        reviews: [
          agentReview(
            id: 'review-1',
            rating: 3,
            authorId: 'buyer-1',
            authorFullName: 'A Buyer',
          ),
        ],
      );
      final container = await pumpSection(tester, repository: repo);
      container
          .read(authSessionProvider.notifier)
          .signIn(authUser(id: 'buyer-1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit your review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete review'));
      await tester.pumpAndSettle();

      // The shared delete-confirm alert.
      expect(find.text('Delete review?'), findsOneWidget);
      await tester.tap(find.byKey(const ValueKey('deleteConfirmDelete')));
      await tester.pumpAndSettle();

      expect(repo.deleteMyAgentReviewCallCount, 1);
      expect(find.text('Review deleted.'), findsOneWidget);
      expect(find.text('Leave a review'), findsOneWidget);
      expect(find.text('No reviews yet.'), findsOneWidget);
    });

    testWidgets('cancelling the delete confirm leaves the review intact', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        reviews: [
          agentReview(
            id: 'review-1',
            rating: 3,
            authorId: 'buyer-1',
            authorFullName: 'A Buyer',
          ),
        ],
      );
      final container = await pumpSection(tester, repository: repo);
      container
          .read(authSessionProvider.notifier)
          .signIn(authUser(id: 'buyer-1'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Edit your review'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete review'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('deleteConfirmCancel')));
      await tester.pumpAndSettle();

      expect(repo.deleteMyAgentReviewCallCount, 0);
      // Sheet stays open — cancelling the alert only dismisses the alert.
      expect(find.text('Edit Your Review'), findsOneWidget);
    });
  });

  group('timezone', () {
    // `AgentReview.createdAt` comes off the wire through
    // `dateTimeFromWireTimestamp`, which builds its `DateTime` with
    // `isUtc: true`, and `Formatters.date` reads plain calendar/clock fields
    // off whatever it is handed. Without `.toLocal()` a review left at 09:00
    // Tashkent rendered "04:00", and one left before 05:00 local rendered on
    // the previous day — right beside the reviewer's name.
    //
    // The expectation is derived rather than hardcoded for the same reason
    // `kanban_column_test.dart`'s timezone group derives its own: a test
    // process's local zone is whatever the machine is set to and Dart fixes
    // it at process start, so a literal would only be right on one machine.
    // Under UTC this is a tautology; under every other zone — including this
    // app's own UTC+5 market — it fails the moment the conversion is dropped.
    testWidgets('a review tile dates the instant in local time', (
      tester,
    ) async {
      const seconds = 1754784000;
      await pumpSection(
        tester,
        repository: FakeAgentsRepository(
          reviews: [
            agentReview(
              id: 'review-1',
              rating: 5,
              comment: 'Great agent.',
              authorId: 'buyer-1',
              authorFullName: 'A Buyer',
              createdAtSeconds: seconds,
            ),
          ],
        ),
      );

      final createdAt = DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      );
      expect(
        find.text(Formatters.date(createdAt.toLocal())),
        findsOneWidget,
        reason: 'the raw UTC clock fields must not reach the review tile',
      );
    });
  });

  group('load more', () {
    testWidgets('a page under the page size never shows the button', (
      tester,
    ) async {
      final repo = FakeAgentsRepository(
        reviews: [
          for (var i = 0; i < 3; i++)
            agentReview(
              id: 'review-$i',
              rating: 4,
              authorId: 'buyer-$i',
              authorFullName: 'Buyer $i',
            ),
        ],
      );

      await pumpSection(tester, repository: repo);

      expect(find.text('Show more reviews'), findsNothing);
    });

    testWidgets(
      'more than one page shows the button, and tapping appends the rest',
      (tester) async {
        // agentReviewsPageSize is 10 — 13 reviews makes exactly two pages.
        final repo = FakeAgentsRepository(
          reviews: [
            for (var i = 0; i < 13; i++)
              agentReview(
                id: 'review-$i',
                rating: 4,
                authorId: 'buyer-$i',
                authorFullName: 'Buyer $i',
              ),
          ],
        );

        await pumpSection(tester, repository: repo);

        expect(find.text('Buyer 0'), findsOneWidget);
        await tester.scrollUntilVisible(
          find.text('Show more reviews'),
          200,
          scrollable: find.byType(Scrollable),
        );
        expect(find.text('Buyer 10'), findsNothing);
        expect(find.text('Show more reviews'), findsOneWidget);

        await tester.tap(find.text('Show more reviews'));
        await tester.pumpAndSettle();

        await tester.scrollUntilVisible(
          find.text('Buyer 12'),
          200,
          scrollable: find.byType(Scrollable),
        );
        expect(find.text('Buyer 12'), findsOneWidget);
        expect(find.text('Show more reviews'), findsNothing);
      },
    );
  });
}
