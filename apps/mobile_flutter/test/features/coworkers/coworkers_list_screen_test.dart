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
      expect(find.text('+998901112233'), findsOneWidget);
      // Only the 2 ads whose coworkerId matches — the 3rd (a different
      // coworker) must not be counted.
      expect(find.text('2 listings'), findsOneWidget);
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

      expect(find.text('—'), findsOneWidget);
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
      expect(find.text('—'), findsWidgets);
    });

    testWidgets('empty state is §35 copy verbatim', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(coworkers: const []),
      );

      expect(find.text('No coworkers yet.'), findsOneWidget);
    });

    testWidgets('a roster load failure shows Retry and re-fetches', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        listError: const NetworkException('offline'),
      );

      await pumpScreen(tester, repository: repo);

      expect(find.text("Couldn't load your coworkers"), findsOneWidget);
      expect(repo.listCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

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

  group('"+ Add new coworker" (WORK_TAB_CONTRACT.md ruling on solo_realtor)', () {
    testWidgets('visible for an agency agent', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        role: UserRole.agent,
        realtorKind: RealtorKind.agency,
      );

      expect(find.text('+ Add new coworker'), findsOneWidget);
    });

    testWidgets('hidden for a solo agent', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        role: UserRole.agent,
        realtorKind: RealtorKind.solo,
      );

      expect(find.text('+ Add new coworker'), findsNothing);
    });

    testWidgets('hidden for a coworker session', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        role: UserRole.coworker,
        realtorKind: null,
      );

      expect(find.text('+ Add new coworker'), findsNothing);
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
