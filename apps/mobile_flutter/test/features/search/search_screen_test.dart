// Widget tests for `listing-search` (lib/features/search/, SCREENS.md §3.4).
// This screen's build agent was cut off before writing any tests of its own
// (see the README's former "Known gaps" entry) — every test below pumps
// SearchScreen directly inside a themed MaterialApp + ProviderScope, with
// searchRepositoryProvider/recentSearchesRepositoryProvider overridden to
// fakes — no real network, no real keystore, no coupling to the bundled
// fixtures being unchanged. Same shape as home_feed_screen_test.dart and
// saved_listings_screen_test.dart.
//
// The two tests that actually navigate (map toggle handoff, listing
// tap-through) build a small stub GoRouter instead of the bare MaterialApp,
// since `context.push` throws without a GoRouter ancestor — same reasoning
// as saved_listings_screen_test.dart's `pumpScreen`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/search/search.dart';
import 'package:lacasa_mobile/features/search/state/recent_searches_repository_provider.dart';
import 'package:lacasa_mobile/features/search/state/search_providers.dart';
import 'package:lacasa_mobile/features/search/state/search_repository_provider.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../shared/support/fake_favourite_ad_ids_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'support/fake_recent_searches_repository.dart';
import 'support/fake_search_repository.dart';
import 'support/search_test_ads.dart';

void main() {
  Future<ProviderContainer> pumpSearchScreen(
    WidgetTester tester, {
    required FakeSearchRepository repository,
    FakeRecentSearchesRepository? recentsRepository,
    // Overridden by the sort-order tests below: the default 800x600 test
    // surface only lays out ~2 cards' worth of the results ListView (lazy,
    // like every other list in this app), which would leave a 3rd card's
    // `getTopLeft` unable to find its widget. Same fix
    // home_feed_screen_test.dart uses for its own tall CustomScrollView.
    Size? viewSize,
  }) async {
    if (viewSize != null) {
      tester.view.physicalSize = viewSize;
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
    }

    final container = ProviderContainer(
      // Same reasoning as home_feed_screen_test.dart: disables Riverpod 3's
      // automatic exponential-backoff retry so "one call, then one more
      // after Retry" assertions stay exact.
      retry: (retryCount, error) => null,
      overrides: [
        searchRepositoryProvider.overrideWithValue(repository),
        recentSearchesRepositoryProvider.overrideWithValue(
          recentsRepository ?? FakeRecentSearchesRepository(),
        ),
        favouriteAdIdsRepositoryProvider.overrideWithValue(
          FakeFavouriteAdIdsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, theme: AppTheme.light(), home: const SearchScreen()),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// For the two tests that exercise a real `context.push` (map toggle,
  /// listing tap-through). Stub routes stand in for `map-view` and
  /// `listing-detail` so the push can be observed without dragging either
  /// whole screen in — same pattern as `saved_listings_screen_test.dart`.
  Future<ProviderContainer> pumpSearchScreenWithRouter(
    WidgetTester tester, {
    required FakeSearchRepository repository,
    FakeRecentSearchesRepository? recentsRepository,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        searchRepositoryProvider.overrideWithValue(repository),
        recentSearchesRepositoryProvider.overrideWithValue(
          recentsRepository ?? FakeRecentSearchesRepository(),
        ),
        favouriteAdIdsRepositoryProvider.overrideWithValue(
          FakeFavouriteAdIdsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RoutePaths.search,
      routes: [
        GoRoute(
          path: RoutePaths.search,
          builder: (context, state) => const SearchScreen(),
          routes: [
            GoRoute(
              path: 'listing/:id',
              builder: (context, state) => Scaffold(
                body: Text('listing-stub-${state.pathParameters['id']}'),
              ),
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.mapView,
          builder: (context, state) {
            final ads = (state.extra as List<Ad>?) ?? const <Ad>[];
            return Scaffold(
              body: Text(
                'map-stub-${ads.length}-${ads.map((ad) => ad.id).join(",")}',
              ),
            );
          },
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
    return container;
  }

  /// City is no longer a free-text field on `filter-sheet` — it's a
  /// tap-to-pick cascade sourced from `GET /regions`
  /// (`filter_city_district_section.dart`, `filter_option_picker_sheet.dart`).
  /// Drives one full pick end to end: taps the `_PickerField` (opening
  /// `showFilterOptionPicker`'s nested modal sheet), then taps the matching
  /// `filterOption-<value>` row inside it. Same shape as
  /// `filter_sheet_buyer_test.dart`'s own `selectPickerOption` — reused here
  /// rather than reinvented, per that file's doc comment on why City moved
  /// off `TextField`. This screen's default (non-live) `filterRepositoryProvider`
  /// / `regionsRepositoryProvider` wiring already serves
  /// `filter_regions_fixtures.dart`'s bundled single region ('Tashkent') with
  /// no override needed here, same as `filter_sheet_buyer_test.dart`.
  Future<void> selectCity(WidgetTester tester, String value) async {
    final field = find.byKey(const ValueKey('filterField-city'));
    await tester.ensureVisible(field);
    await tester.pumpAndSettle();
    await tester.tap(field);
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('filterOption-$value')));
    await tester.pumpAndSettle();
  }

  group('search bar — debounce and query behaviour', () {
    testWidgets(
      'typing does not filter the results list until 300ms of no further input',
      (tester) async {
        final repo = FakeSearchRepository(
          ads: [
            searchAd(id: 'ad-1', title: 'Bright flat in Chilonzor', district: 'Chilonzor'),
            searchAd(id: 'ad-2', title: 'Studio near Yunusobod metro', district: 'Yunusobod'),
          ],
        );
        await pumpSearchScreen(tester, repository: repo);

        await tester.enterText(
          find.byKey(const ValueKey('searchInputField')),
          'yunusobod',
        );

        // Not yet committed: both ads still show.
        await tester.pump(const Duration(milliseconds: 200));
        expect(find.text('Bright flat in Chilonzor'), findsOneWidget);
        expect(find.text('Studio near Yunusobod metro'), findsOneWidget);

        // Past the 300ms debounce: the list is now filtered.
        await tester.pump(const Duration(milliseconds: 150));
        expect(find.text('Bright flat in Chilonzor'), findsNothing);
        expect(find.text('Studio near Yunusobod metro'), findsOneWidget);
      },
    );

    testWidgets(
      'a debounced non-empty commit is recorded into Recent Searches',
      (tester) async {
        final recents = FakeRecentSearchesRepository();
        await pumpSearchScreen(
          tester,
          repository: FakeSearchRepository(),
          recentsRepository: recents,
        );

        await tester.enterText(
          find.byKey(const ValueKey('searchInputField')),
          'Chilonzor',
        );
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        expect(recents.saveCallCount, greaterThan(0));
        expect(recents.lastSaved, ['Chilonzor']);
        expect(find.text('Chilonzor'), findsWidgets); // the chip itself
      },
    );

    testWidgets(
      'Cancel clears the field and the query immediately, and drops a pending debounce so nothing is recorded',
      (tester) async {
        final recents = FakeRecentSearchesRepository();
        final container = await pumpSearchScreen(
          tester,
          repository: FakeSearchRepository(
            ads: [searchAd(id: 'ad-1', title: 'Bright flat in Chilonzor')],
          ),
          recentsRepository: recents,
        );

        await tester.enterText(
          find.byKey(const ValueKey('searchInputField')),
          'chilonzor',
        );
        // Tap Cancel before the 300ms debounce would have fired.
        await tester.pump(const Duration(milliseconds: 100));
        await tester.tap(find.byKey(const ValueKey('searchCancelButton')));
        await tester.pump(const Duration(milliseconds: 400));
        await tester.pumpAndSettle();

        expect(container.read(searchQueryProvider), '');
        expect(
          tester.widget<TextField>(find.byType(TextField).first).controller!.text,
          '',
        );
        expect(recents.saveCallCount, 0);
        expect(find.text('Bright flat in Chilonzor'), findsOneWidget);
      },
    );
  });

  group('recent searches — persistence, replay, cap/eviction', () {
    testWidgets('renders nothing when there are no recent searches yet', (
      tester,
    ) async {
      await pumpSearchScreen(tester, repository: FakeSearchRepository());

      expect(find.text('Recent Searches'), findsNothing);
      expect(find.text('Clear'), findsNothing);
    });

    testWidgets('renders persisted recents on load, most-recent-first', (
      tester,
    ) async {
      await pumpSearchScreen(
        tester,
        repository: FakeSearchRepository(),
        recentsRepository: FakeRecentSearchesRepository(
          initial: ['Yunusobod', 'Chilonzor'],
        ),
      );

      expect(find.text('Recent Searches'), findsOneWidget);
      expect(find.text('Yunusobod'), findsOneWidget);
      expect(find.text('Chilonzor'), findsOneWidget);
      expect(
        tester.getTopLeft(find.byKey(const ValueKey('recentSearchChip-0'))).dx,
        lessThan(
          tester.getTopLeft(find.byKey(const ValueKey('recentSearchChip-1'))).dx,
        ),
      );
    });

    testWidgets(
      'tapping a chip replays that exact query immediately (no debounce) and bumps it to the front',
      (tester) async {
        final container = await pumpSearchScreen(
          tester,
          repository: FakeSearchRepository(
            ads: [
              searchAd(id: 'ad-1', title: 'Bright flat in Chilonzor', district: 'Chilonzor'),
              searchAd(id: 'ad-2', title: 'Studio near Yunusobod metro', district: 'Yunusobod'),
            ],
          ),
          recentsRepository: FakeRecentSearchesRepository(
            initial: ['Yunusobod', 'Chilonzor'],
          ),
        );

        await tester.tap(find.byKey(const ValueKey('recentSearchChip-1'))); // 'Chilonzor'
        await tester.pump(); // no debounce wait — should apply instantly
        await tester.pumpAndSettle();

        expect(container.read(searchQueryProvider), 'Chilonzor');
        expect(find.text('Bright flat in Chilonzor'), findsOneWidget);
        expect(find.text('Studio near Yunusobod metro'), findsNothing);
        expect(
          tester.widget<TextField>(find.byType(TextField).first).controller!.text,
          'Chilonzor',
        );

        // Bumped to the front of the chip row.
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('recentSearchChip-0')),
            matching: find.text('Chilonzor'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('Clear empties the recent searches row', (tester) async {
      final recents = FakeRecentSearchesRepository(initial: ['Chilonzor']);
      await pumpSearchScreen(
        tester,
        repository: FakeSearchRepository(),
        recentsRepository: recents,
      );
      expect(find.text('Chilonzor'), findsOneWidget);

      await tester.tap(find.text('Clear'));
      await tester.pumpAndSettle();

      expect(find.text('Recent Searches'), findsNothing);
      expect(recents.lastSaved, isEmpty);
    });

    testWidgets(
      'caps at 8 entries, evicting the oldest, most-recent-first',
      (tester) async {
        final container = await pumpSearchScreen(
          tester,
          repository: FakeSearchRepository(),
        );
        final notifier = container.read(recentSearchesProvider.notifier);

        for (var i = 1; i <= 9; i++) {
          await notifier.addQuery('q$i');
        }
        await tester.pumpAndSettle();

        final stored = container.read(recentSearchesProvider).value!;
        expect(stored.length, 8);
        expect(stored.first, 'q9'); // most recent first
        expect(stored.last, 'q2'); // 'q1' evicted as the oldest
        expect(stored.contains('q1'), isFalse);
      },
    );

    testWidgets(
      'de-duplicates case-insensitively, keeping the newest casing at the front',
      (tester) async {
        final container = await pumpSearchScreen(
          tester,
          repository: FakeSearchRepository(),
        );
        final notifier = container.read(recentSearchesProvider.notifier);

        await notifier.addQuery('Chilonzor');
        await notifier.addQuery('Yunusobod');
        await notifier.addQuery('chilonzor'); // same query, different casing
        await tester.pumpAndSettle();

        final stored = container.read(recentSearchesProvider).value!;
        expect(stored, ['chilonzor', 'Yunusobod']);
      },
    );

    testWidgets('a blank query is never recorded', (tester) async {
      final container = await pumpSearchScreen(
        tester,
        repository: FakeSearchRepository(),
      );
      final notifier = container.read(recentSearchesProvider.notifier);

      await notifier.addQuery('   ');
      await tester.pumpAndSettle();

      expect(container.read(recentSearchesProvider).value, isEmpty);
    });

    testWidgets(
      'a query added while the initial load is still in flight survives the '
      'load resolving (real bug found writing this suite: build() used to '
      'silently overwrite it — see RecentSearchesNotifier.addQuery)',
      (tester) async {
        final loadGate = Completer<void>();
        final recents = FakeRecentSearchesRepository(
          initial: ['old'],
          loadHold: loadGate,
        );
        final container = await pumpSearchScreen(
          tester,
          repository: FakeSearchRepository(),
          recentsRepository: recents,
        );
        final notifier = container.read(recentSearchesProvider.notifier);

        // The initial load() is still pending (gated, simulating a slow
        // keystore read). Commit a query now, exactly like a debounce
        // firing before a cold-launch load has resolved.
        final addFuture = notifier.addQuery('new');
        await tester.pump();

        // Now let load() resolve.
        loadGate.complete();
        await addFuture;
        await tester.pumpAndSettle();

        // 'new' must still be there, merged with the list load() returned
        // — not silently clobbered by it.
        expect(container.read(recentSearchesProvider).value, ['new', 'old']);
      },
    );
  });

  group('results list states', () {
    testWidgets('populated: renders every ad from the repository', (
      tester,
    ) async {
      final repo = FakeSearchRepository(
        ads: [
          searchAd(id: 'ad-1', title: 'Bright flat in Chilonzor'),
          searchAd(id: 'ad-2', title: 'Studio near Yunusobod metro'),
        ],
      );
      await pumpSearchScreen(tester, repository: repo);

      expect(find.text('Bright flat in Chilonzor'), findsOneWidget);
      expect(find.text('Studio near Yunusobod metro'), findsOneWidget);
      expect(find.byKey(const ValueKey('featuredCard-ad-1')), findsOneWidget);
    });

    testWidgets(
      'loading: shows a shimmer skeleton, not an error or empty state',
      (tester) async {
        final gate = Completer<void>();
        final repo = FakeSearchRepository(hold: gate, ads: const []);

        final container = ProviderContainer(
          retry: (retryCount, error) => null,
          overrides: [
            searchRepositoryProvider.overrideWithValue(repo),
            recentSearchesRepositoryProvider.overrideWithValue(
              FakeRecentSearchesRepository(),
            ),
            favouriteAdIdsRepositoryProvider.overrideWithValue(
              FakeFavouriteAdIdsRepository(),
            ),
          ],
        );
        addTearDown(container.dispose);

        // Deliberately not settling: ShimmerBox animates continuously, and a
        // hanging fetch never settles — same reasoning as
        // listing_detail_screen_test.dart's identically-shaped loading test.
        await tester.pumpWidget(
          UncontrolledProviderScope(
            container: container,
            child: MaterialApp(
              localizationsDelegates: AppLocalizations.localizationsDelegates,
              supportedLocales: AppLocalizations.supportedLocales,
              theme: AppTheme.light(),
              home: const SearchScreen(),
            ),
          ),
        );
        await tester.pump();

        expect(find.byType(ShimmerBox), findsWidgets);
        expect(find.text('Retry'), findsNothing);
        expect(find.text('No listings found.'), findsNothing);

        gate.complete();
        await tester.pumpAndSettle();
        expect(find.byType(ShimmerBox), findsNothing);
      },
    );

    testWidgets(
      'empty: shows the SCREENS.md-corrected "No listings found." copy',
      (tester) async {
        await pumpSearchScreen(
          tester,
          repository: FakeSearchRepository(ads: const []),
        );

        expect(find.text('No listings found.'), findsOneWidget);
      },
    );

    testWidgets('a failed fetch offers Retry, which re-fetches', (
      tester,
    ) async {
      final repo = FakeSearchRepository(
        error: const NetworkException('offline'),
      );
      await pumpSearchScreen(tester, repository: repo);

      expect(find.text("Couldn't load listings."), findsOneWidget);
      expect(repo.fetchCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.fetchCallCount, 2);
    });
  });

  group('sort control — server-side sort (search_providers.dart documents)', () {
    late FakeSearchRepository repo;

    setUp(() {
      repo = FakeSearchRepository(
        ads: [
          searchAd(
            id: 'ad-mid',
            title: 'Mid-priced, oldest',
            price: 100000,
            createdAtSeconds: 1700000000,
          ),
          searchAd(
            id: 'ad-cheap',
            title: 'Cheapest, newest',
            price: 50000,
            createdAtSeconds: 1700002000,
          ),
          searchAd(
            id: 'ad-expensive',
            title: 'Priciest, middle-aged',
            price: 150000,
            createdAtSeconds: 1700001000,
          ),
        ],
      );
    });

    List<String> visibleOrder(WidgetTester tester) {
      final ids = ['ad-mid', 'ad-cheap', 'ad-expensive'];
      final withY = ids
          .map(
            (id) => (
              id: id,
              y: tester.getTopLeft(find.byKey(ValueKey('featuredCard-$id'))).dy,
            ),
          )
          .toList()
        ..sort((a, b) => a.y.compareTo(b.y));
      return withY.map((e) => e.id).toList();
    }

    testWidgets('defaults to Newest, matching the server\'s own ordering', (
      tester,
    ) async {
      await pumpSearchScreen(
        tester,
        repository: repo,
        viewSize: const Size(800, 2200),
      );

      expect(visibleOrder(tester), ['ad-cheap', 'ad-expensive', 'ad-mid']);
    });

    testWidgets('Highest price sorts descending by price', (tester) async {
      await pumpSearchScreen(
        tester,
        repository: repo,
        viewSize: const Size(800, 2200),
      );

      // The 3 sort chips live in their own horizontally-scrollable strip
      // (search_toolbar.dart's doc comment) so not every chip is
      // necessarily built at a narrow width — `ensureVisible` scrolls the
      // target into the ListView's viewport first, same fix
      // filter_sheet_crm_test.dart uses for its own off-screen chips.
      final highestChip = find.byKey(const ValueKey('sortChip-highestPrice'));
      await tester.ensureVisible(highestChip);
      await tester.tap(highestChip);
      await tester.pumpAndSettle();

      expect(visibleOrder(tester), ['ad-expensive', 'ad-mid', 'ad-cheap']);
    });

    testWidgets('Lowest price sorts ascending by price', (tester) async {
      await pumpSearchScreen(
        tester,
        repository: repo,
        viewSize: const Size(800, 2200),
      );

      final lowestChip = find.byKey(const ValueKey('sortChip-lowestPrice'));
      await tester.ensureVisible(lowestChip);
      await tester.tap(lowestChip);
      await tester.pumpAndSettle();

      expect(visibleOrder(tester), ['ad-cheap', 'ad-mid', 'ad-expensive']);
    });

    testWidgets('Sort applies immediately, with no debounce', (tester) async {
      await pumpSearchScreen(
        tester,
        repository: repo,
        viewSize: const Size(800, 2200),
      );

      final highestChip = find.byKey(const ValueKey('sortChip-highestPrice'));
      await tester.ensureVisible(highestChip);
      await tester.tap(highestChip);
      // Two bare frames — not a `pumpAndSettle`, and deliberately not a
      // `Duration` wait of any length. Sort is server-side now (unlike the
      // client-side re-filter this test used to cover), so tapping a chip
      // still triggers a real, awaited `fetchPage` call; the first `pump`
      // reflects the tap itself (`searchSortProvider` changing state), the
      // second lets that already-in-flight (undelayed, in the fake) fetch's
      // `Future` resolve. What this test actually proves — "no debounce" —
      // is that neither pump carries a wait duration: contrast with the
      // search-query debounce test above, which must advance the clock by a
      // full 300ms before its own re-fetch is even sent.
      await tester.pump();
      await tester.pump();

      expect(visibleOrder(tester), ['ad-expensive', 'ad-mid', 'ad-cheap']);
    });
  });

  group('filter sheet handoff and the Filters badge preview', () {
    testWidgets(
      'opening Filters, applying a change, re-fetches with the applied filters and updates the badge',
      (tester) async {
        final repo = FakeSearchRepository(
          ads: [searchAd(id: 'ad-1', title: 'Bright flat in Chilonzor')],
        );
        await pumpSearchScreen(tester, repository: repo);
        expect(repo.fetchCallCount, 1);
        expect(find.byKey(const ValueKey('filtersBadge')), findsNothing);

        await tester.tap(find.byKey(const ValueKey('filtersButton')));
        await tester.pumpAndSettle();

        await selectCity(tester, 'Tashkent');

        await tester.tap(find.byKey(const ValueKey('filterSheet-apply')));
        await tester.pumpAndSettle();

        // Re-fetched against the newly-applied filters — Furniture/Repair
        // carry their SCREENS.md §3.5 stated defaults too, since the sheet
        // seeds them whenever the incoming value was null (see
        // `filter_sheet.dart#_seedDefaults`).
        expect(repo.fetchCallCount, 2);
        expect(repo.lastFilters?.city, 'Tashkent');
        expect(repo.lastFilters?.furniture, Furniture.withFurniture);
        expect(repo.lastFilters?.repairment, Repairment.notRepaired);

        // The toolbar badge previews the resulting active-filter count.
        expect(find.byKey(const ValueKey('filtersBadge')), findsOneWidget);
        expect(find.text('3'), findsOneWidget);
      },
    );

    testWidgets(
      're-opening Filters seeds the sheet with the currently applied filters',
      (tester) async {
        final repo = FakeSearchRepository(ads: const []);
        await pumpSearchScreen(tester, repository: repo);

        await tester.tap(find.byKey(const ValueKey('filtersButton')));
        await tester.pumpAndSettle();
        await selectCity(tester, 'Tashkent');
        await tester.tap(find.byKey(const ValueKey('filterSheet-apply')));
        await tester.pumpAndSettle();

        // Re-open: the City field should come back pre-filled — the
        // `_PickerField`'s own display text, not a `TextField` controller,
        // since City no longer holds free text (see `selectCity`'s doc
        // comment above).
        await tester.tap(find.byKey(const ValueKey('filtersButton')));
        await tester.pumpAndSettle();

        expect(
          find.descendant(
            of: find.byKey(const ValueKey('filterField-city')),
            matching: find.text('Tashkent'),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets('dismissing the sheet without Apply leaves filters untouched', (
      tester,
    ) async {
      final repo = FakeSearchRepository(ads: const []);
      await pumpSearchScreen(tester, repository: repo);
      expect(repo.fetchCallCount, 1);

      await tester.tap(find.byKey(const ValueKey('filtersButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filterSheet-close')));
      await tester.pumpAndSettle();

      expect(repo.fetchCallCount, 1); // no re-fetch
      expect(find.byKey(const ValueKey('filtersBadge')), findsNothing);
    });
  });

  group('map toggle — handoff to map-view', () {
    testWidgets(
      'passes the currently displayed (query-filtered) results, not the full fetched set',
      (tester) async {
        final repo = FakeSearchRepository(
          ads: [
            // Distinct createdAt so the default Newest sort orders them
            // deterministically — this test's assertion depends on it.
            searchAd(
              id: 'ad-1',
              title: 'Bright flat in Chilonzor',
              district: 'Chilonzor',
              createdAtSeconds: 1700000300,
            ),
            searchAd(
              id: 'ad-2',
              title: 'Studio near Yunusobod metro',
              district: 'Yunusobod',
              createdAtSeconds: 1700000200,
            ),
            searchAd(
              id: 'ad-3',
              title: 'House in Chilonzor with garden',
              district: 'Chilonzor',
              createdAtSeconds: 1700000100,
            ),
          ],
        );
        await pumpSearchScreenWithRouter(tester, repository: repo);

        await tester.enterText(
          find.byKey(const ValueKey('searchInputField')),
          'chilonzor',
        );
        await tester.pump(const Duration(milliseconds: 350));
        await tester.pumpAndSettle();

        await tester.tap(find.byKey(const ValueKey('mapViewButton')));
        await tester.pumpAndSettle();

        expect(find.text('map-stub-2-ad-1,ad-3'), findsOneWidget);
      },
    );

    testWidgets('passes the full result set when no query is active', (
      tester,
    ) async {
      final repo = FakeSearchRepository(
        ads: [
          searchAd(
            id: 'ad-1',
            title: 'Bright flat in Chilonzor',
            createdAtSeconds: 1700000200,
          ),
          searchAd(
            id: 'ad-2',
            title: 'Studio near Yunusobod metro',
            createdAtSeconds: 1700000100,
          ),
        ],
      );
      await pumpSearchScreenWithRouter(tester, repository: repo);

      await tester.tap(find.byKey(const ValueKey('mapViewButton')));
      await tester.pumpAndSettle();

      expect(find.text('map-stub-2-ad-1,ad-2'), findsOneWidget);
    });
  });

  group('results list — tap-through to listing-detail', () {
    testWidgets('tapping a card pushes /search/listing/:id', (tester) async {
      final repo = FakeSearchRepository(
        ads: [searchAd(id: 'ad-1', title: 'Bright flat in Chilonzor')],
      );
      await pumpSearchScreenWithRouter(tester, repository: repo);

      await tester.tap(find.byKey(const ValueKey('featuredCard-ad-1')));
      await tester.pumpAndSettle();

      expect(find.text('listing-stub-ad-1'), findsOneWidget);
    });
  });

  group('toolbar', () {
    testWidgets('renders Filters (no badge when no filters are active), all 3 sort chips, and the map icon', (
      tester,
    ) async {
      await pumpSearchScreen(tester, repository: FakeSearchRepository());

      expect(find.byKey(const ValueKey('filtersButton')), findsOneWidget);
      expect(find.text('Filters'), findsOneWidget);
      expect(find.byKey(const ValueKey('filtersBadge')), findsNothing);

      expect(find.text('Highest price'), findsOneWidget);
      expect(find.text('Lowest price'), findsOneWidget);
      expect(find.text('Newest'), findsOneWidget);

      expect(find.byKey(const ValueKey('mapViewButton')), findsOneWidget);
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

        await pumpSearchScreen(
          tester,
          repository: FakeSearchRepository(
            ads: [
              searchAd(
                id: 'ad-1',
                title: 'Bright 3-room apartment in Chilonzor with a view',
              ),
              searchAd(id: 'ad-2', title: 'Quiet studio near the metro'),
            ],
          ),
          recentsRepository: FakeRecentSearchesRepository(
            initial: ['Chilonzor', 'Yunusobod', 'Mirobod'],
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

        await pumpSearchScreen(
          tester,
          repository: FakeSearchRepository(ads: const []),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
