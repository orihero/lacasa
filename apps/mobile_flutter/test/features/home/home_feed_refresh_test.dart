// UX audit §9.3 — "nothing refreshes".
//
// `homeFeedAdsProvider` and `topAgentsProvider` are plain, non-autoDispose
// providers: once Home has loaded they are never rebuilt for the life of the
// process, and the only `ref.invalidate` on either one anywhere else lives
// inside `RailRetryCard`, which renders solely after a failure. A session
// opened in the morning was still showing the morning's listings at 6pm,
// with nothing the user could do about it. These tests pin the gesture that
// fixes that, and — just as importantly — that it reaches *both* fetches,
// since a refresh that visibly leaves the Top Agents rail stale is worse
// than none at all.
//
// Kept in its own file rather than folded into `home_feed_screen_test.dart`
// so the drag-based refresh harness (which needs its own pump sequence) does
// not have to share that file's fixed-surface pump helper.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/home/home.dart';
import 'package:lacasa_mobile/features/home/state/home_feed_providers.dart';
import 'package:lacasa_mobile/features/home/state/home_feed_repository_provider.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../shared/support/fake_favourite_ad_ids_repository.dart';
import '../../support/ambient_repository_overrides.dart';
import 'support/fake_home_feed_repository.dart';

Map<String, dynamic> _adJson(int index) {
  return {
    'id': 'ad-$index',
    'title': 'Listing $index',
    'city': 'Tashkent',
    'district': 'District $index',
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': index.isEven ? 'sale' : 'rent',
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
}

void main() {
  Future<ProviderContainer> pumpHome(
    WidgetTester tester,
    FakeHomeFeedRepository repository,
  ) async {
    // Same fixed surface `home_feed_screen_test.dart` uses: the whole feed
    // is one tall CustomScrollView, and a 800x600 default leaves most rails
    // beyond the cache extent where they are never laid out.
    tester.view.physicalSize = const Size(1400, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      // Riverpod's default retry-with-backoff on a failed AsyncNotifier
      // build makes call counts non-deterministic under a time-advancing
      // pump loop; "one call, then exactly one more after the pull" is the
      // whole assertion here.
      retry: (retryCount, error) => null,
      overrides: [
        ...ambientRepositoryOverrides(homeFeed: false, favourites: false),
        homeFeedRepositoryProvider.overrideWithValue(repository),
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
          home: const HomeFeedScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
  }

  /// Drags the feed down far enough to arm the indicator and lets the whole
  /// scroll → spin → hide sequence run out, which is the sequence Flutter's
  /// own `RefreshIndicator` tests use.
  ///
  /// The drag distance is not arbitrary: [RefreshIndicator] only arms once
  /// the overscroll passes 25% of the *viewport* extent, and `pumpHome`
  /// gives this feed a 3600px-tall surface so every rail lays out. That puts
  /// the arming threshold at 900px, so the 400px fling Flutter's own
  /// 600px-tall `RefreshIndicator` tests use would never trip it here.
  Future<void> pullToRefresh(WidgetTester tester) async {
    await tester.fling(
      find.byType(CustomScrollView),
      const Offset(0, 1200),
      1000,
    );
    await tester.pump();
    await tester.pump(const Duration(seconds: 1)); // scroll animation
    await tester.pump(const Duration(seconds: 1)); // indicator settle
    await tester.pump(const Duration(seconds: 1)); // indicator hide
  }

  final ads = [for (var i = 0; i < 4; i++) Ad.fromJson(_adJson(i))];

  testWidgets('the feed carries a pull-to-refresh indicator', (tester) async {
    await pumpHome(tester, FakeHomeFeedRepository(ads: ads));

    expect(find.byKey(const ValueKey('homeFeed-refresh')), findsOneWidget);
  });

  testWidgets('a pull re-requests the feed and the Top Agents rail', (
    tester,
  ) async {
    final repository = FakeHomeFeedRepository(ads: ads);
    await pumpHome(tester, repository);

    expect(repository.fetchFeedCallCount, 1);
    expect(repository.fetchTopAgentsCallCount, 1);

    await pullToRefresh(tester);

    // Both, not just the feed: the rails sit in one scroll and a gesture the
    // user watched complete must not leave half of it on this morning's data.
    expect(repository.fetchFeedCallCount, 2);
    expect(repository.fetchTopAgentsCallCount, 2);
  });

  testWidgets('a pull renders whatever the second fetch returns', (
    tester,
  ) async {
    var call = 0;
    final repository = FakeHomeFeedRepository(
      adsFor: (_) => call++ == 0
          ? ads
          : [Ad.fromJson(_adJson(0)..['title'] = 'Freshly posted')],
    );
    await pumpHome(tester, repository);

    expect(find.text('Freshly posted'), findsNothing);

    await pullToRefresh(tester);

    // Both rails read the same provider, so the new row appears twice
    // (Featured Listings and Explore Nearby).
    expect(find.text('Freshly posted'), findsWidgets);
  });

  testWidgets('the pull keeps the listings on screen instead of blanking '
      'them into skeletons', (tester) async {
    // The mirror image of `rail_loading_states_test.dart`'s Retry tests, and
    // the reason those had to be fixed with `asReload: true` at the two call
    // sites rather than by flipping `when(skipLoadingOnRefresh: false)` in
    // the rails. A refresh keeps the previous `AsyncData` attached and
    // `skipLoadingOnRefresh` defaults to true, so every rail goes on
    // rendering the listings the user is looking at while the new ones load;
    // the [RefreshIndicator]'s own spinner is the feedback. Reloading here
    // would grey out the whole feed under the user's finger, which is
    // exactly what a Retry tap *should* do and a pull should never do.
    final repository = FakeHomeFeedRepository(ads: ads);
    await pumpHome(tester, repository);
    expect(find.text('Listing 0'), findsWidgets);

    // Hold the refresh's fetches open so the assertions below land on a
    // mid-flight frame rather than on the settled result.
    final inFlight = Completer<void>();
    repository.gate = inFlight.future;

    await pullToRefresh(tester);

    expect(repository.fetchFeedCallCount, 2);
    expect(find.text('Listing 0'), findsWidgets);
    expect(find.byType(ShimmerBox), findsNothing);

    inFlight.complete();
    // Explicit pumps rather than `pumpAndSettle`: the indicator's spinner
    // animates indefinitely while it is on screen, so settling never
    // arrives — the same reason `pullToRefresh` above counts frames by hand.
    await tester.pump();
    await tester.pump(const Duration(seconds: 1));
    await tester.pump(const Duration(seconds: 1));
  });

  testWidgets('the pull does not reset the chosen category chip', (
    tester,
  ) async {
    final container = await pumpHome(tester, FakeHomeFeedRepository(ads: ads));

    container
        .read(selectedCategoryChipProvider.notifier)
        .select(2, AdType.nonresidential);
    await tester.pumpAndSettle();

    await pullToRefresh(tester);

    // The lit chip is the user's own current choice, not fetched state —
    // silently dropping it back to "All" mid-refresh would discard a filter
    // they never touched.
    expect(
      container.read(selectedCategoryChipProvider),
      const HomeCategorySelection(index: 2, type: AdType.nonresidential),
    );
  });
}
