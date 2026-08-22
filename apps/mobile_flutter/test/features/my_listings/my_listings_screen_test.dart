// Widget tests for `my-listings` (lib/features/my_listings/). Pumped inside
// a real GoRouter, not a bare MaterialApp: the header's back control
// branches on `context.canPop()`, a row tap pushes a Work-branch listing
// route, the edit icon pushes `edit-listing` (a child route of this screen,
// so this screen stays underneath it), and "+" pushes the top-level
// `create-listing` modal — none of which exist without a router
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
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
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
    Locale locale = const Locale('en'),
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
              // Both stubs are nested here, not on `/work`, because that is
              // where `app_router.dart` declares the real routes: this
              // screen is the page a Back out of either has to reveal, so
              // it has to be the page underneath them here too.
              routes: [
                GoRoute(
                  path: 'listing/:id',
                  builder: (context, state) => Scaffold(
                    body: Text('listing-stub-${state.pathParameters['id']}'),
                  ),
                ),
                GoRoute(
                  path: 'edit-listing/:id',
                  builder: (context, state) => Scaffold(
                    body: Text(
                      'edit-listing-stub-${state.pathParameters['id']}',
                    ),
                  ),
                ),
                // Same nesting as `RoutePaths.workPublishStatus`
                // (`/work/my-listings/publish-status/:id`) — the row's
                // channel badges push here, so this screen has to be the
                // page underneath it exactly as it is for `edit-listing`.
                GoRoute(
                  path: 'publish-status/:id',
                  builder: (context, state) => Scaffold(
                    body: Text(
                      'publish-status-stub-${state.pathParameters['id']}',
                    ),
                  ),
                ),
              ],
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
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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
      // A server-side failure, not a connectivity one — the per-screen
      // string is the better copy exactly here, where "which screen failed"
      // is the most specific thing the app knows (see
      // `shared/widgets/read_error.dart`).
      final repo = FakeMyListingsRepository(adsError: StateError('boom'));

      await pumpScreen(tester, repository: repo);

      expect(find.text("Couldn't load your ads."), findsOneWidget);
      expect(repo.fetchMyAdsCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.fetchMyAdsCallCount, 2);
    });

    testWidgets(
      'a connectivity failure names itself instead of blaming this screen '
      '(UX audit §9.5)',
      (tester) async {
        // Before this, every read path in the app rendered its own fixed
        // "Couldn't load X." for a request that never reached the server —
        // a dozen anonymous cards for one condition, each offering a Retry
        // that could not possibly succeed. The screen-specific sentence is
        // now the fallback, not the answer.
        final repo = FakeMyListingsRepository(
          adsError: const NetworkException('offline'),
        );

        await pumpScreen(tester, repository: repo);

        expect(
          find.text('No connection. Check your network and try again.'),
          findsOneWidget,
        );
        expect(find.text("Couldn't load your ads."), findsNothing);
        // The glyph carries the same fact — a generic error triangle over
        // "No connection" wastes the half of the state a user reads first.
        expect(find.byIcon(Icons.wifi_off_rounded), findsOneWidget);
      },
    );

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
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
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

    testWidgets('tapping the edit icon opens edit-listing, not detail', (
      tester,
    ) async {
      final ad = myListingAd(id: 'ad-1001');

      await pumpScreen(tester, repository: FakeMyListingsRepository(ads: [ad]));

      await tester.tap(find.byKey(const ValueKey('myListingEdit-ad-1001')));
      await tester.pumpAndSettle();

      expect(find.text('edit-listing-stub-ad-1001'), findsOneWidget);
      expect(find.text('listing-stub-ad-1001'), findsNothing);
    });

    testWidgets(
      'the edit icon pushes, leaving this very screen on the stack below',
      (tester) async {
        final ad = myListingAd(id: 'ad-1001');

        await pumpScreen(
          tester,
          repository: FakeMyListingsRepository(ads: [ad]),
        );
        // `context.go` used to be used here (build contract §2.2 read
        // literally), which replaced the branch stack: this screen — its
        // applied filters, its paged scroll position — was disposed on
        // every edit-icon tap, and `edit-listing` had nothing to pop back
        // to. Comparing the `State` object across the navigation is what
        // catches a regression to that; the route being reachable is not
        // enough.
        final before = tester.state<State>(find.byType(MyListingsScreen));

        await tester.tap(find.byKey(const ValueKey('myListingEdit-ad-1001')));
        await tester.pumpAndSettle();
        expect(find.text('edit-listing-stub-ad-1001'), findsOneWidget);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('edit-listing-stub-ad-1001'), findsNothing);
        // Back landed on My Ads — the same instance, not a rebuild — rather
        // than falling through to the route below it.
        expect(find.byType(MyListingsScreen), findsOneWidget);
        expect(tester.state<State>(find.byType(MyListingsScreen)), same(before));
        expect(find.text('work-root'), findsNothing);
      },
    );
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
      // Badge count: Status, and Status only. A fresh open of the shared
      // `FilterSheet` now pre-selects nothing — it used to seed Furniture
      // ("With furniture") and Repair ("Not repaired") into any null
      // incoming value, so this very flow (tap Sort, tap Status, Apply)
      // walked out with two constraints the agent never chose and a badge
      // reading 3. `activeMyListingsFilterCount` counts whatever the user
      // genuinely selected, which here is the one Status chip; Sort is
      // excluded from the count by design, same as on the buyer-facing
      // sheet. 1 (status) = 1.
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('myListingsFiltersBadge')),
          matching: find.text('1'),
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

        // The paging window, read straight off the list rather than
        // inferred from which rows happen to be built: `ListView.separated`
        // reports its item count (excluding separators) as
        // `semanticChildCount`, and the window is one page of ads plus the
        // load-more sentinel. Asserted *before* any drag, because the rows
        // are shorter than they used to be, so the very scroll that brings
        // the first page's last row into view can also cross the
        // near-bottom threshold and legitimately reveal page two — a row
        // finder can no longer tell "not paged in yet" from "just
        // off-screen" here.
        expect(
          tester.widget<ListView>(listFinder).semanticChildCount,
          myListingsPageSize + 1,
        );

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

        // Drag the list up repeatedly until the scroll listener's
        // near-bottom threshold fires and reveals the rest. Plain `pump()`
        // rather than `pumpAndSettle()` throughout — once the paging
        // window's own "load more" sentinel (an indeterminate
        // `CircularProgressIndicator`) is on screen, its ticker never
        // settles on its own, so `pumpAndSettle` would hang.
        for (var i = 0; i < 12; i++) {
          if (tester.widget<ListView>(listFinder).semanticChildCount ==
              myListingsPageSize + 5) {
            break;
          }
          await tester.drag(listFinder, const Offset(0, -400));
          await tester.pump();
        }

        // The window grew to hold every ad, and the sentinel is gone
        // because there is no next page left.
        expect(
          tester.widget<ListView>(listFinder).semanticChildCount,
          myListingsPageSize + 5,
        );

        // The revealed rows also have to be scrolled into view before a
        // finder sees them, for the same virtualization reason as above.
        // The assertion targets the *last* ad rather than the first of
        // page two: by the time the list has been dragged to its end, row
        // `pageSize` has scrolled back off the top and been recycled, so
        // it would be absent for a reason that has nothing to do with
        // paging.
        const lastAdKey = ValueKey(
          'myListingRow-ad-${myListingsPageSize + 4}',
        );
        for (var i = 0; i < 12; i++) {
          if (find.byKey(lastAdKey).evaluate().isNotEmpty) break;
          await tester.drag(listFinder, const Offset(0, -400));
          await tester.pump();
        }

        expect(find.byKey(lastAdKey), findsOneWidget);
      });
    },
  );

  group('stage-count strip (UX audit §1 "Relocate" / §5.6)', () {
    testWidgets(
      'renders the endpoint\'s counts, not a fold of the loaded page',
      (tester) async {
        // The distinction is the whole point: `GET /my/ads` is keyset-paged
        // here, so folding the one page in memory would print "1 active"
        // for an agent who has twelve — a number that is wrong by
        // construction and grows as they scroll.
        final repo = FakeMyListingsRepository(
          ads: [myListingAd(id: 'ad-1001')],
          stageCounts: const AdStageCounts(active: 12, sold: 3, draft: 2),
        );

        await pumpScreen(tester, repository: repo);

        expect(
          find.byKey(const ValueKey('myListingsStageStrip')),
          findsOneWidget,
        );
        expect(find.text('All'), findsOneWidget);
        expect(find.text('12 active'), findsOneWidget);
        expect(find.text('3 sold'), findsOneWidget);
        expect(find.text('2 drafts'), findsOneWidget);
        expect(repo.fetchStageCountsCallCount, 1);
      },
    );

    testWidgets('a segment is a filter shortcut and re-fetches by stage', (
      tester,
    ) async {
      final repo = FakeMyListingsRepository(
        ads: [
          myListingAd(id: 'ad-1001', stage: '1'),
          myListingAd(id: 'ad-1005', stage: '2'),
        ],
        stageCounts: const AdStageCounts(active: 1, sold: 1, draft: 0),
      );

      final container = await pumpScreen(tester, repository: repo);
      expect(find.byKey(const ValueKey('myListingRow-ad-1005')), findsOneWidget);

      await tester.tap(
        find.byKey(const ValueKey('myListingsStageSegment-sold')),
      );
      await tester.pumpAndSettle();

      // A real server param, not a client-side narrowing of what was
      // already fetched.
      expect(repo.lastStage, AdStage.sold);
      expect(container.read(myListingsStatusProvider), AdStage.sold);
      expect(find.byKey(const ValueKey('myListingRow-ad-1001')), findsNothing);
      expect(find.byKey(const ValueKey('myListingRow-ad-1005')), findsOneWidget);
    });

    testWidgets(
      'the sticky stage filter stays visible, and All clears it in one tap '
      '(UX audit §5.7)',
      (tester) async {
        // `myListingsStatusProvider` is a non-autoDispose global: a stage
        // filter set once survives the whole session. That is only
        // acceptable because the strip states it on the surface it affects
        // and offers the undo right beside it.
        final repo = FakeMyListingsRepository(
          ads: [myListingAd(id: 'ad-1001', stage: '1')],
          stageCounts: const AdStageCounts(active: 1, sold: 0, draft: 0),
        );

        final container = await pumpScreen(tester, repository: repo);

        // The painted fill is what says "this filter is on" — read it off
        // the segment's own decoration rather than hard-coding a palette
        // value, so the assertion survives a theme change and still fails
        // if selection stops moving.
        Color fillOf(String suffix) {
          final box = tester.widget<Container>(
            find.descendant(
              of: find.byKey(ValueKey('myListingsStageSegment-$suffix')),
              matching: find.byType(Container),
            ),
          );
          return (box.decoration! as BoxDecoration).color!;
        }

        final selectedFill = fillOf('all');
        final unselectedFill = fillOf('draft');
        expect(selectedFill, isNot(unselectedFill));

        await tester.tap(
          find.byKey(const ValueKey('myListingsStageSegment-draft')),
        );
        await tester.pumpAndSettle();
        expect(container.read(myListingsStatusProvider), AdStage.draft);
        // Stated twice, and both statements are on the surface the filter
        // affects: the selected segment moved, and the header's filter
        // badge appeared (it counts Status —
        // `activeMyListingsFilterCount`).
        expect(fillOf('draft'), selectedFill);
        expect(fillOf('all'), unselectedFill);
        expect(
          find.byKey(const ValueKey('myListingsFiltersBadge')),
          findsOneWidget,
        );
        expect(find.bySemanticsLabel('Show Draft ads'), findsOneWidget);

        await tester.tap(
          find.byKey(const ValueKey('myListingsStageSegment-all')),
        );
        await tester.pumpAndSettle();

        expect(container.read(myListingsStatusProvider), isNull);
        expect(
          find.byKey(const ValueKey('myListingsFiltersBadge')),
          findsNothing,
        );
      },
    );

    testWidgets('a counts failure hides the strip and nothing else', (
      tester,
    ) async {
      final repo = FakeMyListingsRepository(
        ads: [myListingAd(id: 'ad-1001')],
        stageCountsError: StateError('stage-counts is down'),
      );

      await pumpScreen(tester, repository: repo);

      expect(find.byKey(const ValueKey('myListingsStageStrip')), findsNothing);
      // Build contract §6 — the ads list is a separate provider and is
      // unaffected.
      expect(find.byKey(const ValueKey('myListingRow-ad-1001')), findsOneWidget);
    });
  });

  group('publish-channel badges (UX audit §9.2)', () {
    testWidgets('a FAILED channel is visible on the row itself', (
      tester,
    ) async {
      // Before this, the only record of a failed public post lived two
      // levels deep: edit the ad, scroll past the whole form, tap "Publish
      // Status".
      final repo = FakeMyListingsRepository(
        ads: [myListingAd(id: 'ad-1001')],
        publishStatuses: {
          'ad-1001': [
            myListingsChannelStatus(
              channel: Channel.telegram,
              status: PublishStatus.published,
            ),
            myListingsChannelStatus(
              channel: Channel.instagram,
              status: PublishStatus.failed,
            ),
          ],
        },
      );

      await pumpScreen(tester, repository: repo);

      expect(
        find.byKey(const ValueKey('myListingChannel-ad-1001-telegram')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('myListingChannel-ad-1001-instagram')),
        findsOneWidget,
      );
      // The tint is what a sighted user reads; this is the same fact for a
      // screen reader, in `Channel.allChannels` order.
      expect(
        find.bySemanticsLabel('Telegram — Published, Instagram — Failed'),
        findsOneWidget,
      );
    });

    testWidgets('an ad with no attempts says so, rather than saying nothing', (
      tester,
    ) async {
      final repo = FakeMyListingsRepository(
        ads: [myListingAd(id: 'ad-1001')],
      );

      await pumpScreen(tester, repository: repo);

      // The batch route answers one key per requested id with an empty
      // list, and an empty list is a real answer: never attempted.
      expect(
        find.bySemanticsLabel('Telegram — Not published, Instagram — '
            'Not published'),
        findsOneWidget,
      );
    });

    testWidgets('a channel published from elsewhere still gets a badge', (
      tester,
    ) async {
      // YouTube has no publish button in this app (`hasServerPublishPath`
      // is false), but the server can still report a publication for it —
      // reported channels are additive to the two always-shown ones.
      final repo = FakeMyListingsRepository(
        ads: [myListingAd(id: 'ad-1001')],
        publishStatuses: {
          'ad-1001': [
            myListingsChannelStatus(
              channel: Channel.youtube,
              status: PublishStatus.published,
            ),
          ],
        },
      );

      await pumpScreen(tester, repository: repo);

      expect(
        find.byKey(const ValueKey('myListingChannel-ad-1001-youtube')),
        findsOneWidget,
      );
    });

    testWidgets('one batched request for the whole page, never one per row', (
      tester,
    ) async {
      // `PublishResource.statusForAds` exists for exactly this; the
      // singular `statusForAd` would be one request per visible row.
      final repo = FakeMyListingsRepository(
        ads: [
          myListingAd(id: 'ad-1'),
          myListingAd(id: 'ad-2'),
          myListingAd(id: 'ad-3'),
        ],
      );

      await pumpScreen(tester, repository: repo);

      expect(repo.fetchPublishStatusesCallCount, 1);
      expect(repo.lastPublishStatusAdIds, ['ad-1', 'ad-2', 'ad-3']);
    });

    testWidgets('tapping the badges opens publish-status for that ad', (
      tester,
    ) async {
      final repo = FakeMyListingsRepository(
        ads: [myListingAd(id: 'ad-1001')],
        publishStatuses: {
          'ad-1001': [
            myListingsChannelStatus(
              channel: Channel.instagram,
              status: PublishStatus.failed,
            ),
          ],
        },
      );

      await pumpScreen(tester, repository: repo);
      final before = tester.state<State>(find.byType(MyListingsScreen));

      await tester.tap(
        find.byKey(const ValueKey('myListingChannel-ad-1001-instagram')),
      );
      await tester.pumpAndSettle();

      expect(find.text('publish-status-stub-ad-1001'), findsOneWidget);

      // Pushed, not `go`ne — My Ads survives underneath, same as for
      // `edit-listing`. Asserted by popping back rather than by looking for
      // `MyListingsScreen` next to the stub: a completed push leaves the
      // route below it offstage, so the default `find.byType` would miss it
      // whether it survived or not. Coming back to the *same* `State` is
      // the thing that separates a push from a `go` (see the edit-icon test
      // above, which this mirrors).
      await tester.binding.handlePopRoute();
      await tester.pumpAndSettle();

      expect(find.text('publish-status-stub-ad-1001'), findsNothing);
      expect(find.byType(MyListingsScreen), findsOneWidget);
      expect(tester.state<State>(find.byType(MyListingsScreen)), same(before));
    });

    testWidgets('a batch failure costs the badges and nothing else', (
      tester,
    ) async {
      final repo = FakeMyListingsRepository(
        ads: [myListingAd(id: 'ad-1001')],
        publishStatusesError: StateError('publish status is down'),
      );

      await pumpScreen(tester, repository: repo);

      expect(find.byKey(const ValueKey('myListingRow-ad-1001')), findsOneWidget);
      // No badge asserts "not published" on an unknown — the strip renders
      // nothing at all rather than a grey pill the app cannot back up.
      expect(
        find.byKey(const ValueKey('myListingChannels-ad-1001')),
        findsNothing,
      );
    });
  });

  group('pull-to-refresh (UX audit §9.3)', () {
    testWidgets('a pull re-fetches the ads, the counts and the badges', (
      tester,
    ) async {
      // `myListingsResultsProvider` is not `autoDispose`, so before this the
      // only thing that ever re-fetched this screen was a filter change or
      // killing the app — an ad added by a coworker or the web console
      // simply never appeared.
      final repo = FakeMyListingsRepository(
        ads: [myListingAd(id: 'ad-1001')],
        stageCounts: const AdStageCounts(active: 1, sold: 0, draft: 0),
      );

      await pumpScreen(tester, repository: repo);
      expect(repo.fetchMyAdsCallCount, 1);
      expect(repo.fetchStageCountsCallCount, 1);
      expect(repo.fetchPublishStatusesCallCount, 1);

      await tester.fling(
        find.byKey(const ValueKey('myListingsListView')),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repo.fetchMyAdsCallCount, 2);
      expect(repo.fetchStageCountsCallCount, 2);
      expect(repo.fetchPublishStatusesCallCount, 2);
      expect(repo.fetchCoworkersCallCount, 2);
    });

    testWidgets('a refresh that fails lands in the list, not in the console', (
      tester,
    ) async {
      // A rejected `onRefresh` future is an unhandled async error: it
      // reaches no user and takes the test run down with it. The same
      // failure is already the list's own error state, which has copy and a
      // Retry — see `refreshMyListings`.
      final repo = FakeMyListingsRepository(ads: [myListingAd(id: 'ad-1001')]);

      await pumpScreen(tester, repository: repo);

      repo.adsError = const NetworkException('offline');
      await tester.fling(
        find.byKey(const ValueKey('myListingsListView')),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(
        find.text('No connection. Check your network and try again.'),
        findsOneWidget,
      );
    });

    testWidgets('the empty state can be pulled too', (tester) async {
      // The state most worth refreshing is the one with nothing on it —
      // which is also the one a default `ListView` refuses to overscroll.
      final repo = FakeMyListingsRepository(ads: const []);

      await pumpScreen(tester, repository: repo);
      expect(repo.fetchMyAdsCallCount, 1);

      await tester.fling(
        find.byType(RefreshIndicator),
        const Offset(0, 300),
        1000,
      );
      await tester.pumpAndSettle();

      expect(repo.fetchMyAdsCallCount, 2);
    });
  });

  group('empty states (UX audit §9.4)', () {
    testWidgets(
      'a brand-new agent gets §25\'s copy and a way forward',
      (tester) async {
        // The only affordance on this screen used to be an unlabelled 38px
        // "+" in the header.
        await pumpScreen(
          tester,
          repository: FakeMyListingsRepository(ads: const []),
        );

        expect(
          find.byKey(const ValueKey('myListingsEmptyState')),
          findsOneWidget,
        );
        expect(find.text('Ads not found.'), findsOneWidget);

        await tester.tap(find.text('Create New Post'));
        await tester.pumpAndSettle();

        expect(find.text('create-listing-stub'), findsOneWidget);
      },
    );

    testWidgets('"filtered out" is a different sentence from "none"', (
      tester,
    ) async {
      // Identical copy for both used to make an agent with a Status=Sold
      // filter believe they had no ads at all.
      final repo = FakeMyListingsRepository(
        ads: [myListingAd(id: 'ad-1001', stage: '1')],
      );
      final container = await pumpScreen(tester, repository: repo);

      container.read(myListingsStatusProvider.notifier).setStatus(AdStage.sold);
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('myListingsFilteredEmptyState')),
        findsOneWidget,
      );
      expect(find.text('No ads match your filters.'), findsOneWidget);
      expect(find.text('Ads not found.'), findsNothing);

      await tester.tap(find.text('Clear filters'));
      await tester.pumpAndSettle();

      expect(container.read(myListingsStatusProvider), isNull);
      expect(find.byKey(const ValueKey('myListingRow-ad-1001')), findsOneWidget);
    });
  });

  group('row details', () {
    testWidgets('Created At is rendered in local time, not UTC', (
      tester,
    ) async {
      // `Ad.createdAt` is decoded `isUtc: true` (`wire_timestamp.dart`), and
      // `Formatters.date` reads the fields straight off whatever it is
      // handed — so without `.toLocal()` an ad created at 09:30 in Tashkent
      // printed 04:30, and one created after 05:00 local printed the
      // previous day's date on a list sorted newest-first.
      const seconds = 1700000800;
      final utc = DateTime.fromMillisecondsSinceEpoch(
        seconds * 1000,
        isUtc: true,
      );

      await pumpScreen(
        tester,
        repository: FakeMyListingsRepository(
          ads: [myListingAd(id: 'ad-1001', createdAtSeconds: seconds)],
        ),
      );

      expect(
        find.textContaining(Formatters.date(utc.toLocal())),
        findsOneWidget,
      );
      // The negative half only says anything on a machine that is not
      // already on UTC; asserting it unconditionally would fail there for a
      // reason that has nothing to do with this code.
      if (utc.toLocal().timeZoneOffset != Duration.zero) {
        expect(find.textContaining(Formatters.date(utc)), findsNothing);
      }
    });

    testWidgets('the edit affordance clears the 48dp touch floor', (
      tester,
    ) async {
      // The circle still paints at the mockup's 34dp — only the transparent
      // hit box around it grew (UX audit §10.2).
      await pumpScreen(
        tester,
        repository: FakeMyListingsRepository(
          ads: [myListingAd(id: 'ad-1001')],
        ),
      );

      final size = tester.getSize(
        find.byKey(const ValueKey('myListingEdit-ad-1001')),
      );
      expect(size.width, greaterThanOrEqualTo(TapTarget.minimumSize));
      expect(size.height, greaterThanOrEqualTo(TapTarget.minimumSize));
      // …and the mockup's `.trow__act` circle is still painted at exactly
      // 34: the hit box grew, the paint did not.
      expect(
        tester.getSize(
          find.descendant(
            of: find.byKey(const ValueKey('myListingEdit-ad-1001')),
            matching: find.byType(Container),
          ),
        ),
        const Size(34, 34),
      );
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

  group('layout holds at real phone widths under ru/uz', () {
    for (final locale in const [Locale('ru'), Locale('uz')]) {
      for (final size in const [
        (label: 'small android', size: Size(360, 800)),
        (label: 'iphone 14', size: Size(390, 844)),
        (label: 'pro max', size: Size(430, 932)),
      ]) {
        testWidgets(
          'toolbar row: no overflow at ${size.label} (${locale.languageCode})',
          (tester) async {
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
              locale: locale,
            );

            expect(tester.takeException(), isNull);
          },
        );

        testWidgets(
          'empty state: no overflow at ${size.label} (${locale.languageCode})',
          (tester) async {
            tester.view.physicalSize = size.size;
            tester.view.devicePixelRatio = 1.0;
            addTearDown(tester.view.resetPhysicalSize);
            addTearDown(tester.view.resetDevicePixelRatio);

            await pumpScreen(
              tester,
              repository: FakeMyListingsRepository(ads: const []),
              locale: locale,
            );

            expect(tester.takeException(), isNull);
          },
        );
      }
    }
  });
}
