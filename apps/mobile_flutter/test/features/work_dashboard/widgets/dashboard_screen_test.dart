// Widget tests for `dashboard` (SCREENS.md §24, lib/features/work_dashboard/).
// Pumped inside a real GoRouter — the bell icon and every tile/row/coworker
// row navigate via context.push/context.go, none of which exists without a
// router in the tree, same reasoning as
// test/features/coworkers/coworkers_list_screen_test.dart.
//
// These tests exercise fixture-mode rendering only (`useLiveWorkDashboardApi`
// defaults false and is a compile-time `bool.fromEnvironment` switch, not
// something a widget test can flip at runtime) — the live-mode 2-bar
// "Created vs sold" branch in `ads_statistics_panel.dart` is exercised by
// `dart analyze` + manual review only, matching how `home_feed_screen_test`
// only ever pumps the app's real default wiring, never the live-API branch.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_repository_provider.dart';
import 'package:lacasa_mobile/features/work_dashboard/work_dashboard.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/dashboard_test_data.dart';
import '../support/fake_dashboard_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<ProviderContainer> pumpDashboard(
    WidgetTester tester, {
    required FakeDashboardRepository repository,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).setRole(UserRole.agent);

    final router = GoRouter(
      initialLocation: RoutePaths.work,
      routes: [
        GoRoute(
          path: RoutePaths.work,
          builder: (context, state) => const Scaffold(body: Text('work-root')),
          routes: [
            GoRoute(
              path: 'dashboard',
              builder: (context, state) => const DashboardScreen(),
            ),
            GoRoute(
              path: 'notifications',
              builder: (context, state) =>
                  const Scaffold(body: Text('notifications-stub')),
            ),
            GoRoute(
              path: 'my-listings',
              builder: (context, state) =>
                  const Scaffold(body: Text('my-listings-stub')),
            ),
            GoRoute(
              path: 'leads',
              builder: (context, state) =>
                  const Scaffold(body: Text('leads-stub')),
            ),
            GoRoute(
              path: 'coworkers',
              builder: (context, state) =>
                  const Scaffold(body: Text('coworkers-list-stub')),
              routes: [
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
        child: MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, theme: AppTheme.light(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    router.go(RoutePaths.workDashboard);
    await tester.pumpAndSettle();

    return container;
  }

  final coworkers = [
    const Coworker(
      id: 'cw-1',
      fullName: 'Sardor Abdullayev',
      email: 'sardor@lacasa.uz',
      phoneNumber: null,
      avatar: null,
      agentId: 'agent-1',
    ),
    const Coworker(
      id: 'cw-2',
      fullName: 'Kamola Rashidova',
      email: 'kamola@lacasa.uz',
      phoneNumber: null,
      avatar: null,
      agentId: 'agent-1',
    ),
  ];

  final ads = [
    testAd(id: 'ad-1', coworkerId: 'cw-1'),
    testAd(id: 'ad-2', coworkerId: 'cw-1', stage: '3'), // draft
    testAd(id: 'ad-3', coworkerId: 'cw-2'),
    testAd(id: 'ad-4'), // the agent's own, no coworker
  ];

  final leads = [
    testLead(id: 'lead-1', coworkerId: 'cw-1'),
    testLead(
      id: 'lead-2',
      coworkerId: 'cw-1',
      status: 'need_to_call_back',
      callbackIso: '2000-01-01T00:00:00.000Z', // long overdue -> due today
    ),
    testLead(id: 'lead-3', coworkerId: 'cw-2'),
  ];

  // Backs the Coworker statistics section's "Ads count" column, per
  // `coworkerStatRowsProvider`'s own event-stream fold (not `ads` above —
  // see that provider's doc comment for why the two columns use different
  // real sources). Sardor: 3 adCreated + 1 adSold (the adSold row must NOT
  // count toward "Ads count", and 3 is deliberately distinct from Sardor's
  // own 2-lead count below so the row's two numeric columns never collide).
  // Kamola: 4 adCreated.
  final coworkerActivity = [
    testActivityEvent(id: 'evt-1', coworkerId: 'cw-1'),
    testActivityEvent(id: 'evt-2', coworkerId: 'cw-1'),
    testActivityEvent(id: 'evt-3', coworkerId: 'cw-1'),
    testActivityEvent(id: 'evt-4', coworkerId: 'cw-1', stage: 2), // adSold
    testActivityEvent(id: 'evt-5', coworkerId: 'cw-2'),
    testActivityEvent(id: 'evt-6', coworkerId: 'cw-2'),
    testActivityEvent(id: 'evt-7', coworkerId: 'cw-2'),
    testActivityEvent(id: 'evt-8', coworkerId: 'cw-2'),
  ];

  // The fixture-mode chart (`ads_statistics_panel.dart`'s `_FixtureAreaChart`)
  // always renders day-axis labels "1"/"3"/"5"/"7"/"9"/"11"/"12" alongside
  // the stat tiles, so a bare `find.text('5')` is ambiguous whenever a tile
  // value happens to land on one of those digits. Every stat-tile value
  // assertion below is scoped to its own tile's key for that reason.
  Finder tileValue(String tileKey, String value) => find.descendant(
    of: find.byKey(ValueKey(tileKey)),
    matching: find.text(value),
  );

  // "Coworkers" is not unique on this screen — the stat tile's own label
  // and the workspace-link row's title both read "Coworkers" verbatim, so a
  // bare `find.text('Coworkers')` is ambiguous. Scope to the stat tile.
  Finder tileLabel(String tileKey, String label) => find.descendant(
    of: find.byKey(ValueKey(tileKey)),
    matching: find.text(label),
  );

  group('stat tiles (SCREENS.md §24)', () {
    testWidgets('renders the default This-month totals and subtitles', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        repository: FakeDashboardRepository(
          adsStatisticsByFilter: {
            StatisticsFilter.thisMonth: const AdsStatistics(
              adsNewCount: 10,
              adsSoldCount: 5,
            ),
          },
          coworkers: coworkers,
          ads: ads,
          leads: leads,
        ),
      );

      expect(find.text('Statistics'), findsOneWidget);
      expect(find.text('Ads created'), findsOneWidget);
      expect(tileValue('dashboardTile-adsCreated', '10'), findsOneWidget);
      expect(find.text('Ads sold'), findsOneWidget);
      expect(tileValue('dashboardTile-adsSold', '5'), findsOneWidget);
      // Two of §24's tiles' subtitle both read "this month" by default.
      expect(find.text('this month'), findsNWidgets(2));

      expect(find.text('Active leads'), findsOneWidget);
      expect(tileValue('dashboardTile-activeLeads', '3'), findsOneWidget);
      expect(find.text('1 needs a call back'), findsOneWidget);

      expect(tileLabel('dashboardTile-coworkers', 'Coworkers'), findsOneWidget);
      expect(tileValue('dashboardTile-coworkers', '2'), findsOneWidget);
      expect(find.text('tap to manage'), findsOneWidget);
    });

    testWidgets('tapping the Coworkers tile pushes to coworkers-list', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        repository: FakeDashboardRepository(coworkers: coworkers),
      );

      await tester.tap(find.byKey(const ValueKey('dashboardTile-coworkers')));
      await tester.pumpAndSettle();

      expect(find.text('coworkers-list-stub'), findsOneWidget);
    });

    testWidgets(
      'a failed ads-statistics fetch shows Retry without blanking the other tiles',
      (tester) async {
        await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(
            adsStatisticsError: const NetworkException('offline'),
            coworkers: coworkers,
          ),
        );

        // Both Ads-statistics tiles share the one failed provider, so both
        // show their own Retry affordance.
        expect(find.text('Retry'), findsNWidgets(2));
        // Coworkers tile (a different provider) still renders fine.
        expect(tileLabel('dashboardTile-coworkers', 'Coworkers'), findsOneWidget);
      },
    );

    testWidgets('the bell icon pushes to work notifications', (tester) async {
      await pumpDashboard(tester, repository: FakeDashboardRepository());

      await tester.tap(
        find.byKey(const ValueKey('dashboardNotificationsButton')),
      );
      await tester.pumpAndSettle();

      expect(find.text('notifications-stub'), findsOneWidget);
    });
  });

  group('time-range selector', () {
    testWidgets('This month is selected by default', (tester) async {
      await pumpDashboard(tester, repository: FakeDashboardRepository());

      expect(
        find.byKey(const ValueKey('dashboardRange-thisMonth')),
        findsOneWidget,
      );
    });

    testWidgets(
      'chips render left-to-right in SCREENS.md §24 order: All, This month, This week, Today',
      (tester) async {
        await pumpDashboard(tester, repository: FakeDashboardRepository());

        double leftEdge(String key) =>
            tester.getTopLeft(find.byKey(ValueKey(key))).dx;

        final order = [
          'dashboardRange-all',
          'dashboardRange-thisMonth',
          'dashboardRange-thisWeek',
          'dashboardRange-today',
        ].map(leftEdge).toList();

        expect(
          order,
          List.of(order)..sort(),
          reason: 'chips must appear in ascending x-position in this exact order',
        );
      },
    );

    testWidgets(
      'selecting This week re-fetches ads statistics for that filter',
      (tester) async {
        final repository = FakeDashboardRepository(
          adsStatisticsByFilter: {
            StatisticsFilter.thisMonth: const AdsStatistics(
              adsNewCount: 10,
              adsSoldCount: 3,
            ),
            StatisticsFilter.thisWeek: const AdsStatistics(
              adsNewCount: 4,
              adsSoldCount: 1,
            ),
          },
        );
        await pumpDashboard(tester, repository: repository);

        expect(tileValue('dashboardTile-adsCreated', '10'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('dashboardRange-thisWeek')),
        );
        await tester.pumpAndSettle();

        expect(
          repository.adsStatisticsFilterCalls,
          contains(StatisticsFilter.thisWeek),
        );
        expect(tileValue('dashboardTile-adsCreated', '4'), findsOneWidget);
        expect(find.text('this week'), findsNWidgets(2));
      },
    );
  });

  group('ads statistics panel (fixture mode)', () {
    testWidgets('renders the static 12-point chart with its legend', (
      tester,
    ) async {
      await pumpDashboard(tester, repository: FakeDashboardRepository());

      expect(find.text('Ads statistics'), findsOneWidget);
      expect(find.text('Days 1–12'), findsOneWidget);
      expect(find.text('Created'), findsOneWidget);
      expect(find.text('Sold'), findsOneWidget);
    });
  });

  group('coworker statistics section', () {
    Finder rowValue(String coworkerId, String value) => find.descendant(
      of: find.byKey(ValueKey('coworkerStatListRow-$coworkerId')),
      matching: find.text(value),
    );

    testWidgets('renders both coworkers with real Ads/Lead counts', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        repository: FakeDashboardRepository(
          coworkers: coworkers,
          coworkerActivity: coworkerActivity,
          leads: leads,
        ),
      );

      expect(find.text('Sardor Abdullayev'), findsOneWidget);
      expect(find.text('Kamola Rashidova'), findsOneWidget);
      // Sardor: 3 adCreated events (the 1 adSold event must not count), 2
      // leads. Kamola: 4 adCreated events, 1 lead.
      expect(rowValue('cw-1', '3'), findsOneWidget);
      expect(rowValue('cw-1', '2'), findsOneWidget);
      expect(rowValue('cw-2', '4'), findsOneWidget);
      expect(rowValue('cw-2', '1'), findsOneWidget);
    });

    testWidgets(
      '"Sale count" is a real number now: a genuine zero renders 0, never '
      'the honesty em dash',
      (tester) async {
        // "Sale count" used to be a permanent em dash (no backing data
        // existed). It's real now — `coworkerStatRowsProvider` folds the
        // same `coworkerActivity` stream `adsCount` already reads, filtered
        // to `ActivityEventStage.adSold` instead of `adCreated` (see
        // `coworker_statistics_section.dart`'s doc comment). `coworkerActivity`
        // above gives Sardor (cw-1) exactly one adSold event and Kamola
        // (cw-2) none, so this one fixture set exercises both halves of the
        // honesty guarantee at once: a real non-zero count, and a true zero
        // that must still render "0" rather than fall back to the
        // fetch-still-pending "—" placeholder.
        await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(
            coworkers: coworkers,
            coworkerActivity: coworkerActivity,
            leads: leads,
          ),
        );

        expect(rowValue('cw-1', '1'), findsOneWidget);
        expect(rowValue('cw-2', '0'), findsOneWidget);
        // The "—" placeholder is reserved for a fetch that hasn't resolved
        // yet — every fetch here has, so none should be showing.
        expect(find.text('—'), findsNothing);
      },
    );

    testWidgets('tapping a coworker row navigates (go) to coworker-detail', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        repository: FakeDashboardRepository(coworkers: coworkers),
      );

      final row = find.byKey(const ValueKey('coworkerStatListRow-cw-1'));
      await tester.ensureVisible(row);
      await tester.pumpAndSettle();
      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(find.text('coworker-detail-stub-cw-1'), findsOneWidget);
      // context.go replaces the stack — the dashboard/work-root are gone.
      expect(find.text('Statistics'), findsNothing);
    });

    testWidgets('shows "No coworkers yet." when there are none', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        repository: FakeDashboardRepository(coworkers: const []),
      );

      expect(find.text('No coworkers yet.'), findsOneWidget);
    });

    testWidgets('a failed fetch shows Retry, which re-invokes fetchCoworkers', (
      tester,
    ) async {
      final repository = FakeDashboardRepository(
        coworkersError: const NetworkException('offline'),
      );
      await pumpDashboard(tester, repository: repository);

      expect(repository.coworkersCallCount, 1);
      expect(find.text("Couldn't load coworker statistics"), findsOneWidget);

      final retry = find.text('Retry').last;
      await tester.ensureVisible(retry);
      await tester.pumpAndSettle();
      await tester.tap(retry);
      await tester.pumpAndSettle();

      expect(repository.coworkersCallCount, 2);
    });
  });

  group('workspace links', () {
    testWidgets('My Ads / Leads / Coworkers rows render real subtitles', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        repository: FakeDashboardRepository(
          coworkers: coworkers,
          ads: ads,
          leads: leads,
        ),
      );

      expect(find.text('My Ads'), findsOneWidget);
      expect(find.text('4 listings · 1 drafts'), findsOneWidget);

      expect(find.text('Leads'), findsOneWidget);
      expect(find.text('3 active · 1 need a call back'), findsOneWidget);

      expect(find.text('2 people'), findsOneWidget);
    });

    testWidgets('tapping My Ads pushes to my-listings', (tester) async {
      await pumpDashboard(tester, repository: FakeDashboardRepository());

      final myAds = find.byKey(const ValueKey('workspaceLink-myAds'));
      await tester.ensureVisible(myAds);
      await tester.pumpAndSettle();
      await tester.tap(myAds);
      await tester.pumpAndSettle();

      expect(find.text('my-listings-stub'), findsOneWidget);
    });

    testWidgets('tapping Leads pushes to the leads list', (tester) async {
      await pumpDashboard(tester, repository: FakeDashboardRepository());

      final leadsLink = find.byKey(const ValueKey('workspaceLink-leads'));
      await tester.ensureVisible(leadsLink);
      await tester.pumpAndSettle();
      await tester.tap(leadsLink);
      await tester.pumpAndSettle();

      expect(find.text('leads-stub'), findsOneWidget);
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

        await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(
            coworkers: coworkers,
            ads: ads,
            leads: leads,
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
