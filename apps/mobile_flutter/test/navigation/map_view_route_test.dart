// Regression tests for `app_router.dart`'s `RoutePaths.mapView` builder and
// the payload its callers send it.
//
// `MapViewScreen` shipped a complete single-listing mode — `focusAd`
// suppresses the search watch, pre-selects the pin and hides the Filters
// button — and `MapViewArgs` shipped as its typed carrier, but the route
// builder only ever read `state.extra is List<Ad>`. So `focusAd` was
// unreachable: a buyer tapping "where is this flat?" on `listing-detail`
// got their one ad for a beat (the `fallbackAds` path) and then, once the
// search fetch that the watch itself started came back, up to 20 unrelated
// listings under a Filters button for a search they never ran.
//
// These drive the REAL `goRouterProvider` rather than a scoped stub router,
// because the builder *is* what's under test — a stub router would restate
// the fix rather than check it. `pumpMapViewRoute` therefore mounts the
// whole app shell, which is why the ambient repository overrides are here:
// every un-overridden repository provider builds a live `LaCasaApi` and
// fires real HTTP, and that doesn't fail, it hangs (see
// `test/support/ambient_repository_overrides.dart`).

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/map_view/map_view.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/app_router.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/map/map_tile_layer_provider.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/ambient_repository_overrides.dart';

/// A wire-shaped ad with coordinates, run through the real `Ad.fromJson`.
/// Duplicated locally rather than imported from
/// `test/features/map_view/support/`, matching the per-feature test fixture
/// convention `app_router_redirect_test.dart` already follows here.
Ad _pinnedAd({required String id, double lat = 41.31, double lng = 69.24}) {
  return Ad.fromJson({
    'id': id,
    'title': 'Test listing $id',
    'city': 'Tashkent',
    'district': 'Yunusabad',
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': 'sale',
    'rooms': 3,
    'area': 72,
    'storey': 4,
    'floors': 9,
    'hashtags': null,
    'price': 90000,
    'priceType': 'usd',
    'stage': '1',
    'description': null,
    'nearPlacesList': <String>[],
    'optionList': null,
    'active': true,
    'lat': lat,
    'lng': lng,
    'tour3dLink': null,
    'agentId': 'agent-a',
    'coworkerId': '',
    'photos': <String>[],
    'media': <Map<String, dynamic>>[],
    'createdAt': {'seconds': 1700000000},
    'updatedAt': {'seconds': 1700000000},
  });
}

void main() {
  /// Pumps the real router, pushes `/map-view` with [extra], and returns the
  /// `MapViewScreen` the builder produced.
  Future<MapViewScreen> pumpMapViewRoute(
    WidgetTester tester, {
    required Object? extra,
  }) async {
    final container = ProviderContainer(
      overrides: [
        ...ambientRepositoryOverrides(),
        // The real tile layer fires HTTP at OpenStreetMap's public servers,
        // which a test suite must not do — same override every map test
        // installs, and everything under test here sits above the base
        // layer.
        mapTileLayerProvider.overrideWithValue(
          const ColoredBox(color: Color(0xFFEFEFEF)),
        ),
      ],
    );
    addTearDown(container.dispose);

    final router = container.read(goRouterProvider);
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

    router.push(RoutePaths.mapView, extra: extra);
    await tester.pumpAndSettle();

    return tester.widget<MapViewScreen>(find.byType(MapViewScreen));
  }

  testWidgets('a MapViewArgs with a focusAd reaches the screen as focusAd', (
    tester,
  ) async {
    final ad = _pinnedAd(id: 'ad-focus');

    final screen = await pumpMapViewRoute(
      tester,
      extra: MapViewArgs(focusAd: ad, branchPrefix: RoutePaths.home),
    );

    // The whole point: before the typed branch existed this was null, the
    // screen watched `searchResultsProvider`, and that watch started a
    // 20-ad fetch the user never asked for.
    expect(screen.focusAd?.id, 'ad-focus');
    // And the preview card's push target follows the branch the map was
    // opened from, instead of the `/search` default grafting a Home listing
    // onto the Search tab's stack.
    expect(screen.branchPrefix, RoutePaths.home);
  });

  testWidgets('a MapViewArgs with ads reaches the screen as fallbackAds', (
    tester,
  ) async {
    final ads = [_pinnedAd(id: 'ad-1'), _pinnedAd(id: 'ad-2', lat: 41.33)];

    final screen = await pumpMapViewRoute(tester, extra: MapViewArgs(ads: ads));

    expect(screen.fallbackAds.map((ad) => ad.id), ['ad-1', 'ad-2']);
    expect(screen.focusAd, isNull);
    // Search mode is `MapViewArgs`' default, and search mode is what the
    // map toggle wants.
    expect(screen.branchPrefix, RoutePaths.search);
  });

  testWidgets('a bare List<Ad> is still honoured as fallbackAds', (
    tester,
  ) async {
    // Not a legacy call site any more — both were switched — but a deep
    // link or a restored route stack can still reach this path with the old
    // shape, and dropping it would turn those into an empty map.
    final screen = await pumpMapViewRoute(
      tester,
      extra: <Ad>[_pinnedAd(id: 'ad-deep-link')],
    );

    expect(screen.fallbackAds.map((ad) => ad.id), ['ad-deep-link']);
    expect(screen.focusAd, isNull);
  });

  testWidgets('no extra at all is not an error', (tester) async {
    final screen = await pumpMapViewRoute(tester, extra: null);

    expect(screen.fallbackAds, isEmpty);
    expect(screen.focusAd, isNull);
  });
}
