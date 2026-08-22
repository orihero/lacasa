// What Home's rails render *while a request is in flight* — the frames
// between a control being touched and the answer arriving.
//
// Every assertion here is about that middle frame, which is why the fake
// repository is gated (see `FakeHomeFeedRepository.gate`): an ungated fake
// answers inside the same microtask drain as the pump that would have
// rendered the skeleton, so a test written without the gate passes
// identically against the broken behaviour and the fixed one.
//
// Three distinct contracts, deliberately in one file because they are only
// meaningful against each other:
//
//  1. **Retry shows the skeleton.** `ref.invalidate` defaults to
//     `asReload: false`, i.e. a *refresh*, which re-attaches the previous
//     `AsyncError` and leaves `when`'s `skipLoadingOnRefresh` (default
//     **true**) skipping the `loading:` arm entirely. The rail therefore
//     re-rendered the very same `RailRetryCard` and the screen was
//     pixel-identical from the tap until the network answered.
//     `asReload: true` is the fix, and these are the tests that fail
//     without it.
//
//  2. **A category chip shows the skeleton.** Same requirement, reached a
//     different way: the chip moves a `ref.watch`ed dependency, which
//     Riverpod already classifies as a reload, so this one has always been
//     correct. Pinned anyway — it is the same user-visible promise, and the
//     obvious "simplification" of both rails onto
//     `skipLoadingOnReload: true` would break it silently.
//
//  3. **Pull-to-refresh must NOT show the skeleton.** The mirror image, and
//     the reason (1) is a flag rather than a `when(skipLoadingOnRefresh:
//     false)`: blanking listings the user is looking at into grey boxes
//     under their own finger is a regression. That one lives in
//     `home_feed_refresh_test.dart`, next to the drag harness it needs.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/home/state/home_feed_repository_provider.dart';
import 'package:lacasa_mobile/features/home/widgets/category_chip_row.dart';
import 'package:lacasa_mobile/features/home/widgets/featured_listings_rail.dart';
import 'package:lacasa_mobile/features/home/widgets/top_agents_rail.dart';
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

final _ads = [for (var i = 0; i < 4; i++) Ad.fromJson(_adJson('ad-$i'))];

void main() {
  /// Pumps [child] over [repository] on a surface tall and wide enough for a
  /// whole rail to lay out.
  ///
  /// `retry: (_, _) => null` disables Riverpod's default retry-with-backoff
  /// on a failed build. Two of these tests deliberately leave a provider in
  /// its error state and then assert on what the *next* request renders;
  /// with the backoff live, a timer Riverpod owns fires a request of its own
  /// and the counts and frames stop being the test's to control.
  Future<void> pump(
    WidgetTester tester,
    FakeHomeFeedRepository repository,
    Widget child,
  ) async {
    tester.view.physicalSize = const Size(1200, 1200);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
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
          home: Scaffold(
            body: Align(alignment: Alignment.topLeft, child: child),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  /// Two frames, because the rebuild [WidgetRef.invalidate] schedules is not
  /// the same frame as the tap. Both land while [FakeHomeFeedRepository.gate]
  /// is still open, so this is still the in-flight moment.
  Future<void> pumpInFlight(WidgetTester tester) async {
    await tester.pump();
    await tester.pump();
  }

  group('a Retry tap', () {
    testWidgets('puts the Featured Listings rail into its shimmer skeleton', (
      tester,
    ) async {
      final repository = FakeHomeFeedRepository(
        feedError: Exception('feed unreachable'),
      );
      await pump(tester, repository, const FeaturedListingsRail());

      expect(find.byType(RailRetryCard), findsOneWidget);
      expect(find.byType(ShimmerBox), findsNothing);
      expect(repository.fetchFeedCallCount, 1);

      // Hold the retry request open so there is a frame to look at.
      final inFlight = Completer<void>();
      repository.gate = inFlight.future;

      await tester.tap(find.text('Retry'));
      await pumpInFlight(tester);

      expect(repository.fetchFeedCallCount, 2);
      // The whole point: the card the user just tapped is gone and the rail
      // is visibly working. Before `asReload: true` this frame was the error
      // card again, unchanged.
      expect(find.byType(RailRetryCard), findsNothing);
      expect(find.byType(ShimmerBox), findsNWidgets(3));

      inFlight.complete();
      await tester.pumpAndSettle();

      // Still broken, so the retry card comes back — the skeleton is the
      // in-flight state, not a new terminal one.
      expect(find.byType(RailRetryCard), findsOneWidget);
    });

    testWidgets('puts the Top Agents rail into its shimmer skeleton', (
      tester,
    ) async {
      final repository = FakeHomeFeedRepository(
        topAgentsError: Exception('agents unreachable'),
      );
      await pump(tester, repository, const TopAgentsRail());

      expect(find.byType(RailRetryCard), findsOneWidget);
      expect(find.byType(ShimmerBox), findsNothing);

      final inFlight = Completer<void>();
      repository.gate = inFlight.future;

      await tester.tap(find.text('Retry'));
      await pumpInFlight(tester);

      expect(repository.fetchTopAgentsCallCount, 2);
      expect(find.byType(RailRetryCard), findsNothing);
      // Five skeleton columns, two boxes each (avatar + two caption lines is
      // three boxes per column — see the rail's `loading:` arm).
      expect(find.byType(ShimmerBox), findsNWidgets(15));

      inFlight.complete();
      await tester.pumpAndSettle();
      expect(find.byType(RailRetryCard), findsOneWidget);
    });
  });

  testWidgets('a category chip puts the feed into its shimmer skeleton while '
      'the narrowed request is in flight', (tester) async {
    final repository = FakeHomeFeedRepository(ads: _ads);
    await pump(
      tester,
      repository,
      const Column(
        mainAxisSize: MainAxisSize.min,
        children: [CategoryChipRow(), FeaturedListingsRail()],
      ),
    );

    expect(find.byType(FullListingCard), findsNWidgets(3));
    expect(find.byType(ShimmerBox), findsNothing);

    final inFlight = Completer<void>();
    repository.gate = inFlight.future;

    // Index 3 is Office — `AdType.nonresidential`.
    await tester.tap(find.byKey(const ValueKey('categoryChip-3')));
    await pumpInFlight(tester);

    // A filter the user just applied has to look applied immediately. The
    // previous category's listings are the wrong answer to the question the
    // chip just asked, so they go and the skeleton stands in until the
    // server's answer arrives.
    expect(repository.feedFilterLog.last.type, AdType.nonresidential);
    expect(find.byType(FullListingCard), findsNothing);
    expect(find.byType(ShimmerBox), findsNWidgets(3));

    inFlight.complete();
    await tester.pumpAndSettle();
    expect(find.byType(FullListingCard), findsNWidgets(3));
  });
}
