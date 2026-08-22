// Widget tests for `dashboard` (SCREENS.md §24, lib/features/work_dashboard/).
// Pumped inside a real GoRouter — the bell icon and every tile/row/coworker
// row navigate via context.push/context.go, none of which exists without a
// router in the tree, same reasoning as
// test/features/coworkers/coworkers_list_screen_test.dart.
//
// Every case drives the screen through `FakeDashboardRepository`, the only
// `DashboardRepository` a test may use: there is no fixture fallback behind
// the provider any more (the fixture repositories and the compile-time
// `useLiveWorkDashboardApi` switch that used to choose between them are both
// gone), so an un-overridden pump would fire real HTTP. What used to be two
// rendering paths is one — see `ads_statistics_panel.dart`'s doc comment.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/my_listings/state/my_listings_providers.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_repository_provider.dart';
import 'package:lacasa_mobile/features/work_dashboard/work_dashboard.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/dashboard_test_data.dart';
import '../support/fake_dashboard_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  // [realtorKind] decides whether the session can manage coworkers at all
  // (`canManageCoworkersProvider`). The default — a role-only session with
  // no `AuthUser` behind it — is the "nothing has said this account is
  // solo" case, which renders every coworker surface; pass
  // `RealtorKind.solo` to exercise the hidden branch.
  Future<ProviderContainer> pumpDashboard(
    WidgetTester tester, {
    required FakeDashboardRepository repository,
    RealtorKind? realtorKind,
    Locale? locale,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [dashboardRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    if (realtorKind == null) {
      container.read(authSessionProvider.notifier).setRole(UserRole.agent);
    } else {
      container
          .read(authSessionProvider.notifier)
          .signIn(dashboardAgent(realtorKind: realtorKind));
    }

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
              routes: [
                // Nested under `dashboard`, mirroring the real agent
                // shell's own branch 0 — the bell that opens it lives in
                // this branch's header. See `app_router.dart`.
                GoRoute(
                  path: 'notifications',
                  builder: (context, state) =>
                      const Scaffold(body: Text('notifications-stub')),
                ),
              ],
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
                // Declared before `:id` so `/work/coworkers/create` matches
                // the literal, exactly as `app_router.dart` orders it.
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
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
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

  // The chart (`ads_statistics_panel.dart`'s `_SeriesAreaChart`) renders
  // day-axis labels "1"/"3"/"5"/"7"/"9"/"11"/"12" for the fake's default
  // 12-bucket series, plus its own y-axis ticks, alongside the stat tiles —
  // so a bare `find.text('5')` is ambiguous whenever a tile value happens to
  // land on one of those digits. Every stat-tile value assertion below is
  // scoped to its own tile's key for that reason.
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
      // `.tile__l` is uppercased at render (`_StatTile`), so the ARB's
      // sentence-case string never appears verbatim on screen.
      expect(find.text('ADS CREATED'), findsOneWidget);
      expect(tileValue('dashboardTile-adsCreated', '10'), findsOneWidget);
      expect(find.text('ADS SOLD'), findsOneWidget);
      expect(tileValue('dashboardTile-adsSold', '5'), findsOneWidget);
      // Two of §24's tiles' subtitle both read "this month" by default.
      expect(find.text('this month'), findsNWidgets(2));

      expect(find.text('ACTIVE LEADS'), findsOneWidget);
      expect(tileValue('dashboardTile-activeLeads', '3'), findsOneWidget);
      expect(find.text('1 needs a call back'), findsOneWidget);

      expect(tileLabel('dashboardTile-coworkers', 'COWORKERS'), findsOneWidget);
      expect(tileValue('dashboardTile-coworkers', '2'), findsOneWidget);
      expect(find.text('tap to manage'), findsOneWidget);
    });

    testWidgets(
      '"Active leads" excludes closed and archived leads — it is not the '
      'size of the GET /leads table',
      (tester) async {
        // The defect this pins: the tile (and the Workspace "Leads" row
        // below it) rendered `leads.length`, so an agent whose pipeline had
        // been running for a while read every rejection they had ever taken
        // back as a live lead. Five leads here, only two of them actually
        // open — one `new`, one `need_to_call_back`.
        await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(
            leads: [
              testLead(id: 'lead-open-1'),
              testLead(
                id: 'lead-open-2',
                status: 'need_to_call_back',
                callbackIso: '2000-01-01T00:00:00.000Z', // overdue -> due today
              ),
              testLead(id: 'lead-rejected', status: 'rejected'),
              testLead(id: 'lead-accepted', status: 'accepted'),
              testLead(id: 'lead-archived', active: false),
            ],
          ),
        );

        expect(tileValue('dashboardTile-activeLeads', '2'), findsOneWidget);
        expect(
          tileValue('dashboardTile-activeLeads', '5'),
          findsNothing,
          reason: 'the raw table size must never reach this tile again',
        );
        // The Workspace row reads the same shared `countActiveLeads`, so the
        // two surfaces agree on the same screen — the whole point of the
        // helper being one function.
        expect(find.text('2 active · 1 need a call back'), findsOneWidget);
        expect(find.textContaining('5 active'), findsNothing);
      },
    );

    testWidgets(
      'the Active-leads tile and its own subtitle count the same population: '
      'a closed lead with a stale callback date shows 0 over 0, never 0 over 1',
      (tester) async {
        // The self-contradiction this pins. While the tile rendered
        // `leads.length` its subtitle could never exceed it, so folding the
        // raw table for the callback count was harmless; the moment the
        // value became a filtered count it stopped being. `kanban-move-sheet`
        // does not blank `callbackDate` when a lead is rejected, so a closed
        // lead still carrying one is the ordinary end state — and it used to
        // render this tile as "0" directly above "1 needs a call back".
        await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(
            leads: [
              testLead(
                id: 'lead-rejected',
                status: 'rejected',
                callbackIso: '2000-01-01T00:00:00.000Z',
              ),
              testLead(
                id: 'lead-archived',
                active: false,
                callbackIso: '2000-01-01T00:00:00.000Z',
              ),
            ],
          ),
        );

        expect(tileValue('dashboardTile-activeLeads', '0'), findsOneWidget);
        expect(find.text('0 need a call back'), findsOneWidget);
        expect(
          find.text('1 needs a call back'),
          findsNothing,
          reason: 'the subtitle must never outnumber the value above it',
        );
        // The Workspace row renders both figures inside one ARB sentence, so
        // it contradicts itself even more visibly than the tile does.
        expect(find.text('0 active · 0 need a call back'), findsOneWidget);
      },
    );

    testWidgets(
      'gating the callback count on the active predicate narrows it, it does '
      'not silence it',
      (tester) async {
        await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(
            leads: [
              testLead(
                id: 'lead-open',
                status: 'need_to_call_back',
                callbackIso: '2000-01-01T00:00:00.000Z',
              ),
              testLead(
                id: 'lead-rejected',
                status: 'rejected',
                callbackIso: '2000-01-01T00:00:00.000Z',
              ),
            ],
          ),
        );

        expect(tileValue('dashboardTile-activeLeads', '1'), findsOneWidget);
        expect(find.text('1 needs a call back'), findsOneWidget);
        expect(find.text('1 active · 1 need a call back'), findsOneWidget);
      },
    );

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
      'tapping "Ads sold" opens my-listings without leaving a session-long '
      'stage filter behind',
      (tester) async {
        // The defect this pins: the tile used to preset
        // `myListingsStatusProvider` to `AdStage.sold` on its way to
        // my-listings. That provider is a plain global `Notifier` — not
        // `autoDispose`, and nothing anywhere clears it — so one tap here
        // narrowed the user's My Ads screen to Sold for the rest of the
        // session, including every later arrival by the tab bar or a deep
        // link, with most of their listings simply missing and the CRM
        // filter sheet the only surface that revealed why.
        final container = await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(),
        );
        expect(container.read(myListingsStatusProvider), isNull);

        await tester.tap(find.byKey(const ValueKey('dashboardTile-adsSold')));
        await tester.pumpAndSettle();

        expect(find.text('my-listings-stub'), findsOneWidget);
        expect(
          container.read(myListingsStatusProvider),
          isNull,
          reason:
              'the dashboard must not write a filter it has no way to clear',
        );
      },
    );

    testWidgets(
      'neither ad tile stomps a stage filter the user chose themselves',
      (tester) async {
        final container = await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(),
        );
        // The user narrowed My Ads to Sold in the CRM filter sheet on a
        // previous visit. That is *their* selection, and the dashboard is
        // not entitled to clear it any more than it is to set one — the
        // screen must open exactly as they left it.
        container
            .read(myListingsStatusProvider.notifier)
            .setStatus(AdStage.sold);
        await tester.pumpAndSettle();

        await tester.tap(
          find.byKey(const ValueKey('dashboardTile-adsCreated')),
        );
        await tester.pumpAndSettle();

        expect(find.text('my-listings-stub'), findsOneWidget);
        expect(container.read(myListingsStatusProvider), AdStage.sold);
      },
    );

    testWidgets('a tile speaks its own number, not just its caption', (
      tester,
    ) async {
      // The defect this pins: the tile's `Semantics.label` was
      // "{label}, {subtitle}" — "Ads created, this month" — with the one
      // figure the tile exists to show missing from between them.
      final handle = tester.ensureSemantics();

      await pumpDashboard(
        tester,
        repository: FakeDashboardRepository(
          adsStatisticsByFilter: {
            StatisticsFilter.thisMonth: const AdsStatistics(
              adsNewCount: 10,
              adsSoldCount: 5,
            ),
          },
        ),
      );

      expect(
        find.bySemanticsLabel('Ads created, 10, this month'),
        findsOneWidget,
      );
      expect(find.bySemanticsLabel('Ads sold, 5, this month'), findsOneWidget);
      expect(
        find.bySemanticsLabel('Ads created, this month'),
        findsNothing,
        reason: 'a tile that omits its value announces only its caption',
      );

      // Folding the value into the label means `excludeSemantics`, which
      // drops the inner GestureDetector's own tap action — the same
      // regression `category_chip_row.dart`'s chips shipped once. The
      // action has to come off the annotation instead.
      expect(
        tester.getSemantics(
          find.byKey(const ValueKey('dashboardTile-adsSold')),
        ),
        isSemantics(
          label: 'Ads sold, 5, this month',
          isButton: true,
          hasTapAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('tapping "Active leads" pushes to the leads list', (
      tester,
    ) async {
      await pumpDashboard(tester, repository: FakeDashboardRepository());

      await tester.tap(find.byKey(const ValueKey('dashboardTile-activeLeads')));
      await tester.pumpAndSettle();

      expect(find.text('leads-stub'), findsOneWidget);
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
        expect(
          tileLabel('dashboardTile-coworkers', 'COWORKERS'),
          findsOneWidget,
        );
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
        find.byKey(const ValueKey('dashboardRange-StatisticsFilter.thisMonth')),
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
          'dashboardRange-StatisticsFilter.all',
          'dashboardRange-StatisticsFilter.thisMonth',
          'dashboardRange-StatisticsFilter.thisWeek',
          'dashboardRange-StatisticsFilter.today',
        ].map(leftEdge).toList();

        expect(
          order,
          List.of(order)..sort(),
          reason:
              'chips must appear in ascending x-position in this exact order',
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
          find.byKey(
            const ValueKey('dashboardRange-StatisticsFilter.thisWeek'),
          ),
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

  group('ads statistics panel', () {
    // Three buckets so the day axis is short and unambiguous, with peaks
    // the y-ticks can be asserted against: created 1/4/2 (7 total), sold
    // 0/2/1 (3 total). `maxValue` is 4 and its half is 2.
    final series = AdsSeries(
      granularity: SeriesGranularity.day,
      from: DateTime.utc(2024, 3, 1),
      to: DateTime.utc(2024, 3, 3),
      buckets: [
        AdsSeriesBucket(
          bucketStart: DateTime.utc(2024, 3, 1),
          adCreatedCount: 1,
          adSoldCount: 0,
        ),
        AdsSeriesBucket(
          bucketStart: DateTime.utc(2024, 3, 2),
          adCreatedCount: 4,
          adSoldCount: 2,
        ),
        AdsSeriesBucket(
          bucketStart: DateTime.utc(2024, 3, 3),
          adCreatedCount: 2,
          adSoldCount: 1,
        ),
      ],
    );

    testWidgets('renders the 12-point chart with its legend', (tester) async {
      await pumpDashboard(tester, repository: FakeDashboardRepository());

      expect(find.text('Ads statistics'), findsOneWidget);
      expect(find.text('Days 1–12'), findsOneWidget);
      expect(find.text('Created'), findsOneWidget);
      expect(find.text('Sold'), findsOneWidget);
    });

    testWidgets(
      'the chart states its own scale: the peak and its midpoint are printed '
      'as y-axis ticks',
      (tester) async {
        // The defect this pins: both series were normalized against a
        // `maxValue` computed inside `paint` and never surfaced, so a peak
        // of 4 and a peak of 400 drew the identical shape.
        await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(
            adsSeriesByFilter: {StatisticsFilter.thisMonth: series},
          ),
        );

        expect(
          find.byKey(const ValueKey('adsStatisticsYTick-4')),
          findsOneWidget,
        );
        expect(
          find.byKey(const ValueKey('adsStatisticsYTick-2')),
          findsOneWidget,
        );
      },
    );

    testWidgets('an all-zero range states a scale of 0, not a phantom 1', (
      tester,
    ) async {
      // The defect this pins: `_maxValueOf` floored the peak at 1 so the
      // `value / maxValue` division could never blow up. Invisible while
      // that number only scaled a path — and a printed lie the moment it
      // became a y-axis tick. A quiet month (and the fake's own zero-filled
      // default, which is the honest shape of a real empty response) drew a
      // top tick reading "1" above a flat baseline: a scale nothing in the
      // series reaches.
      await pumpDashboard(tester, repository: FakeDashboardRepository());

      expect(
        find.byKey(const ValueKey('adsStatisticsYTick-0')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('adsStatisticsYTick-1')),
        findsNothing,
        reason: 'nothing in an all-zero series reaches 1',
      );
    });

    // The defect these pin: the error branch reused the chart's fixed 120dp
    // box, and `RailRetryCard` outgrew it when the shared Retry gained a
    // 48dp tap target — 16+16 of padding, a 22dp icon, a 6dp gap, the
    // message and the 48dp target already come to ~113dp for a single-line
    // message, and the ru/uz messages wrap to two lines at this width.
    for (final locale in const [Locale('en'), Locale('ru'), Locale('uz')]) {
      testWidgets(
        'a failed series fetch fits its own retry card in '
        '${locale.languageCode}',
        (tester) async {
          final overflows = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (details) {
            final text = details.exceptionAsString();
            if (text.contains('overflowed')) {
              overflows.add(text.split('\n').first);
            } else {
              previous?.call(details);
            }
          };
          tester.view.physicalSize = const Size(360, 800);
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            FlutterError.onError = previous;
          });

          await pumpDashboard(
            tester,
            repository: FakeDashboardRepository(
              adsSeriesError: const NetworkException('offline'),
            ),
            locale: locale,
          );

          expect(
            find.byKey(const ValueKey('adsStatisticsChart')),
            findsNothing,
          );
          expect(tester.takeException(), isNull);
          expect(
            overflows,
            isEmpty,
            reason:
                'the retry card overflowed the chart box in '
                '${locale.languageCode}:\n${overflows.join('\n')}',
          );
        },
      );
    }

    testWidgets('the chart summarises itself for a screen reader', (
      tester,
    ) async {
      // Disposed inline at the end of the body, not via addTearDown:
      // `WidgetTester._endOfTestVerifications` asserts every SemanticsHandle
      // is already released, and it runs inside the test body — before any
      // tearDown the test package registered.
      final handle = tester.ensureSemantics();

      await pumpDashboard(
        tester,
        repository: FakeDashboardRepository(
          adsSeriesByFilter: {StatisticsFilter.thisMonth: series},
        ),
      );

      // The canvas used to emit nothing at all — the one unlabelled thing
      // on a screen where every other figure is spoken.
      expect(
        find.bySemanticsLabel('Ads statistics, Days 1–3: 7 created, 3 sold'),
        findsOneWidget,
      );

      handle.dispose();
    });

    testWidgets(
      '"All" says the chart is showing this month, since the series endpoint '
      'has no all-time mode',
      (tester) async {
        // The stat tiles keep a genuine all-time total (a different
        // endpoint, which does have one), so the chip stays — what was
        // missing was the caption admitting the two answer different
        // questions. See `live_dashboard_repository.dart`'s remap.
        await pumpDashboard(tester, repository: FakeDashboardRepository());

        expect(find.text('Days 1–12'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('dashboardRange-StatisticsFilter.all')),
        );
        await tester.pumpAndSettle();

        expect(find.text('Days 1–12 · chart shows this month'), findsOneWidget);
      },
    );
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

    testWidgets(
      'the Leads column answers the time-range chip, like Ads and Sales',
      (tester) async {
        // The defect this pins: `leadCount` folded the whole lead list while
        // the two columns either side of it filtered by the selected range,
        // so "Today" produced rows like `Ads 0 · Leads 14 · Sales 0` — one
        // selector, three numbers, two of them obeying it.
        //
        // Old leads are dated 2020 rather than "yesterday" so the expected
        // figures hold whichever day of the month the suite runs on; the
        // recent ones use `testLead`'s plain local `DateTime.now()` default
        // (see that builder's doc comment for why it is an ordinary "now"
        // and not a zone-hedged constant).
        await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(
            coworkers: coworkers,
            leads: [
              testLead(id: 'lead-new-1', coworkerId: 'cw-1'),
              testLead(id: 'lead-new-2', coworkerId: 'cw-1'),
              testLead(
                id: 'lead-old-1',
                coworkerId: 'cw-1',
                createdAt: DateTime(2020, 5, 4),
              ),
              testLead(
                id: 'lead-old-2',
                coworkerId: 'cw-1',
                createdAt: DateTime(2020, 5, 5),
              ),
              testLead(
                id: 'lead-old-3',
                coworkerId: 'cw-1',
                createdAt: DateTime(2020, 5, 6),
              ),
            ],
          ),
        );

        expect(
          rowValue('cw-1', '2'),
          findsOneWidget,
          reason: 'the default "This month" range excludes the 2020 leads',
        );

        await tester.tap(
          find.byKey(const ValueKey('dashboardRange-StatisticsFilter.all')),
        );
        await tester.pumpAndSettle();

        expect(rowValue('cw-1', '5'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('dashboardRange-StatisticsFilter.today')),
        );
        await tester.pumpAndSettle();

        expect(rowValue('cw-1', '2'), findsOneWidget);
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

    testWidgets('every bar carries its own number, not just the Ads one', (
      tester,
    ) async {
      // The defect this pins: `_BarRow` printed `row.adsCount` alone at
      // the right of a three-bar stack, so the Leads and Sales bars were
      // unreadable lengths — a 4 and a 40 look the same when nothing
      // states the scale.
      await pumpDashboard(
        tester,
        repository: FakeDashboardRepository(
          coworkers: coworkers,
          coworkerActivity: coworkerActivity,
          leads: leads,
        ),
      );

      // Sardor: 3 ads, 2 leads, 1 sale — three distinct figures, so all
      // three must appear inside his own bar row.
      Finder barValue(String coworkerId, String value) => find.descendant(
        of: find.byKey(ValueKey('coworkerBarRow-$coworkerId')),
        matching: find.text(value),
      );
      expect(barValue('cw-1', '3'), findsOneWidget);
      expect(barValue('cw-1', '2'), findsOneWidget);
      expect(barValue('cw-1', '1'), findsOneWidget);
    });

    testWidgets(
      'the table headings render uppercased from sentence-case ARB values',
      (tester) async {
        // The ARBs hold "Ads"/"Leads"/"Sales"; `_HeaderCell` uppercases at
        // the call site, the rule the stat tiles already followed.
        await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(coworkers: coworkers),
        );

        expect(find.text('ADS'), findsOneWidget);
        expect(find.text('LEADS'), findsOneWidget);
        expect(find.text('SALES'), findsOneWidget);
        // The stat tile's own label is "COWORKERS" too, hence two.
        expect(find.text('COWORKERS'), findsNWidgets(2));
      },
    );

    testWidgets(
      'an agency agent with no coworkers gets an "Add coworker" action, not a '
      'dead panel',
      (tester) async {
        await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(coworkers: const []),
          realtorKind: RealtorKind.agency,
        );

        expect(find.text('No coworkers yet.'), findsOneWidget);

        final action = find.text('Add coworker');
        await tester.ensureVisible(action);
        await tester.pumpAndSettle();
        await tester.tap(action);
        await tester.pumpAndSettle();

        expect(find.text('add-coworker-stub'), findsOneWidget);
        // `go`, not `push`: `add-coworker` is declared under
        // `RoutePaths.workCoworkers`, i.e. inside the Coworkers branch,
        // while this panel renders in the Dashboard branch — build contract
        // §2.2's cross-branch rule. Both assertions look *under* the top
        // page (`skipOffstage: false`), which is the only way to tell the
        // two verbs apart: a push would have left the dashboard sitting
        // there, a go rebuilds the destination's own branch stack.
        expect(
          find.text('coworkers-list-stub', skipOffstage: false),
          findsOneWidget,
          reason: 'go builds [coworkers, add-coworker]: Back shows the roster',
        );
        expect(
          find.text('Statistics', skipOffstage: false),
          findsNothing,
          reason: 'a push would have left the dashboard underneath instead',
        );
      },
    );

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

  group('a solo realtor gets no coworker surfaces at all', () {
    // The defect this pins: solo is the DEFAULT choice on `register`, and
    // `POST /coworkers` 403s for one — so the most common new realtor
    // landed on a dashboard a third of which was a permanently empty "No
    // coworkers yet." panel, over a tile inviting them to "tap to manage" a
    // roster they are forbidden to add to. `coworkers_list_screen.dart`
    // already hid its own add button on this exact predicate.
    testWidgets('the section, the tile and the workspace row all disappear', (
      tester,
    ) async {
      await pumpDashboard(
        tester,
        repository: FakeDashboardRepository(coworkers: coworkers),
        realtorKind: RealtorKind.solo,
      );

      expect(find.text('Coworker statistics'), findsNothing);
      expect(
        find.byKey(const ValueKey('dashboardTile-coworkers')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('workspaceLink-coworkers')),
        findsNothing,
      );
      expect(find.text('No coworkers yet.'), findsNothing);
      expect(find.text('tap to manage'), findsNothing);
    });

    testWidgets('the rest of the screen is untouched', (tester) async {
      await pumpDashboard(
        tester,
        repository: FakeDashboardRepository(
          adsStatisticsByFilter: {
            StatisticsFilter.thisMonth: const AdsStatistics(
              adsNewCount: 10,
              adsSoldCount: 5,
            ),
          },
          ads: ads,
          leads: leads,
        ),
        realtorKind: RealtorKind.solo,
      );

      expect(tileValue('dashboardTile-adsCreated', '10'), findsOneWidget);
      expect(tileValue('dashboardTile-adsSold', '5'), findsOneWidget);
      expect(tileValue('dashboardTile-activeLeads', '3'), findsOneWidget);
      expect(find.text('Ads statistics'), findsOneWidget);
      expect(find.byKey(const ValueKey('workspaceLink-myAds')), findsOneWidget);
      expect(find.byKey(const ValueKey('workspaceLink-leads')), findsOneWidget);
    });

    testWidgets('the roster is not even fetched', (tester) async {
      final repository = FakeDashboardRepository(coworkers: coworkers);
      await pumpDashboard(
        tester,
        repository: repository,
        realtorKind: RealtorKind.solo,
      );

      expect(
        repository.coworkersCallCount,
        0,
        reason: 'nothing renders it, so GET /coworkers is a wasted request',
      );
    });

    testWidgets('an agency realtor still gets all three', (tester) async {
      await pumpDashboard(
        tester,
        repository: FakeDashboardRepository(coworkers: coworkers),
        realtorKind: RealtorKind.agency,
      );

      expect(find.text('Coworker statistics'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('dashboardTile-coworkers')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('workspaceLink-coworkers')),
        findsOneWidget,
      );
    });
  });

  group('layout holds at real phone widths', () {
    // Both axes of the sweep matter and for different reasons: the narrow
    // widths catch a row that cannot fit its children, and ru/uz catch the
    // strings that make it not fit — Russian "ОБЪЯВЛЕНИЯ" needs ~65dp at
    // the 10px label role where the column is 56, and the uppercased tile
    // labels run past half a 360dp screen. `test/phone_width_overflow_test
    // .dart`, the app-wide sweep, pumps a signed-out `App()` in the default
    // locale and so reaches neither this screen nor these strings.
    for (final size in const [
      (label: 'small android', size: Size(360, 800)),
      (label: 'iphone 14', size: Size(390, 844)),
      (label: 'pro max', size: Size(430, 932)),
    ]) {
      for (final locale in const [Locale('en'), Locale('ru'), Locale('uz')]) {
        testWidgets('no overflow at ${size.label} in ${locale.languageCode}', (
          tester,
        ) async {
          final overflows = <String>[];
          final previous = FlutterError.onError;
          FlutterError.onError = (details) {
            final text = details.exceptionAsString();
            if (text.contains('overflowed')) {
              overflows.add(text.split('\n').first);
            } else {
              previous?.call(details);
            }
          };

          tester.view.physicalSize = size.size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(() {
            tester.view.resetPhysicalSize();
            tester.view.resetDevicePixelRatio();
            FlutterError.onError = previous;
          });

          await pumpDashboard(
            tester,
            repository: FakeDashboardRepository(
              coworkers: coworkers,
              coworkerActivity: coworkerActivity,
              ads: ads,
              leads: leads,
            ),
            locale: locale,
          );

          expect(tester.takeException(), isNull);
          expect(
            overflows,
            isEmpty,
            reason:
                'overflow at ${size.label} in ${locale.languageCode}:\n'
                '${overflows.join('\n')}',
          );
        });
      }
    }

    testWidgets(
      'two stat tiles that want different heights still render the same '
      'height',
      (tester) async {
        // `_StatTile`'s row used to centre its children, so a tile whose
        // content was taller than its neighbour's rendered as a bigger card
        // floating about a shared centre line. The fix is the
        // `IntrinsicHeight` + `CrossAxisAlignment.stretch` pair in
        // `dashboard_stat_tiles.dart`.
        //
        // **Row 1 cannot exercise it.** Both its tiles read the one
        // `adsStatisticsProvider`, carry the identical `_rangeSubtitle`, and
        // their labels are pinned to `maxLines: 1` — so their content is the
        // same height by construction and they would line up with or without
        // the fix. Row 2 is the real case: `dashboardLeadsProvider` and
        // `dashboardCoworkersProvider` fail independently, so failing the
        // leads fetch alone puts an 11dp single-line `Retry` in one tile
        // against the other's 10.5dp subtitle. The precondition below
        // asserts that difference rather than assuming it, so this case can
        // never quietly go vacuous the way row 1 did.
        tester.view.physicalSize = const Size(360, 800);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpDashboard(
          tester,
          repository: FakeDashboardRepository(
            coworkers: coworkers,
            leadsError: const NetworkException('offline'),
          ),
        );

        Rect tileRect(String key) => tester.getRect(find.byKey(ValueKey(key)));
        double subtitleHeight(String tileKey, String text) => tester
            .getSize(
              find.descendant(
                of: find.byKey(ValueKey(tileKey)),
                matching: find.text(text),
              ),
            )
            .height;

        expect(
          subtitleHeight('dashboardTile-activeLeads', 'Retry'),
          isNot(subtitleHeight('dashboardTile-coworkers', 'tap to manage')),
          reason:
              'precondition: this only pins the fix while the two tiles '
              'genuinely want different heights',
        );
        expect(
          tileRect('dashboardTile-activeLeads').height,
          tileRect('dashboardTile-coworkers').height,
        );
        // Row 1 is the weaker, structural check: whatever else changes, the
        // pair must not drift apart.
        expect(
          tileRect('dashboardTile-adsCreated').height,
          tileRect('dashboardTile-adsSold').height,
        );
      },
    );
  });
}
