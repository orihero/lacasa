// Widget tests for the pinned Home header (the `_PinnedHomeHeader` sliver in
// lib/features/home/widgets/home_feed_screen.dart).
//
// Deliberately separate from home_feed_screen_test.dart: every test there
// pumps a 1400x3600 surface so the whole feed lays out without scrolling,
// which is exactly the condition under which a pinning bug is invisible.
// These pump a real phone viewport with a real status-bar inset and then
// scroll.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/home/home.dart';
import 'package:lacasa_mobile/features/home/state/home_feed_repository_provider.dart';
import 'package:lacasa_mobile/features/home/widgets/home_header_row.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../shared/support/fake_favourite_ad_ids_repository.dart';
import '../../support/ambient_repository_overrides.dart';
import 'support/fake_home_feed_repository.dart';

/// A notched-phone top inset, the case the header has to get right: the row
/// must clear it, and the fold of the inset into the pinned extent is what
/// keeps the location pill off the clock once the feed scrolls.
const double _topInset = 59;

Map<String, dynamic> _adJson(String id, String title) => {
  'id': id,
  'title': title,
  'city': 'Tashkent',
  'district': 'Chilonzor',
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

void main() {
  Future<void> pumpFeed(WidgetTester tester) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        ...ambientRepositoryOverrides(homeFeed: false, favourites: false),
        homeFeedRepositoryProvider.overrideWithValue(
          FakeHomeFeedRepository(
            ads: List.generate(
              8,
              (i) => Ad.fromJson(_adJson('ad-${1000 + i}', 'Listing $i')),
            ),
          ),
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
          // MaterialApp installs its own MediaQuery from the test view, so
          // the inset has to be injected below it, inside `home`.
          home: Builder(
            builder: (context) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(padding: const EdgeInsets.only(top: _topInset)),
              child: const HomeFeedScreen(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  ScrollPosition feedPosition(WidgetTester tester) =>
      tester.state<ScrollableState>(find.byType(Scrollable).first).position;

  testWidgets('the header clears the status bar at rest', (tester) async {
    await pumpFeed(tester);

    // `topInset + AppSpacing.md` is where the delegate positions the row;
    // the row's own `AppSpacing.base` top padding sits inside that rect, so
    // its top edge is the inset plus the spacer alone.
    expect(
      tester.getTopLeft(find.byType(HomeHeaderRow)).dy,
      _topInset + AppSpacing.md,
    );
    expect(feedPosition(tester).pixels, 0);
  });

  testWidgets('the header stays on screen, unmoved, while the feed scrolls', (
    tester,
  ) async {
    await pumpFeed(tester);
    final restingRect = tester.getRect(find.byType(HomeHeaderRow));

    // A vertical drag anywhere in the feed: the horizontal rails' own
    // recognizers lose the arena to the viewport's vertical one, so the
    // gesture cannot be swallowed by whatever happens to be under the
    // scroll view's centre.
    await tester.drag(find.byType(CustomScrollView), const Offset(0, -400));
    await tester.pumpAndSettle();

    // The feed actually moved...
    expect(feedPosition(tester).pixels, greaterThan(0));
    // ...and the header did not follow it, jump, or resize.
    expect(find.byType(HomeHeaderRow), findsOneWidget);
    expect(tester.getRect(find.byType(HomeHeaderRow)), restingRect);

    // Scrolling back leaves it exactly where it started, i.e. the pinned
    // extent is not being consumed on the way out. Driven off the position
    // rather than by a second drag: the return gesture lands wherever the
    // first one left the feed, and a horizontal rail under that point costs
    // the drag its touch slop, which makes the offset — not the header —
    // the thing the assertion ends up measuring.
    feedPosition(tester).jumpTo(0);
    await tester.pumpAndSettle();
    expect(tester.getRect(find.byType(HomeHeaderRow)), restingRect);
  });

  testWidgets('feed content scrolls underneath the pinned header', (
    tester,
  ) async {
    await pumpFeed(tester);
    final headerBottom = tester.getRect(find.byType(HomeHeaderRow)).bottom;

    // The chip row starts below the header and has to end up above its
    // bottom edge — i.e. behind it — rather than being clipped away at a
    // boundary the way a header outside the scroller would do.
    expect(tester.getTopLeft(find.text('All')).dy, greaterThan(headerBottom));

    await tester.drag(find.byType(CustomScrollView), const Offset(0, -120));
    await tester.pumpAndSettle();

    expect(tester.getTopLeft(find.text('All')).dy, lessThan(headerBottom));
    expect(find.byType(HomeHeaderRow), findsOneWidget);
  });
}
