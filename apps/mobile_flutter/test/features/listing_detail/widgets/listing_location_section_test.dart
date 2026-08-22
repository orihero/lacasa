// Widget tests for `listing-detail`'s Location section (SCREENS.md §3.7) —
// specifically the payload its map preview pushes to `map-view`.
//
// This section answers exactly one question: "where is *this* flat?". It
// used to push `extra: <Ad>[ad]`, a bare list indistinguishable from the
// result set `listing-search`'s map toggle sends, so `map-view` fell through
// to search mode — it watched `searchResultsProvider`, that watch started a
// fetch, and the buyer's one ad was replaced by up to 20 unrelated listings
// under a Filters button for a search they never ran. It now sends a
// `MapViewArgs` naming the ad as `focusAd`.
//
// The `/map-view` route here is a stub that records `state.extra` rather
// than the real `MapViewScreen`: what this section is responsible for is the
// payload, and `test/navigation/map_view_route_test.dart` separately pins
// that the real router turns that payload into the right screen. Keeping the
// two apart also keeps this file from depending on the map screen's own
// widget tree.

import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
// Not exported from the feature barrel — the section is an internal piece
// of the screen, same as `listing_hero.dart` in the screen's own test.
import 'package:lacasa_mobile/features/listing_detail/widgets/listing_location_section.dart';
import 'package:lacasa_mobile/features/map_view/map_view_args.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/map/map_tile_layer_provider.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/listing_detail_test_ads.dart';

void main() {
  /// Pumps the section alone under a router whose `/map-view` is a stub, and
  /// returns a one-element holder the stub writes `state.extra` into.
  Future<List<Object?>> pumpSection(
    WidgetTester tester,
    Ad ad, {
    String branchPrefix = RoutePaths.home,
  }) async {
    final pushed = <Object?>[];

    final router = GoRouter(
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: ListingLocationSection(ad: ad, branchPrefix: branchPrefix),
          ),
        ),
        GoRoute(
          path: RoutePaths.mapView,
          builder: (context, state) {
            pushed.add(state.extra);
            return const Scaffold(body: Placeholder());
          },
        ),
      ],
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          // The real tile layer would fire HTTP at OpenStreetMap's public
          // servers. The preview's pin, caption and tap target all sit above
          // the base layer and are unaffected by which one is installed.
          mapTileLayerProvider.overrideWithValue(
            const ColoredBox(color: Color(0xFFEFEFEF)),
          ),
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

    return pushed;
  }

  testWidgets('tapping the map imagery asks map-view for this one listing', (
    tester,
  ) async {
    final ad = testAd(id: 'ad-1001', lat: 41.31, lng: 69.24);

    final pushed = await pumpSection(tester, ad);
    // Deliberately the *map*, not the caption strip. `flutter_map`'s
    // interactive viewer is the deeper tap recognizer and wins the arena
    // over the enclosing GestureDetector even with `InteractiveFlag.none`,
    // so this tap used to do nothing whatsoever.
    await tester.tapAt(tester.getRect(find.byType(FlutterMap)).center);
    await tester.pumpAndSettle();

    expect(pushed, hasLength(1));
    final args = pushed.single;
    // A bare `List<Ad>` here is the other half of the defect: it cannot say
    // "this one", so the map opened in search mode and fetched a feed.
    expect(args, isA<MapViewArgs>());
    expect((args! as MapViewArgs).focusAd?.id, 'ad-1001');
  });

  testWidgets('tapping the caption strip opens the same thing', (
    tester,
  ) async {
    final ad = testAd(id: 'ad-1001', lat: 41.31, lng: 69.24);

    final pushed = await pumpSection(tester, ad);
    // The caption is inside the enclosing detector but outside the map's
    // own recognizer, so it is the one part that always worked — pinned so
    // the two halves cannot drift to different destinations.
    final section = tester.getRect(
      find.byKey(const ValueKey('listingLocationMap')),
    );
    await tester.tapAt(Offset(section.center.dx, section.bottom - 12));
    await tester.pumpAndSettle();

    expect((pushed.single! as MapViewArgs).focusAd?.id, 'ad-1001');
  });

  testWidgets('the branch it was opened from travels with the tap', (
    tester,
  ) async {
    final ad = testAd(id: 'ad-1001', lat: 41.31, lng: 69.24);

    final pushed = await pumpSection(
      tester,
      ad,
      branchPrefix: RoutePaths.search,
    );
    await tester.tapAt(tester.getRect(find.byType(FlutterMap)).center);
    await tester.pumpAndSettle();

    // So the map's preview card pushes back into the same tab's stack —
    // `MapViewArgs` otherwise defaults to `/search`, which is right for the
    // search toggle and wrong for a listing reached from Home.
    expect((pushed.single! as MapViewArgs).branchPrefix, RoutePaths.search);
  });

  testWidgets('an ad with no coordinates has nothing to open', (tester) async {
    // The section still renders — "we don't know where this is" is
    // information a buyer acts on — but there is no map preview to tap, so
    // no way to reach a map that could not plot the ad anyway.
    final pushed = await pumpSection(tester, testAd(id: 'ad-1008'));

    expect(find.byKey(const ValueKey('listingLocationMap')), findsNothing);
    expect(pushed, isEmpty);
  });
}
