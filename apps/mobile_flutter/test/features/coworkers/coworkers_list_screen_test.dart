// Widget tests for `coworkers-list` (lib/features/coworkers/). Pumped
// inside a real GoRouter — the header's back control branches on
// `context.canPop()` and a row/button tap pushes a route, neither of which
// exists without a router in the tree, same reasoning as
// `test/features/agents/agent_profile_screen_test.dart`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/coworkers/coworkers.dart';
import 'package:lacasa_mobile/features/coworkers/state/coworkers_repository_provider.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import 'support/coworker_test_data.dart';
import 'support/fake_coworkers_repository.dart';

void main() {
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required FakeCoworkersRepository repository,
    UserRole? role = UserRole.agent,
    RealtorKind? realtorKind = RealtorKind.agency,
    bool withBackStack = true,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [coworkersRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    if (role != null) {
      container
          .read(authSessionProvider.notifier)
          .signIn(authUser(id: 'user-a', role: role, realtorKind: realtorKind));
    }

    final router = GoRouter(
      initialLocation: RoutePaths.work,
      routes: [
        GoRoute(
          path: RoutePaths.work,
          builder: (context, state) => const Scaffold(body: Text('work-root')),
          routes: [
            GoRoute(
              path: 'coworkers',
              builder: (context, state) => const CoworkersListScreen(),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) =>
                      const Scaffold(body: Text('add-coworker-stub')),
                ),
                GoRoute(
                  path: ':id',
                  builder: (context, state) => Scaffold(
                    body: Text(
                      'coworker-detail-stub-${state.pathParameters['id']}',
                    ),
                  ),
                ),
              ],
            ),
          ],
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

    if (withBackStack) {
      router.push(RoutePaths.workCoworkers);
    } else {
      router.go(RoutePaths.workCoworkers);
    }
    await tester.pumpAndSettle();

    return container;
  }

  group('header', () {
    testWidgets('shows the §35 title', (tester) async {
      await pumpScreen(tester, repository: FakeCoworkersRepository());
      expect(find.text('Coworkers'), findsOneWidget);
    });

    testWidgets('back pops to the route below', (tester) async {
      await pumpScreen(tester, repository: FakeCoworkersRepository());

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('work-root'), findsOneWidget);
    });

    testWidgets('a deep link with nothing to pop still leaves via back', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        withBackStack: false,
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('work-root'), findsOneWidget);
    });
  });

  group('roster', () {
    testWidgets('renders rows with name, phone, and derived ads count', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        coworkers: [
          coworker(
            id: 'coworker-sardor',
            fullName: 'Sardor Abdullayev',
            phoneNumber: '+998901112233',
          ),
        ],
        ads: [
          coworkerAd(id: 'ad-1', coworkerId: 'coworker-sardor'),
          coworkerAd(id: 'ad-2', coworkerId: 'coworker-sardor'),
          coworkerAd(id: 'ad-3', coworkerId: 'coworker-other'),
        ],
      );

      await pumpScreen(tester, repository: repo);

      expect(find.text('Sardor Abdullayev'), findsOneWidget);
      // §35's row subtitle is one line joining count and phone — the mockup's
      // `.lrow__s` ("11 ads · +998 90 444 55 66"). Only the 2 ads whose
      // coworkerId matches — the 3rd (a different coworker) must not be
      // counted.
      expect(find.text('2 ads · +998901112233'), findsOneWidget);
    });

    testWidgets('a coworker with no phone shows a dash, not a blank row', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        coworkers: [
          coworker(id: 'coworker-a', fullName: 'Kamola Rashidova', phoneNumber: null),
        ],
      );

      await pumpScreen(tester, repository: repo);

      // The dash now sits in the joined `.lrow__s` subtitle line.
      expect(find.textContaining('—'), findsOneWidget);
    });

    testWidgets('an ads-fetch failure degrades only the count, not the row', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        coworkers: [coworker(id: 'coworker-a', fullName: 'Kamola Rashidova')],
        adsError: const NetworkException('offline'),
      );

      await pumpScreen(tester, repository: repo);

      expect(find.text('Kamola Rashidova'), findsOneWidget);
      // Count and phone share one joined `.lrow__s` line now. Only the count
      // degrades to an em dash — the phone came from the roster call, which
      // succeeded, so it must still be printed. That is the whole point of
      // this test: the failure is contained to the half it belongs to.
      expect(find.text('— · +998901112233'), findsOneWidget);
    });

    testWidgets('empty state is §35 copy verbatim', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(coworkers: const []),
      );

      expect(find.text('No coworkers yet.'), findsOneWidget);
    });

    testWidgets(
      'an agency agent\'s empty state offers Add coworker, which pushes the '
      'create screen',
      (tester) async {
        await pumpScreen(
          tester,
          repository: FakeCoworkersRepository(coworkers: const []),
          role: UserRole.agent,
          realtorKind: RealtorKind.agency,
        );

        // Until this, the only way forward from an empty roster was an
        // unlabelled 38px "+" in the header — the state named a fact and
        // offered nothing to tap.
        await tester.tap(find.text('Add coworker'));
        await tester.pumpAndSettle();

        expect(find.text('add-coworker-stub'), findsOneWidget);
      },
    );

    testWidgets(
      'a solo agent\'s empty state offers no action — the create would 403',
      (tester) async {
        await pumpScreen(
          tester,
          repository: FakeCoworkersRepository(coworkers: const []),
          role: UserRole.agent,
          realtorKind: RealtorKind.solo,
        );

        // Same predicate as the header's "+" (WORK_TAB_CONTRACT.md's
        // solo_realtor ruling): an invitation into a wall is worse than no
        // invitation.
        expect(find.text('No coworkers yet.'), findsOneWidget);
        expect(find.text('Add coworker'), findsNothing);
      },
    );

    testWidgets(
      'a coworker session\'s empty state offers no action either',
      (tester) async {
        await pumpScreen(
          tester,
          repository: FakeCoworkersRepository(coworkers: const []),
          role: UserRole.coworker,
          realtorKind: null,
        );

        expect(find.text('Add coworker'), findsNothing);
      },
    );

    testWidgets(
      'a roster load failure with no connection names the connection, not '
      'the screen, and Retry re-fetches',
      (tester) async {
        final repo = FakeCoworkersRepository(
          listError: const NetworkException('offline'),
        );

        await pumpScreen(tester, repository: repo);

        // Was "Couldn't load your coworkers" — one of a dozen identical
        // anonymous per-screen sentences an offline app used to fragment
        // into. See `lib/shared/widgets/read_error.dart`.
        expect(
          find.text('No connection. Check your network and try again.'),
          findsOneWidget,
        );
        expect(find.text("Couldn't load your coworkers"), findsNothing);
        expect(repo.listCallCount, 1);

        await tester.tap(find.text('Retry'));
        await tester.pumpAndSettle();

        expect(repo.listCallCount, 2);
      },
    );

    testWidgets(
      'a failure that did reach the server keeps this screen\'s own copy',
      (tester) async {
        // Not a NetworkException: the request got an answer, it was just a
        // bad one, and "which screen failed" is then the most specific thing
        // the app knows.
        final repo = FakeCoworkersRepository(listError: Exception('boom'));

        await pumpScreen(tester, repository: repo);

        expect(find.text("Couldn't load your coworkers"), findsOneWidget);
        expect(
          find.text('No connection. Check your network and try again.'),
          findsNothing,
        );
      },
    );

    testWidgets('pull-to-refresh reloads the roster and the ads counts', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        coworkers: [coworker(id: 'coworker-a', fullName: 'Kamola Rashidova')],
      );

      await pumpScreen(tester, repository: repo);
      expect(repo.listCallCount, 1);
      expect(repo.summaryCallCount, 1);

      await tester.fling(find.byType(ListView), const Offset(0, 250), 1000);
      await tester.pumpAndSettle();

      // `coworkersListProvider` is deliberately not `.autoDispose`, so
      // before this gesture a roster change made from the console never
      // reached an open screen. The counts come from a second provider and
      // would otherwise stay at yesterday's numbers under a fresh list.
      expect(repo.listCallCount, 2);
      expect(repo.summaryCallCount, 2);
    });

    testWidgets('the pull gesture still works when the roster is empty', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(coworkers: const []);

      await pumpScreen(tester, repository: repo);
      expect(repo.listCallCount, 1);

      await tester.fling(find.byType(ListView), const Offset(0, 250), 1000);
      await tester.pumpAndSettle();

      // An empty roster is exactly when a user pulls to see whether an
      // invite has landed — and exactly when a default-physics scroller is
      // too short to overscroll at all.
      expect(repo.listCallCount, 2);
    });

    testWidgets('tapping a row pushes coworker-detail', (tester) async {
      final repo = FakeCoworkersRepository(
        coworkers: [coworker(id: 'coworker-a', fullName: 'Kamola Rashidova')],
      );

      await pumpScreen(tester, repository: repo);

      await tester.tap(find.byKey(const ValueKey('coworkerRow-coworker-a')));
      await tester.pumpAndSettle();

      expect(find.text('coworker-detail-stub-coworker-a'), findsOneWidget);
    });

    testWidgets('shows a shimmer skeleton while loading, then settles', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = FakeCoworkersRepository(hold: gate, coworkers: const []);

      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [coworkersRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container
          .read(authSessionProvider.notifier)
          .signIn(authUser(id: 'user-a', role: UserRole.agent, realtorKind: RealtorKind.agency));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const CoworkersListScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Coworkers'), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(ShimmerBox), findsNothing);
    });
  });

  // The mockup's own affordance is `.nav .rnd.acc` — an icon-only circle in
  // the header's trailing slot — so §35's "+ Add new coworker" copy now
  // reaches the user through the button's semantics label rather than an
  // on-screen text run. The visibility rule below is unchanged.
  group('"+ Add new coworker" (WORK_TAB_CONTRACT.md ruling on solo_realtor)', () {
    testWidgets('visible for an agency agent', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        role: UserRole.agent,
        realtorKind: RealtorKind.agency,
      );

      expect(find.bySemanticsLabel('+ Add new coworker'), findsOneWidget);
    });

    testWidgets('hidden for a solo agent', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        role: UserRole.agent,
        realtorKind: RealtorKind.solo,
      );

      expect(find.bySemanticsLabel('+ Add new coworker'), findsNothing);
      expect(find.byKey(const ValueKey('addCoworkerButton')), findsNothing);
    });

    testWidgets('hidden for a coworker session', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        role: UserRole.coworker,
        realtorKind: null,
      );

      expect(find.bySemanticsLabel('+ Add new coworker'), findsNothing);
      expect(find.byKey(const ValueKey('addCoworkerButton')), findsNothing);
    });

    testWidgets('tapping it pushes add-coworker', (tester) async {
      await pumpScreen(tester, repository: FakeCoworkersRepository());

      await tester.tap(find.byKey(const ValueKey('addCoworkerButton')));
      await tester.pumpAndSettle();

      expect(find.text('add-coworker-stub'), findsOneWidget);
    });
  });

  group('layout holds at real phone widths', () {
    for (final size in const [
      (label: 'small android', size: Size(360, 800)),
      (label: 'iphone 14', size: Size(390, 844)),
      (label: 'pro max', size: Size(430, 932)),
    ]) {
      testWidgets('no overflow at ${size.label}', (tester) async {
        tester.view.physicalSize = size.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpScreen(
          tester,
          repository: FakeCoworkersRepository(
            coworkers: [
              coworker(
                id: 'coworker-a',
                fullName: 'Shahnoza Yoldosheva-Abdurahmonova',
                phoneNumber: '+998901234567',
              ),
              coworker(id: 'coworker-b', fullName: 'Kamola Rashidova', phoneNumber: null),
            ],
            ads: [coworkerAd(id: 'ad-1', coworkerId: 'coworker-a')],
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
