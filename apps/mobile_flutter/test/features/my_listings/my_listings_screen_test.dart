// Widget tests for `my-listings` (lib/features/my_listings/). Pumped inside
// a real GoRouter, not a bare MaterialApp: the header's back control
// branches on `context.canPop()`, a row tap pushes a Work-branch listing
// route, the edit icon `context.go`es to `edit-listing`, and "+" pushes the
// top-level `create-listing` modal — none of which exist without a router
// in the tree, same reasoning as
// `test/features/saved_listings/saved_listings_screen_test.dart`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/my_listings/my_listings.dart';
import 'package:lacasa_mobile/features/my_listings/state/my_listings_providers.dart';
import 'package:lacasa_mobile/features/my_listings/state/my_listings_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import 'support/fake_my_listings_repository.dart';
import 'support/my_listings_test_data.dart';

void main() {
  /// Pumps `my-listings` at `/work/my-listings`, with the Work root as the
  /// route below it so `canPop()` is true — the ordinary agent-session
  /// case. Stub routes stand in for `listing-detail`/`edit-listing`/
  /// `create-listing` so a push/go can be observed without dragging any of
  /// those whole screens in.
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required FakeMyListingsRepository repository,
    AuthUser? user,
    bool withBackStack = true,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [myListingsRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);
    if (user != null) {
      container.read(authSessionProvider.notifier).signIn(user);
    }

    final router = GoRouter(
      initialLocation: RoutePaths.work,
      routes: [
        GoRoute(
          path: RoutePaths.work,
          builder: (context, state) => const Scaffold(body: Text('work-root')),
          routes: [
            GoRoute(
              path: 'my-listings',
              builder: (context, state) => const MyListingsScreen(),
            ),
            GoRoute(
              path: 'listing/:id',
              builder: (context, state) => Scaffold(
                body: Text('listing-stub-${state.pathParameters['id']}'),
              ),
            ),
            GoRoute(
              path: 'edit-listing/:id',
              builder: (context, state) => Scaffold(
                body: Text('edit-listing-stub-${state.pathParameters['id']}'),
              ),
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.createListing,
          builder: (context, state) =>
              const Scaffold(body: Text('create-listing-stub')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (withBackStack) {
      router.push('${RoutePaths.work}/my-listings');
    } else {
      router.go('${RoutePaths.work}/my-listings');
    }
    await tester.pumpAndSettle();

    return container;
  }

  group('header', () {
    testWidgets('shows the §25 title', (tester) async {
      await pumpScreen(tester, repository: FakeMyListingsRepository());
      expect(find.text('My Ads'), findsOneWidget);
    });

    testWidgets('back pops to the route below', (tester) async {
      await pumpScreen(tester, repository: FakeMyListingsRepository());

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('work-root'), findsOneWidget);
    });

    testWidgets(
      'a coworker deep link with nothing to pop still leaves via back',
      (tester) async {
        await pumpScreen(
          tester,
          repository: FakeMyListingsRepository(),
          withBackStack: false,
        );

        await tester.tap(find.bySemanticsLabel('Back'));
        await tester.pumpAndSettle();

        expect(find.text('work-root'), findsOneWidget);
      },
    );
  });

  group('list', () {
    testWidgets('renders every §25 row field', (tester) async {
      final ad = myListingAd(
        id: 'ad-1001',
        city: 'Tashkent',
        district: 'Chilonzor',
        rooms: 3,
        area: 65,
        stage: '1',
        coworkerId: '',
      );

      await pumpScreen(
        tester,
        repository: FakeMyListingsRepository(ads: [ad]),
        user: myListingsAuthUser(id: 'agent-a', fullName: 'Javlon Rustamov'),
      );

      expect(find.text(Formatters.adIdBadge('ad-1001')), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.textContaining('Tashkent'), findsOneWidget);
      // Author with no coworkerId resolves to the signed-in agent.
      expect(find.textContaining('Javlon Rustamov'), findsOneWidget);
      expect(find.textContaining('3 rooms'), findsOneWidget);
      expect(find.textContaining('65 m²'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('myListingEdit-ad-1001')),
        findsOneWidget,
      );
    });

    testWidgets('empty state is §25 copy verbatim', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeMyListingsRepository(ads: const []),
      );

      expect(find.text('Ads not found.'), findsOneWidget);
    });

    testWidgets('a load failure shows Retry and re-fetches', (tester) async {
      final repo = FakeMyListingsRepository(
        adsError: const NetworkException('offline'),
      );

      await pumpScreen(tester, repository: repo);

      expect(find.text("Couldn't load your ads."), findsOneWidget);
      expect(repo.fetchMyAdsCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.fetchMyAdsCallCount, 2);
    });

    testWidgets('shows a shimmer skeleton while loading, then settles', (
      tester,
    ) async {
      // Built directly (no GoRouter, no `pumpScreen`'s `pumpAndSettle`):
      // `ShimmerBox` animates continuously while its state is on screen,
      // so settling before `gate` completes would hang — same reasoning
      // as `saved_listings_screen_test.dart`'s identically-shaped test.
      final gate = Completer<void>();
      final repo = FakeMyListingsRepository(adsHold: gate, ads: const []);

      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [myListingsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const MyListingsScreen(),
          ),
        ),
      );
      await tester.pump();

      // The title is outside the AsyncValue branch on purpose — a user
      // should know what screen they are on before its content lands.
      expect(find.text('My Ads'), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(ShimmerBox), findsNothing);
    });

    testWidgets('tapping a row outside the edit icon pushes listing-detail', (
      tester,
    ) async {
      final ad = myListingAd(id: 'ad-1001');

      await pumpScreen(tester, repository: FakeMyListingsRepository(ads: [ad]));

      await tester.tap(find.byKey(const ValueKey('myListingRow-ad-1001')));
      await tester.pumpAndSettle();

      expect(find.text('listing-stub-ad-1001'), findsOneWidget);
    });

    testWidgets('tapping the edit icon goes to edit-listing, not detail', (
      tester,
    ) async {
      final ad = myListingAd(id: 'ad-1001');

      await pumpScreen(tester, repository: FakeMyListingsRepository(ads: [ad]));

      await tester.tap(find.byKey(const ValueKey('myListingEdit-ad-1001')));
      await tester.pumpAndSettle();

      expect(find.text('edit-listing-stub-ad-1001'), findsOneWidget);
      expect(find.text('listing-stub-ad-1001'), findsNothing);
    });
  });

  group(
    'Author column (build contract — mirrors apps/console\'s own resolveAdAuthor)',
    () {
      testWidgets('a coworkerId resolves to that coworker\'s fullName', (
        tester,
      ) async {
        final ad = myListingAd(id: 'ad-1006', coworkerId: 'coworker-sardor');

        await pumpScreen(
          tester,
          repository: FakeMyListingsRepository(
            ads: [ad],
            coworkers: [
              myListingsCoworker(
                id: 'coworker-sardor',
                fullName: 'Sardor Abdullayev',
              ),
            ],
          ),
          user: myListingsAuthUser(id: 'agent-a', fullName: 'Javlon Rustamov'),
        );

        expect(find.textContaining('Sardor Abdullayev'), findsOneWidget);
        expect(find.textContaining('Javlon Rustamov'), findsNothing);
      });

      testWidgets('an unresolved coworkerId shows an em dash, never a guess', (
        tester,
      ) async {
        final ad = myListingAd(id: 'ad-1006', coworkerId: 'coworker-ghost');

        await pumpScreen(
          tester,
          repository: FakeMyListingsRepository(ads: [ad], coworkers: const []),
        );

        expect(find.textContaining('—'), findsOneWidget);
      });
    },
  );

  group('toolbar', () {
    testWidgets('"+" pushes create-listing', (tester) async {
      await pumpScreen(tester, repository: FakeMyListingsRepository());

      await tester.tap(find.byKey(const ValueKey('myListingsCreateButton')));
      await tester.pumpAndSettle();

      expect(find.text('create-listing-stub'), findsOneWidget);
    });

    testWidgets('Filter opens the CRM filter sheet with Sort + Status', (
      tester,
    ) async {
      await pumpScreen(tester, repository: FakeMyListingsRepository());

      await tester.tap(find.byKey(const ValueKey('myListingsFiltersButton')));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      // `FilterFieldLabel` uppercases every label it renders (see that
      // widget's own doc comment) — the sheet never shows literal "Sort"/
      // "Status" text, matching `filter_sheet_crm_test.dart`'s own
      // `find.text('SORT')`/`find.text('STATUS')` assertions for the same
      // widget.
      expect(find.text('SORT'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Sold'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
      // The CRM variant never claims a live buyer-feed count — see
      // `filter_sheet_footer.dart`'s `showLiveCount` doc comment.
      expect(find.text('Apply Filters'), findsOneWidget);
    });

    testWidgets('selecting Sort + Status and applying re-fetches by sort and '
        'narrows the visible list by status', (tester) async {
      final active = myListingAd(id: 'ad-1001', stage: '1');
      final sold = myListingAd(id: 'ad-1005', stage: '2');
      final repo = FakeMyListingsRepository(ads: [active, sold]);

      await pumpScreen(tester, repository: repo);

      expect(
        find.byKey(const ValueKey('myListingRow-ad-1001')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('myListingRow-ad-1005')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('myListingsFiltersButton')));
      await tester.pumpAndSettle();

      // The CRM filter sheet's own `SingleChildScrollView` builds every
      // field eagerly (it's a plain `Column`, not a lazy list), but Sort +
      // Status — appended last — sit below the default 800×600 test
      // surface until scrolled into view; `ensureVisible` finds the
      // ancestor `Scrollable` and brings each target on-screen before the
      // tap (same fix `filter_sheet_crm_test.dart` needs for its own
      // Sort/Status taps).
      final sortChip = find.byKey(
        ValueKey('filterCrmSort-${AdSort.highestPrice}'),
      );
      await tester.ensureVisible(sortChip);
      await tester.pumpAndSettle();
      await tester.tap(sortChip);

      final statusChip = find.byKey(
        ValueKey('filterCrmStatus-${AdStage.active}'),
      );
      await tester.ensureVisible(statusChip);
      await tester.pumpAndSettle();
      await tester.tap(statusChip);

      final applyButton = find.byKey(const ValueKey('filterSheet-apply'));
      await tester.ensureVisible(applyButton);
      await tester.pumpAndSettle();
      await tester.tap(applyButton);
      await tester.pumpAndSettle();

      // Status narrows client-side — the Sold row disappears even though
      // the fake repository still returns both.
      expect(
        find.byKey(const ValueKey('myListingRow-ad-1001')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('myListingRow-ad-1005')), findsNothing);
      // Sort is a real server param — the repository saw it.
      expect(repo.lastSort, AdSort.highestPrice);
      // Badge count: Status (1) *plus* the two fields `filter_sheet.dart`'s
      // `_seedDefaults` silently pre-selects on every fresh open —
      // Furniture ("With furniture") and Repair ("Not repaired"), per
      // SCREENS.md §3.5's own stated defaults. Those seeded chips are
      // genuinely selected in the sheet's UI, not a blank/"any" state, so
      // `activeMyListingsFilterCount` correctly counts them — exactly the
      // same convention `features/search`'s own `activeFilterCount` uses
      // for the buyer-facing sheet (same shared `FilterSheet`,
      // `_seedDefaults` doc comment). Sort itself stays excluded either
      // way. 1 (status) + 1 (furniture) + 1 (repairment) = 3.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('myListingsFiltersBadge')),
          matching: find.text('3'),
        ),
        findsOneWidget,
      );
    });
  });

  group(
    'infinite scroll (build contract §7.7 — client-side paging, no server pagination)',
    () {
      testWidgets('renders only the first page, then reveals more on scroll', (
        tester,
      ) async {
        final ads = [
          for (var i = 0; i < myListingsPageSize + 5; i++)
            myListingAd(id: 'ad-$i', createdAtSeconds: 1700000000 - i),
        ];

        await pumpScreen(
          tester,
          repository: FakeMyListingsRepository(ads: ads),
        );

        final listFinder = find.byKey(const ValueKey('myListingsListView'));

        // `ListView.separated` is a real virtualized list — unlike the
        // filter sheet's `SingleChildScrollView`, it only *builds* rows
        // that fall within its viewport plus a small cache extent, so the
        // first page's own last row (index `pageSize - 1`) isn't in the
        // tree yet at the default 800×600 surface without scrolling it
        // into view first. Dragging repeatedly (rather than one big drag)
        // mirrors how `dragUntilVisible` would do it, but stays a plain
        // loop since the assertions below need control between drags.
        for (var i = 0; i < 6; i++) {
          if (find
              .byKey(ValueKey('myListingRow-ad-${myListingsPageSize - 1}'))
              .evaluate()
              .isNotEmpty) {
            break;
          }
          await tester.drag(listFinder, const Offset(0, -400));
          await tester.pump();
        }

        expect(
          find.byKey(ValueKey('myListingRow-ad-${myListingsPageSize - 1}')),
          findsOneWidget,
        );
        // Not just off-screen — genuinely absent from the paging window's
        // `itemCount` until the scroll listener reveals the next page.
        expect(
          find.byKey(ValueKey('myListingRow-ad-$myListingsPageSize')),
          findsNothing,
        );

        // Drag the list up repeatedly until the scroll listener's
        // near-bottom threshold fires and reveals the rest. Plain `pump()`
        // rather than `pumpAndSettle()` throughout — once the paging
        // window's own "load more" sentinel (an indeterminate
        // `CircularProgressIndicator`) is on screen, its ticker never
        // settles on its own, so `pumpAndSettle` would hang.
        for (var i = 0; i < 6; i++) {
          await tester.drag(listFinder, const Offset(0, -400));
          await tester.pump();
        }
        await tester.pump();

        // The newly-revealed row also needs scrolling into view before the
        // finder sees it, for the same virtualization reason as above.
        for (var i = 0; i < 10; i++) {
          if (find
              .byKey(ValueKey('myListingRow-ad-$myListingsPageSize'))
              .evaluate()
              .isNotEmpty) {
            break;
          }
          await tester.drag(listFinder, const Offset(0, -400));
          await tester.pump();
        }

        expect(
          find.byKey(ValueKey('myListingRow-ad-$myListingsPageSize')),
          findsOneWidget,
        );
      });
    },
  );

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
          repository: FakeMyListingsRepository(
            ads: [
              myListingAd(id: 'ad-1001', coworkerId: 'coworker-sardor'),
              myListingAd(id: 'ad-1002', stage: '3', rooms: null, area: null),
            ],
            coworkers: [
              myListingsCoworker(
                id: 'coworker-sardor',
                fullName: 'Sardor Abdullayev',
              ),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('empty state has no overflow at ${size.label}', (
        tester,
      ) async {
        tester.view.physicalSize = size.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpScreen(
          tester,
          repository: FakeMyListingsRepository(ads: const []),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
