// Widget tests for `map-view` (SCREENS.md §3.6).
//
// `mapTileLayerProvider` is overridden to a plain coloured box in every
// test. That is the entire reason the provider exists (see its doc
// comment): the real layer fires HTTP requests at OpenStreetMap's public
// tile servers, which a test suite must not do. Everything under test here
// — pins, selection, the preview card, the counts, navigation — sits above
// the base layer and is unaffected by which one is installed.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/map_view/map_view.dart';
import 'package:lacasa_mobile/features/map_view/widgets/map_preview_card.dart';
import 'package:lacasa_mobile/features/search/data/search_repository.dart';
import 'package:lacasa_mobile/features/search/state/search_providers.dart';
import 'package:lacasa_mobile/features/search/state/search_repository_provider.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/map/map_tile_layer_provider.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/map_test_ads.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

/// Feeds `searchResultsProvider` — the live state map-view prefers over its
/// `extra:` payload. The screen watches the *paged* provider rather than
/// `displayedSearchResultsProvider` so it can see `nextCursor` and admit
/// that a 20-pin map is not the whole market (audit §9.7), which is why
/// [pageSize] exists here: left null the fake answers one complete,
/// uncursored page (what most tests below want), and set, it pages exactly
/// the way `GET /ads`'s keyset paging does.
class _FakeSearchRepository implements SearchRepository {
  _FakeSearchRepository(this.ads, {this.pageSize});

  /// Mutable so a test can change what the *next* fetch answers — which is
  /// the whole point of a filter change, and the only way to tell "the map
  /// updated" apart from "the map never moved".
  List<Ad> ads;
  final int? pageSize;

  int fetchCallCount = 0;

  /// Holds every fetch open until completed. The reload window (provider
  /// re-running, previous value still on screen) is where the staleness
  /// chrome lives, and it is otherwise a single microtask wide — far too
  /// short for a `pump` to land inside.
  Completer<void>? hold;

  /// Thrown instead of answering, so the failed-reload path — which retains
  /// the previous value exactly as a loading reload does — is reachable.
  Object? failWith;

  @override
  Future<AdPage> fetchPage({
    AdFilters filters = const AdFilters(),
    AdListSort sort = AdListSort.newest,
    String? cursor,
  }) async {
    fetchCallCount++;
    await hold?.future;
    final failure = failWith;
    if (failure != null) throw failure;
    final size = pageSize ?? ads.length;
    final start = cursor == null ? 0 : (int.tryParse(cursor) ?? 0);
    final end = (start + size).clamp(0, ads.length);
    return AdPage(
      items: ads.sublist(start.clamp(0, ads.length), end),
      nextCursor: end >= ads.length ? null : end.toString(),
    );
  }
}

void main() {
  Future<_FakeSearchRepository> pumpMap(
    WidgetTester tester, {
    List<Ad> searchResults = const [],
    List<Ad> fallbackAds = const [],
    int? pageSize,
    Ad? focusAd,
    String branchPrefix = RoutePaths.search,
    _FakeSearchRepository? repository,
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Pre-built only where a test needs the fake configured *before* the
    // very first fetch (a first load that fails); every other caller lets
    // this build one from `searchResults`/`pageSize`.
    repository ??= _FakeSearchRepository(searchResults, pageSize: pageSize);

    final router = GoRouter(
      initialLocation: RoutePaths.mapView,
      routes: [
        GoRoute(
          path: RoutePaths.mapView,
          builder: (context, state) => MapViewScreen(
            fallbackAds: fallbackAds,
            focusAd: focusAd,
            branchPrefix: branchPrefix,
          ),
        ),
        GoRoute(
          path: RoutePaths.search,
          builder: (context, state) =>
              const Scaffold(body: Text('search-root')),
          routes: [
            GoRoute(
              path: 'listing/:id',
              builder: (context, state) => Scaffold(
                body: Text('listing-stub-${state.pathParameters['id']}'),
              ),
            ),
          ],
        ),
        // A second branch, so the preview card's push target can be
        // observed as a *choice* rather than as the one hardcoded path it
        // used to be — a listing reached from Home must not graft its
        // detail page onto the Search tab's stack (audit §4.5).
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const Scaffold(body: Text('home-root')),
          routes: [
            GoRoute(
              path: 'listing/:id',
              builder: (context, state) => Scaffold(
                body: Text('home-listing-stub-${state.pathParameters['id']}'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapTileLayerProvider.overrideWithValue(
            const ColoredBox(color: Color(0xFFEFEFEF)),
          ),
          searchRepositoryProvider.overrideWithValue(repository),
        ],
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    return repository;
  }

  group('pins', () {
    testWidgets('renders one pin per mappable result', (tester) async {
      await pumpMap(
        tester,
        searchResults: [
          mapAd(id: 'ad-1', lat: 41.31, lng: 69.24, price: 90000),
          mapAd(id: 'ad-2', lat: 41.28, lng: 69.20, price: 120000),
        ],
      );

      expect(find.byKey(const ValueKey('mapPin-ad-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('mapPin-ad-2')), findsOneWidget);

      // The pin label is the price — a field of identical pins would tell a
      // buyer nothing without tapping each one — abbreviated to fit the
      // 30dp capsule, exactly as the mockup's own pins read ("$120k").
      expect(find.text('\$90k'), findsOneWidget);
      expect(find.text('\$120k'), findsOneWidget);
    });

    testWidgets('an ad with no coordinates gets no pin', (tester) async {
      await pumpMap(
        tester,
        searchResults: [
          mapAd(id: 'ad-1', lat: 41.31, lng: 69.24),
          mapAd(id: 'ad-2'),
        ],
      );

      expect(find.byKey(const ValueKey('mapPin-ad-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('mapPin-ad-2')), findsNothing);
    });
  });

  group('the count line tells the truth about dropped ads', () {
    testWidgets('says nothing when every result is mappable', (tester) async {
      await pumpMap(
        tester,
        searchResults: [
          mapAd(id: 'ad-1', lat: 41.31, lng: 69.24),
          mapAd(id: 'ad-2', lat: 41.28, lng: 69.20),
        ],
      );

      // The note exists to admit that pins are missing. When none are, it
      // restates what the user can already see — the mockup carries no
      // counter at all, and this is the case it is right about.
      expect(find.text('2 on the map'), findsNothing);
    });

    testWidgets('says "n of m" when some results could not be plotted', (
      tester,
    ) async {
      await pumpMap(
        tester,
        searchResults: [
          mapAd(id: 'ad-1', lat: 41.31, lng: 69.24),
          mapAd(id: 'ad-2'),
          mapAd(id: 'ad-3'),
        ],
      );

      // A map silently showing 1 pin for 3 results lies about the result
      // set; this is the smallest honest way to say so.
      expect(find.text('1 of 3 on the map'), findsOneWidget);
    });
  });

  group('preview card (§3.6)', () {
    testWidgets('no card is shown until a pin is tapped', (tester) async {
      await pumpMap(
        tester,
        searchResults: [mapAd(id: 'ad-1', lat: 41.31, lng: 69.24)],
      );

      expect(find.byType(MapPreviewCard), findsNothing);
    });

    testWidgets('tapping a pin shows the four fields §3.6 names', (
      tester,
    ) async {
      await pumpMap(
        tester,
        searchResults: [
          mapAd(
            id: 'ad-1',
            title: 'Bright two-room near the metro',
            lat: 41.31,
            lng: 69.24,
            rooms: 2,
            price: 90000,
          ),
        ],
      );

      await tester.tap(find.byKey(const ValueKey('mapPin-ad-1')));
      await tester.pumpAndSettle();

      expect(find.byType(MapPreviewCard), findsOneWidget);
      expect(find.text('Bright two-room near the metro'), findsOneWidget);
      // SCREENS.md §3.6 writes this field as literal "{rooms} room", but the
      // i18n pass corrects that to a real ICU plural (listingRoomsCount) —
      // see map_preview_card.dart's doc comment. "2 rooms", not "2 room".
      expect(find.text('2 rooms'), findsOneWidget);
    });

    testWidgets('an ad with no room count drops that line', (tester) async {
      await pumpMap(
        tester,
        searchResults: [mapAd(id: 'ad-1', lat: 41.31, lng: 69.24, rooms: null)],
      );

      await tester.tap(find.byKey(const ValueKey('mapPin-ad-1')));
      await tester.pumpAndSettle();

      expect(find.byType(MapPreviewCard), findsOneWidget);
      expect(find.textContaining('room'), findsNothing);
    });

    testWidgets('tapping the card opens listing-detail in the search branch', (
      tester,
    ) async {
      await pumpMap(
        tester,
        searchResults: [mapAd(id: 'ad-1', lat: 41.31, lng: 69.24)],
      );

      await tester.tap(find.byKey(const ValueKey('mapPin-ad-1')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('mapPreview-ad-1')));
      await tester.pumpAndSettle();

      expect(find.text('listing-stub-ad-1'), findsOneWidget);
    });

    testWidgets('selecting a different pin swaps the card', (tester) async {
      await pumpMap(
        tester,
        searchResults: [
          mapAd(id: 'ad-1', title: 'First listing', lat: 41.31, lng: 69.24),
          mapAd(id: 'ad-2', title: 'Second listing', lat: 41.28, lng: 69.20),
        ],
      );

      await tester.tap(find.byKey(const ValueKey('mapPin-ad-1')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mapPreview-ad-1')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('mapPin-ad-2')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('mapPreview-ad-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('mapPreview-ad-1')), findsNothing);
    });
  });

  group('live search state vs. the extra: payload', () {
    testWidgets('live results win over the fallback', (tester) async {
      await pumpMap(
        tester,
        searchResults: [mapAd(id: 'live-1', lat: 41.31, lng: 69.24)],
        fallbackAds: [mapAd(id: 'stale-1', lat: 41.20, lng: 69.10)],
      );

      // Preferring the snapshot would make the Filters button meaningless —
      // it would update state this screen was ignoring.
      expect(find.byKey(const ValueKey('mapPin-live-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('mapPin-stale-1')), findsNothing);
    });
  });

  // Audit §9.7: `GET /ads` answers 20 rows a page and the map has no scroll
  // of its own, so a search matching 500 listings used to open as 20 pins
  // under a camera fitted snugly around them — a picture that says "this is
  // the market" about 4% of it, with no gesture anywhere on the screen that
  // could add a 21st pin.
  group('how much of the market is on the map', () {
    testWidgets('a page with more behind it admits it, and offers Load more', (
      tester,
    ) async {
      await pumpMap(
        tester,
        searchResults: [
          mapAd(id: 'ad-1', lat: 41.31, lng: 69.24),
          mapAd(id: 'ad-2', lat: 41.28, lng: 69.20),
          mapAd(id: 'ad-3', lat: 41.35, lng: 69.30),
        ],
        pageSize: 2,
      );

      expect(find.byKey(const ValueKey('mapLoadMore')), findsOneWidget);
      expect(find.text('Showing the first 2 matches'), findsOneWidget);
      expect(find.text('Load more'), findsOneWidget);
    });

    testWidgets('a complete result set carries no chip at all', (tester) async {
      await pumpMap(
        tester,
        searchResults: [
          mapAd(id: 'ad-1', lat: 41.31, lng: 69.24),
          mapAd(id: 'ad-2', lat: 41.28, lng: 69.20),
        ],
      );

      // The sentence is rendered exactly when it is true — `nextCursor` is
      // null here, so every match really is on the map and a chip saying
      // otherwise would be its own small lie.
      expect(find.byKey(const ValueKey('mapLoadMore')), findsNothing);
      expect(find.textContaining('Showing the first'), findsNothing);
    });

    testWidgets('tapping it lands the next page of pins on the map', (
      tester,
    ) async {
      await pumpMap(
        tester,
        searchResults: [
          mapAd(id: 'ad-1', lat: 41.31, lng: 69.24),
          mapAd(id: 'ad-2', lat: 41.28, lng: 69.20),
          // Deliberately between the first page's two pins. `_frameCamera`
          // fits the camera once, to the *first* settled pin set, and
          // `MarkerClusterLayer` builds no widget at all for a marker
          // outside the camera — so a second-page ad placed beyond the
          // first page's bounds would be loaded, appended and pinnable and
          // still find nothing here. That would make this a test of
          // flutter_map's culling rather than of paging.
          mapAd(id: 'ad-3', lat: 41.295, lng: 69.225),
        ],
        pageSize: 2,
      );

      expect(find.byKey(const ValueKey('mapPin-ad-3')), findsNothing);

      await tester.tap(find.byKey(const ValueKey('mapLoadMore')));
      await tester.pumpAndSettle();

      // Same `SearchResultsNotifier.loadMore` the results list's infinite
      // scroll calls — one cursor, one page, shared state — so the pins the
      // user asked for here are also in the list behind this screen.
      expect(find.byKey(const ValueKey('mapPin-ad-3')), findsOneWidget);
      // Nothing left behind it now, so the chip retires.
      expect(find.byKey(const ValueKey('mapLoadMore')), findsNothing);
    });

    testWidgets(
      'the dropped-pins note and the partial-results chip both show, and '
      'say different things',
      (tester) async {
        await pumpMap(
          tester,
          searchResults: [
            mapAd(id: 'ad-1', lat: 41.31, lng: 69.24),
            mapAd(id: 'ad-2'), // no coordinates — loaded but not drawable
            mapAd(id: 'ad-3', lat: 41.35, lng: 69.30),
          ],
          pageSize: 2,
        );

        // "1 of 2 on the map" is about what is *drawable* out of what is
        // loaded; "Showing the first 2 matches" is about what is loaded out
        // of what matched. `AdPage` carries no total, so the second is the
        // only honest way this client can say "there are more than these"
        // — see map_view_screen.dart's doc comment.
        expect(find.text('1 of 2 on the map'), findsOneWidget);
        expect(find.text('Showing the first 2 matches'), findsOneWidget);
      },
    );
  });

  // Riverpod hands a *reloading* provider back as `AsyncLoading` that still
  // carries the previous value (and an `AsyncError` from a reload keeps it
  // too), so a map that reads `results.value` naively answers a filter the
  // user has already replaced — silently for the whole round trip, and
  // permanently if the re-fetch throws. Every test below fails against that
  // behaviour: applying a filter used to close the sheet and change nothing
  // on screen at all until the pins abruptly swapped.
  group('a filter change over pins already on screen', () {
    /// Applying filters on this screen goes through `showFilterSheet`, whose
    /// own form is a different feature's surface; what map-view actually
    /// reacts to is the provider that sheet writes on Apply, so these drive
    /// that directly and leave the sheet's fields to `features/filter`'s own
    /// tests.
    void applyFilters(WidgetTester tester, AdFilters filters) {
      ProviderScope.containerOf(tester.element(find.byType(MapViewScreen)))
          .read(appliedSearchFiltersProvider.notifier)
          .apply(filters);
    }

    testWidgets('says the pins are stale instead of presenting them as the '
        'new answer', (tester) async {
      final repository = await pumpMap(
        tester,
        searchResults: [mapAd(id: 'one-room', lat: 41.31, lng: 69.24)],
      );

      repository
        ..hold = Completer<void>()
        ..ads = [mapAd(id: 'two-room', lat: 41.30, lng: 69.23)];
      applyFilters(tester, const AdFilters(rooms: 2));
      await tester.pump();

      // The previous filter set's pin is still drawn — deliberately, a map
      // the user has panned and zoomed is not worth blanking — but it is no
      // longer presented as the answer.
      expect(find.byKey(const ValueKey('mapPin-one-room')), findsOneWidget);
      expect(find.byKey(const ValueKey('mapUpdatingNote')), findsOneWidget);
      expect(find.text('Updating…'), findsOneWidget);
      // Not the full-screen veil: that is for a first load with nothing to
      // show, and throwing away the user's orientation to say "one moment"
      // costs more than it buys.
      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      repository.hold!.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('mapPin-two-room')), findsOneWidget);
      expect(find.byKey(const ValueKey('mapPin-one-room')), findsNothing);
      expect(find.byKey(const ValueKey('mapUpdatingNote')), findsNothing);
    });

    testWidgets('the Load-more chip stands down while the re-fetch is in '
        'flight', (tester) async {
      final repository = await pumpMap(
        tester,
        searchResults: [
          mapAd(id: 'ad-1', lat: 41.31, lng: 69.24),
          mapAd(id: 'ad-2', lat: 41.28, lng: 69.20),
          mapAd(id: 'ad-3', lat: 41.35, lng: 69.30),
        ],
        pageSize: 2,
      );
      expect(find.byKey(const ValueKey('mapLoadMore')), findsOneWidget);

      repository.hold = Completer<void>();
      applyFilters(tester, const AdFilters(rooms: 2));
      await tester.pump();

      // Load-more is not merely misleading here, it is destructive:
      // `loadMore` reads the superseded page's cursor and assigns
      // `AsyncData`, which cancels the reload's loading flag, fetches page 2
      // of the *old* filter set and is then overwritten by the reload it hid.
      expect(find.byKey(const ValueKey('mapLoadMore')), findsNothing);
      expect(find.byKey(const ValueKey('mapUpdatingNote')), findsOneWidget);

      repository.hold!.complete();
      await tester.pumpAndSettle();

      // Still three ads behind a page of two, so the chip comes back — it
      // was suspended for the window, not retired.
      expect(find.byKey(const ValueKey('mapLoadMore')), findsOneWidget);
    });

    testWidgets('a filter change that fails says so and offers a retry, '
        'rather than showing the pre-filter map forever', (tester) async {
      final repository = await pumpMap(
        tester,
        searchResults: [mapAd(id: 'one-room', lat: 41.31, lng: 69.24)],
      );

      repository.failWith = Exception('boom');
      applyFilters(tester, const AdFilters(rooms: 2));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('mapResultsError')), findsOneWidget);
      // `describeReadError`'s non-offline fallback — the same sentence the
      // results list shows for this same provider's failure.
      expect(find.text("Couldn't load listings."), findsOneWidget);
      expect(find.text('Retry'), findsOneWidget);
      // The stale pin stays (it is all the map has), but it is now labelled
      // rather than passed off as the filtered result.
      expect(find.byKey(const ValueKey('mapPin-one-room')), findsOneWidget);


      repository
        ..failWith = null
        ..ads = [mapAd(id: 'two-room', lat: 41.30, lng: 69.23)];
      await tester.tap(find.byKey(const ValueKey('mapResultsError')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('mapResultsError')), findsNothing);
      expect(find.byKey(const ValueKey('mapPin-two-room')), findsOneWidget);
    });

    testWidgets('an offline failure says "you are offline", in the same words '
        'every other read surface uses, and fits the narrowest phone', (
      tester,
    ) async {
      final repository = await pumpMap(
        tester,
        searchResults: [mapAd(id: 'one-room', lat: 41.31, lng: 69.24)],
      );

      // A dozen screens each saying "Couldn't load X" for one dropped
      // connection is the defect `shared/widgets/read_error.dart` exists to
      // prevent, and a map that opted out of it would be the thirteenth.
      repository.failWith = const NetworkException('no route to host');
      applyFilters(tester, const AdFilters(rooms: 2));
      await tester.pumpAndSettle();

      expect(
        find.text('No connection. Check your network and try again.'),
        findsOneWidget,
      );
      expect(find.text("Couldn't load listings."), findsNothing);

      // That sentence is the longest copy this chip can hold, and it sits in
      // a floating pill rather than a full-width card — the narrowest
      // supported phone is where it would burst. A RenderFlex overflow fails
      // the test outright.
      tester.view.physicalSize = const Size(360, 800);
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('mapResultsError')), findsOneWidget);
    });

    testWidgets('a failed first load is not reported as "no matches"', (
      tester,
    ) async {
      final repository = _FakeSearchRepository(const [])
        ..failWith = Exception('boom');

      await pumpMap(tester, repository: repository);

      // "No listings match your search." is a claim about the market; a
      // fetch that never came back is not evidence for it.
      expect(find.text('No listings match your search.'), findsNothing);
      expect(find.byKey(const ValueKey('mapResultsError')), findsOneWidget);
    });

    testWidgets('loading more is not a filter change — it keeps its own '
        'spinner and never claims the map is stale', (tester) async {
      final repository = await pumpMap(
        tester,
        searchResults: [
          mapAd(id: 'ad-1', lat: 41.31, lng: 69.24),
          mapAd(id: 'ad-2', lat: 41.28, lng: 69.20),
          mapAd(id: 'ad-3', lat: 41.295, lng: 69.225),
        ],
        pageSize: 2,
      );

      repository.hold = Completer<void>();
      await tester.tap(find.byKey(const ValueKey('mapLoadMore')));
      await tester.pump();

      // `loadMore` appends to the page in place and reports itself through
      // the chip's own spinner; the pins on screen are still current, so
      // saying "Updating…" over them would be a lie about a control the user
      // did not touch.
      expect(find.byKey(const ValueKey('mapUpdatingNote')), findsNothing);
      expect(find.byKey(const ValueKey('mapLoadMoreSpinner')), findsOneWidget);
      expect(find.byKey(const ValueKey('mapPin-ad-1')), findsOneWidget);

      repository.hold!.complete();
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('mapPin-ad-3')), findsOneWidget);
    });
  });

  // Audit §4.5: `listing-detail`'s Location section pushes here to answer
  // one question — "where is *this* flat?" — and the screen used to answer
  // a different one, fetching up to 20 unrelated listings and framing the
  // camera around all of them.
  group('opened from one listing (focusAd)', () {
    testWidgets('plots that ad alone and never starts a search', (
      tester,
    ) async {
      final focus = mapAd(id: 'focus-1', lat: 41.31, lng: 69.24);
      final repository = await pumpMap(
        tester,
        focusAd: focus,
        searchResults: [mapAd(id: 'other-1', lat: 41.28, lng: 69.20)],
      );

      expect(find.byKey(const ValueKey('mapPin-focus-1')), findsOneWidget);
      expect(find.byKey(const ValueKey('mapPin-other-1')), findsNothing);
      // Not merely filtered out afterwards — the search fetch is never even
      // issued, because subscribing to `searchResultsProvider` *is* the
      // request.
      expect(repository.fetchCallCount, 0);
    });

    testWidgets('opens with the listing already selected', (tester) async {
      await pumpMap(
        tester,
        focusAd: mapAd(
          id: 'focus-1',
          title: 'Bright two-room near the metro',
          lat: 41.31,
          lng: 69.24,
        ),
      );

      // The user asked about this property; making them hunt for and tap
      // its pin to find out which one it is asks the question back at them.
      expect(find.byKey(const ValueKey('mapPreview-focus-1')), findsOneWidget);
      expect(find.text('Bright two-room near the metro'), findsOneWidget);
    });

    testWidgets('offers no Filters button and no partial-results chip', (
      tester,
    ) async {
      await pumpMap(
        tester,
        focusAd: mapAd(id: 'focus-1', lat: 41.31, lng: 69.24),
      );

      // Filters for a search the user never ran, over a content set of one.
      expect(find.text('Filters'), findsNothing);
      expect(find.byKey(const ValueKey('mapLoadMore')), findsNothing);
    });

    testWidgets('a listing with no saved location gets the explanation, not '
        'a preview card floating over an empty city', (tester) async {
      await pumpMap(tester, focusAd: mapAd(id: 'focus-1'));

      expect(
        find.text('None of these listings have a saved location.'),
        findsOneWidget,
      );
      expect(find.byType(MapPreviewCard), findsNothing);
    });

    testWidgets('the preview card pushes into the branch it was opened from', (
      tester,
    ) async {
      await pumpMap(
        tester,
        focusAd: mapAd(id: 'focus-1', lat: 41.31, lng: 69.24),
        branchPrefix: RoutePaths.home,
      );

      await tester.tap(find.byKey(const ValueKey('mapPreview-focus-1')));
      await tester.pumpAndSettle();

      // Hardcoding `/search/listing/:id` grafted a detail page onto the
      // Search tab's stack for a listing the user reached from Home.
      expect(find.text('home-listing-stub-focus-1'), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('back leaves the map', (tester) async {
      await pumpMap(
        tester,
        searchResults: [mapAd(id: 'ad-1', lat: 41.31, lng: 69.24)],
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      // Nothing to pop (the map is the initial location here), so it falls
      // back to the list rather than throwing.
      expect(find.text('search-root'), findsOneWidget);
    });

    testWidgets('the list toggle goes to the same place as back', (
      tester,
    ) async {
      await pumpMap(
        tester,
        searchResults: [mapAd(id: 'ad-1', lat: 41.31, lng: 69.24)],
      );

      await tester.tap(find.bySemanticsLabel('Show list'));
      await tester.pumpAndSettle();

      expect(find.text('search-root'), findsOneWidget);
    });
  });

  // The Android/Impeller tile-compositing workaround used to live as a
  // `Ticker` directly on `_MapViewScreenState` and was tested here. It has
  // moved to `TileCompositingPrimer` in `map_tile_layer_provider.dart`
  // (see that class's doc comment for why: `map-view` isn't the only
  // surface that needs it — `listing-detail`'s Location preview hits the
  // same bug and only the shared tile-layer construction site reaches
  // both). This file's `pumpMap` overrides `mapTileLayerProvider` with a
  // plain coloured box on every test (see the file-level comment above),
  // so the primer is never even in this screen's tree here — the old test
  // that lived in this spot was asserting a guard on code this suite
  // structurally can't exercise. Its replacement is
  // `test/shared/map/map_tile_layer_provider_test.dart`, which pumps the
  // real (non-overridden) provider.

  group('layout holds at real phone widths', () {
    for (final size in const [
      (label: 'small android', size: Size(360, 800)),
      (label: 'iphone 14', size: Size(390, 844)),
      (label: 'pro max', size: Size(430, 932)),
    ]) {
      testWidgets('no overflow at ${size.label}', (tester) async {
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
        addTearDown(() => FlutterError.onError = previous);

        tester.view.physicalSize = size.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpMap(
          tester,
          searchResults: [
            mapAd(
              id: 'ad-1',
              title: 'A deliberately long listing title that has to wrap',
              lat: 41.31,
              lng: 69.24,
              price: 1250000,
            ),
          ],
        );
        await tester.tap(find.byKey(const ValueKey('mapPin-ad-1')));
        await tester.pumpAndSettle();

        expect(overflows, isEmpty, reason: overflows.join('\n'));
      });
    }
  });
}
