// Widget tests for the Explore Nearby grid
// (lib/features/home/widgets/explore_nearby_grid.dart).
//
// A [GridView] with a null `padding` adopts the ambient `MediaQuery.padding`'s
// vertical insets as its own (`BoxScrollView.buildSlivers`). For a scroller
// that *is* the page that clears the notch; for this one, nested mid-feed, it
// injected the status bar's height between the "Explore Nearby" heading and
// the first row of cards, and the tab bar's height below the last one — which
// is why these tests pump the grid under a deliberately non-zero inset.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/home/state/home_feed_repository_provider.dart';
import 'package:lacasa_mobile/features/home/widgets/explore_nearby_grid.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../shared/support/fake_favourite_ad_ids_repository.dart';
import '../../support/ambient_repository_overrides.dart';
import 'support/fake_home_feed_repository.dart';

Map<String, dynamic> _adJson(String id) => {
  'id': id,
  'title': 'Listing $id',
  'city': 'Tashkent',
  'district': 'Chilonzor tumani',
  'address': null,
  'reference': null,
  'type': 'residential',
  'category': 'sale',
  'rooms': 3,
  'area': 60,
  'storey': 2,
  'floors': 9,
  'hashtags': null,
  'price': 100000,
  'priceType': 'usd',
  'stage': '1',
  'description': null,
  'nearPlacesList': <String>[],
  'optionList': null,
  'active': true,
  'lat': null,
  'lng': null,
  'tour3dLink': null,
  'agentId': 'agent-1',
  'coworkerId': '',
  'photos': <String>[],
  'media': <Map<String, dynamic>>[],
  'createdAt': {'seconds': 1700000000},
  'updatedAt': {'seconds': 1700000000},
};

// The grid renders `ads.skip(3)`, so six ads leave three cards for it.
final _sixAds = List.generate(6, (i) => Ad.fromJson(_adJson('ad-${1000 + i}')));

void main() {
  /// Pumps the section on its own under [padding] and returns the vertical
  /// distance between the bottom of the "Explore Nearby" heading and the top
  /// of the first card.
  Future<double> headingToFirstCardGap(
    WidgetTester tester, {
    required EdgeInsets padding,
  }) async {
    // Tall enough for all three cells to lay out; the grid shrink-wraps, so a
    // default 800x600 surface would overflow rather than scroll.
    tester.view.physicalSize = const Size(390, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      overrides: [
        ...ambientRepositoryOverrides(homeFeed: false, favourites: false),
        homeFeedRepositoryProvider.overrideWithValue(
          FakeHomeFeedRepository(ads: _sixAds),
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
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Builder(
            builder: (context) => MediaQuery(
              // The screen this section lives on has no app bar above it and
              // no bottom widgets of its own, so the device insets reach the
              // grid's own BuildContext untouched — reproduced here directly.
              data: MediaQuery.of(context).copyWith(padding: padding),
              child: const Scaffold(
                body: Align(
                  alignment: Alignment.topLeft,
                  child: ExploreNearbyGrid(),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    final heading = find.text('Explore Nearby');
    expect(heading, findsOneWidget);
    final firstCard = find.byType(CompactListingCard).first;
    expect(firstCard, findsOneWidget);

    return tester.getTopLeft(firstCard).dy - tester.getBottomLeft(heading).dy;
  }

  testWidgets(
    'the grid does not inherit the device insets as interior padding',
    (tester) async {
      // A notched phone: 59pt of status bar, and a bottom inset that the
      // tab-bar Scaffold inflates further still. Neither may appear inside
      // the feed.
      final withInsets = await headingToFirstCardGap(
        tester,
        padding: const EdgeInsets.only(top: 59, bottom: 96),
      );
      final withoutInsets = await headingToFirstCardGap(
        tester,
        padding: EdgeInsets.zero,
      );

      expect(withInsets, withoutInsets);
    },
  );

  testWidgets('the heading sits `.grid{margin-top:12px}` above the first row', (
    tester,
  ) async {
    final gap = await headingToFirstCardGap(
      tester,
      padding: const EdgeInsets.only(top: 59, bottom: 96),
    );

    // `.sec` has no bottom margin and `.vcard__ph` starts flush at the top of
    // its cell, so `.grid{margin-top:12px}` ([AppSpacing.base], the SizedBox
    // in ExploreNearbyGrid's `_Shell`) is the whole gap. Measured from the
    // heading's text-box bottom, anything beyond that is injected padding.
    expect(gap, AppSpacing.base);
  });
}
