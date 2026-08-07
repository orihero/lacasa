// Widget tests for `map-view` (SCREENS.md §3.6).
//
// `mapTileLayerProvider` is overridden to a plain coloured box in every
// test. That is the entire reason the provider exists (see its doc
// comment): the real layer fires HTTP requests at OpenStreetMap's public
// tile servers, which a test suite must not do. Everything under test here
// — pins, selection, the preview card, the counts, navigation — sits above
// the base layer and is unaffected by which one is installed.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/map_view/map_view.dart';
import 'package:lacasa_mobile/features/map_view/widgets/map_preview_card.dart';
import 'package:lacasa_mobile/features/search/data/search_repository.dart';
import 'package:lacasa_mobile/features/search/state/search_repository_provider.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/map/map_tile_layer_provider.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/map_test_ads.dart';

/// Feeds `displayedSearchResultsProvider` — the live state map-view prefers
/// over its `extra:` payload.
class _FakeSearchRepository implements SearchRepository {
  _FakeSearchRepository(this.ads);

  final List<Ad> ads;

  @override
  Future<List<Ad>> fetchResults({AdFilters filters = const AdFilters()}) async {
    return ads;
  }
}

void main() {
  Future<void> pumpMap(
    WidgetTester tester, {
    List<Ad> searchResults = const [],
    List<Ad> fallbackAds = const [],
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final router = GoRouter(
      initialLocation: RoutePaths.mapView,
      routes: [
        GoRoute(
          path: RoutePaths.mapView,
          builder: (context, state) => MapViewScreen(fallbackAds: fallbackAds),
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
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          mapTileLayerProvider.overrideWithValue(
            const ColoredBox(color: Color(0xFFEFEFEF)),
          ),
          searchRepositoryProvider.overrideWithValue(
            _FakeSearchRepository(searchResults),
          ),
        ],
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
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
      // buyer nothing without tapping each one.
      expect(find.text('\$ 90,000'), findsOneWidget);
      expect(find.text('\$ 120,000'), findsOneWidget);
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
    testWidgets('says "n on the map" when every result is mappable', (
      tester,
    ) async {
      await pumpMap(
        tester,
        searchResults: [
          mapAd(id: 'ad-1', lat: 41.31, lng: 69.24),
          mapAd(id: 'ad-2', lat: 41.28, lng: 69.20),
        ],
      );

      expect(find.text('2 on the map'), findsOneWidget);
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
      // Rendered in §3.6's own un-pluralized "{rooms} room" form.
      expect(find.text('2 room'), findsOneWidget);
    });

    testWidgets('an ad with no room count drops that line', (tester) async {
      await pumpMap(
        tester,
        searchResults: [
          mapAd(id: 'ad-1', lat: 41.31, lng: 69.24, rooms: null),
        ],
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
