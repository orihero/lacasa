// Widget tests for the Home feed screen (lib/features/home/). Every test
// pumps HomeFeedScreen directly inside a themed MaterialApp + ProviderScope,
// with homeFeedRepositoryProvider overridden to a FakeHomeFeedRepository, and
// every other repository the screen reaches for pinned to the inert ambient
// set (test/support/ambient_repository_overrides.dart) — no real network.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/auth/state/auth_repository_provider.dart';
import 'package:lacasa_mobile/features/home/home.dart';
import 'package:lacasa_mobile/features/home/state/home_feed_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../shared/support/fake_favourite_ad_ids_repository.dart';
import '../../support/ambient_repository_overrides.dart';
import '../auth/support/fake_auth_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'support/fake_home_feed_repository.dart';

Map<String, dynamic> _adJson({
  required String id,
  required String title,
  required String district,
  String category = 'sale',
  num price = 100000,
  int rooms = 3,
  num area = 60,
}) {
  return {
    'id': id,
    'title': title,
    'city': 'Tashkent',
    'district': district,
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': category,
    'rooms': rooms,
    'area': area,
    'storey': 2,
    'floors': 9,
    'hashtags': null,
    'price': price,
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

/// [ratingAverage] defaults to `null` — carried onto the wire map as an
/// explicit null rather than as `0`, which is how the server reports an
/// agent nobody has reviewed (a SQL aggregate over zero rows produces no
/// row, not a row averaging to zero). The Top Agents caption's whole
/// null-vs-zero rule depends on those two staying distinguishable all the
/// way from JSON to pixels — see `top_agents_rail.dart`'s doc comment.
Map<String, dynamic> _agentJson({
  required String id,
  required String fullName,
  required int adsCount,
  double? ratingAverage,
  int ratingCount = 0,
}) {
  return {
    'id': id,
    'fullName': fullName,
    'email': '$id@lacasa.uz',
    'phoneNumber': null,
    'avatar': null,
    'adsCount': adsCount,
    'ratingAverage': ratingAverage,
    'ratingCount': ratingCount,
  };
}

final _fiveAds = List.generate(
  5,
  (i) => Ad.fromJson(
    _adJson(
      id: 'ad-${1000 + i}',
      title: 'Test listing number $i',
      district: 'District $i',
      category: i.isEven ? 'sale' : 'rent',
    ),
  ),
);

void main() {
  Future<ProviderContainer> pumpHomeFeedScreen(
    WidgetTester tester, {
    required FakeHomeFeedRepository repository,
    FakeFavouriteAdIdsRepository? favouritesRepository,
    UserRole? role,
    bool restoringSession = false,
  }) async {
    // The whole feed is one tall CustomScrollView; a default 800x600 test
    // surface leaves most rails beyond the viewport + cache extent, where
    // Flutter's sliver layout genuinely does not lay out (or reliably
    // mount) far-offscreen SliverToBoxAdapter content. Growing the surface
    // to fit everything avoids relying on scrolling/cache-extent behavior
    // that isn't this screen's own logic to test.
    tester.view.physicalSize = const Size(1400, 3600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final container = ProviderContainer(
      // Riverpod retries a failed AsyncNotifier build automatically with
      // exponential backoff by default; pumpAndSettle's time-advancing
      // pump loop lets several of those backoff timers fire before it
      // considers the tree settled, which would otherwise make
      // fetchFeedCallCount assertions non-deterministic. Disabled here so
      // "one call, then one more after Retry" stays exact.
      retry: (retryCount, error) => null,
      overrides: [
        // Everything this screen doesn't own still resolves to a live,
        // network-backed repository now that the fixtures are gone; the
        // ambient inert set keeps those off the wire. The two this test
        // supplies itself are switched off, because Riverpod throws on a
        // duplicate override rather than letting the later one win.
        ...ambientRepositoryOverrides(
          homeFeed: false,
          favourites: false,
          // The ambient auth repository answers "unauthorized" immediately,
          // which settles the startup restore before the first frame — the
          // opposite of the window `restoringSession` exists to hold open.
          auth: !restoringSession,
        ),
        // A cold start with a token on disk: `AuthSessionNotifier.build`
        // returns `signedOut(isRestoring: true)` and fires `/me` on a
        // microtask, and the held `Completer` keeps it in flight for the
        // whole test, so the tree stays in exactly the state a returning
        // agent sees for the first few hundred milliseconds after launch.
        //
        // **Every `restoringSession: true` caller owes the tree a
        // `pump(Duration(seconds: 9))` before it ends.** `_restoreSession`
        // guards `/me` with an 8s `.timeout`, and holding the request open
        // leaves that Timer armed — `flutter_test` fails a test that ends
        // with a pending Timer ("A Timer is still pending even after the
        // widget tree was disposed"). The one caller below does exactly
        // that; a new one must too.
        if (restoringSession) ...[
          hasPersistedAuthTokenProvider.overrideWithValue(true),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(currentUserHold: Completer<void>()),
          ),
        ],
        homeFeedRepositoryProvider.overrideWithValue(repository),
        favouriteAdIdsRepositoryProvider.overrideWithValue(
          favouritesRepository ?? FakeFavouriteAdIdsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    if (role != null) {
      container.read(authSessionProvider.notifier).setRole(role);
    }

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

  group('happy path', () {
    testWidgets(
      'renders Featured Listings, Top Agents and Explore Nearby from repository data',
      (tester) async {
        final repo = FakeHomeFeedRepository(
          ads: _fiveAds,
          agents: [
            AgentSummary.fromJson(
              _agentJson(
                id: 'agent-a',
                fullName: 'Aybek Karimov',
                adsCount: 10,
                ratingAverage: 4.6,
                ratingCount: 12,
              ),
            ),
          ],
        );

        await pumpHomeFeedScreen(tester, repository: repo);

        // Section headers from all four data-backed rails (Top Districts
        // included — it is derived from this same feed now, one tile per
        // distinct `Ad.district`, so the five fake ads give it five).
        expect(find.text('Featured Listings'), findsOneWidget);
        expect(find.text('Top Districts'), findsOneWidget);
        expect(find.text('Top Agents'), findsOneWidget);
        expect(find.text('Explore Nearby'), findsOneWidget);

        // Featured Listings = first 3 of the 5 fake ads.
        expect(find.text('Test listing number 0'), findsOneWidget);
        expect(find.text('Test listing number 1'), findsOneWidget);
        expect(find.text('Test listing number 2'), findsOneWidget);

        // Explore Nearby = the remaining 2.
        expect(find.text('Test listing number 3'), findsOneWidget);
        expect(find.text('Test listing number 4'), findsOneWidget);

        // Top Agents rail. The caption is the *rating*, not the ad count:
        // "Top Agents" reads as an endorsement and `adsCount` is volume, so
        // the ad count no longer appears anywhere in this rail — see
        // top_agents_rail.dart's doc comment.
        expect(find.text('Aybek'), findsOneWidget); // first name only
        expect(find.text('★ 4.6 (12)'), findsOneWidget);
        expect(find.text('10 ads'), findsNothing);

        // The category chip row still renders every chip; what changed is
        // that a tap now leaves for the Search tab carrying a filter
        // (category_chip_row_test.dart owns that behaviour).
        expect(find.text('All'), findsOneWidget);
        expect(find.text('One Post,\nEvery Channel'), findsOneWidget);
      },
    );

    testWidgets(
      'a Featured Listings card exposes a stable per-ad key for its tap target',
      (tester) async {
        // Navigation itself (context.push('/home/listing/:id')) is exercised
        // against the real GoRouter in
        // test/navigation/tab_shell_test.dart — HomeFeedScreen is that
        // suite's actual /home tab-root builder. This isolated pump has no
        // GoRouter ancestor, so this test only asserts the tap target exists
        // with the id-keyed identity later screens/tests rely on, rather than
        // tapping it (which would throw with no GoRouter in the tree).
        final repo = FakeHomeFeedRepository(ads: _fiveAds);
        await pumpHomeFeedScreen(tester, repository: repo);

        expect(
          find.byKey(const ValueKey('featuredCard-ad-1000')),
          findsOneWidget,
        );
      },
    );
  });

  group('empty state', () {
    testWidgets(
      'shows the combined "No listings available yet." message when the feed is empty',
      (tester) async {
        final repo = FakeHomeFeedRepository(ads: const []);
        await pumpHomeFeedScreen(tester, repository: repo);

        expect(find.text('No listings available yet.'), findsOneWidget);
        // Featured Listings' own header is suppressed for the combined case.
        expect(find.text('Featured Listings'), findsNothing);
        // Top Districts is no longer a static list: it tallies
        // `Ad.district` across this same feed, so an empty feed hides that
        // rail *and* its header rather than promising a ranking it has no
        // data for (top_districts_rail.dart).
        expect(find.text('Top Districts'), findsNothing);
      },
    );
  });

  group('category chips filter the feed in place', () {
    /// Two disjoint catalogues behind one repository, so "the rails
    /// followed the chip" is provable by which titles are on screen rather
    /// than by trusting a recorded filter argument.
    ///
    /// Four of each, not one: Explore Nearby renders the feed *after* the
    /// first three (they belong to Featured Listings), so a one-ad
    /// catalogue would hide that whole section for reasons unrelated to
    /// the chip.
    FakeHomeFeedRepository twoCategoryRepository() {
      final residential = List.generate(
        4,
        (i) => Ad.fromJson(
          _adJson(id: 'ad-r$i', title: 'Sunny flat $i', district: 'Chilonzor'),
        ),
      );
      final nonResidential = List.generate(
        4,
        (i) => Ad.fromJson(
          _adJson(
            id: 'ad-n$i',
            title: 'Corner office $i',
            district: 'Yunusobod',
          ),
        ),
      );
      return FakeHomeFeedRepository(
        adsFor: (filters) => switch (filters.type) {
          AdType.residential => residential,
          AdType.nonresidential => nonResidential,
          _ => [...residential, ...nonResidential],
        },
      );
    }

    testWidgets('tapping a chip narrows the rails without leaving Home', (
      tester,
    ) async {
      await pumpHomeFeedScreen(tester, repository: twoCategoryRepository());

      // "All" — both catalogues are on screen.
      expect(find.text('Sunny flat 0'), findsOneWidget);
      expect(find.text('Corner office 0'), findsOneWidget);

      // Index 3 is Office — `AdType.nonresidential`.
      await tester.tap(find.byKey(const ValueKey('categoryChip-3')));
      await tester.pumpAndSettle();

      expect(find.text('Sunny flat 0'), findsNothing);
      expect(find.text('Corner office 0'), findsOneWidget);
      // Still Home: the rails that make this the landing screen are all
      // still mounted around the narrowed feed.
      expect(find.text('Featured Listings'), findsOneWidget);
      expect(find.text('Explore Nearby'), findsOneWidget);
      // Top Districts is derived from the same list, so it re-tallies for
      // the chosen category instead of ranking districts the feed no
      // longer contains.
      expect(find.text('Yunusobod'), findsOneWidget);
      expect(find.text('Chilonzor'), findsNothing);
    });

    testWidgets('an empty category says so, rather than claiming the whole '
        'catalogue is empty', (tester) async {
      await pumpHomeFeedScreen(
        tester,
        // Nothing non-residential exists here at all.
        repository: FakeHomeFeedRepository(
          adsFor: (filters) =>
              filters.type == AdType.nonresidential ? const [] : _fiveAds,
        ),
      );

      expect(find.text('No listings available yet.'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('categoryChip-3')));
      await tester.pumpAndSettle();

      expect(find.text('No listings in this category yet.'), findsOneWidget);
      // The other message would be a lie: clearing the chip brings the feed
      // straight back.
      expect(find.text('No listings available yet.'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('categoryChip-0')));
      await tester.pumpAndSettle();

      expect(find.text('No listings in this category yet.'), findsNothing);
      expect(find.text('Test listing number 0'), findsOneWidget);
    });
  });

  group('error state', () {
    testWidgets(
      'shows a retry card when the feed fails to load, and Retry re-fetches',
      (tester) async {
        final repo = FakeHomeFeedRepository(
          ads: _fiveAds,
          feedError: const NetworkException('offline'),
        );
        await pumpHomeFeedScreen(tester, repository: repo);

        // Only Featured Listings surfaces its own retry card; Explore Nearby
        // deliberately renders nothing for the same underlying failure
        // rather than asking the user to retry the same fetch twice (see
        // explore_nearby_grid.dart's error branch).
        expect(find.text("Couldn't load listings"), findsOneWidget);
        expect(find.text('Test listing number 0'), findsNothing);
        expect(repo.fetchFeedCallCount, 1);

        // The next call succeeds without changing the fake's error field —
        // FakeHomeFeedRepository's feedError is fixed for its lifetime, so
        // this proves Retry re-invokes fetchFeed rather than proving recovery
        // renders content (a second fake covers that below).
        await tester.tap(find.text('Retry').first);
        await tester.pumpAndSettle();
        expect(repo.fetchFeedCallCount, 2);
      },
    );

    testWidgets('a rail that fails does not blank the rest of the screen', (
      tester,
    ) async {
      final repo = FakeHomeFeedRepository(
        ads: _fiveAds,
        topAgentsError: const NetworkException('offline'),
      );
      await pumpHomeFeedScreen(tester, repository: repo);

      // Top Agents degrades to its own retry card...
      expect(find.text("Couldn't load agents"), findsOneWidget);
      // ...while Featured Listings (a different provider) still renders.
      expect(find.text('Test listing number 0'), findsOneWidget);
      expect(find.text('Explore Nearby'), findsOneWidget);
    });
  });

  group('realistic viewport, empty server', () {
    testWidgets(
      'renders the empty state at a phone-sized viewport with no layout overflow',
      (tester) async {
        // This used to pump a bare ProviderContainer to exercise the app's
        // *default* wiring, back when that default was the bundled
        // FixtureHomeFeedRepository and it could assert on seed content.
        // The fixtures are gone and the default is the live API, so the
        // honest equivalent is the ambient (empty) repositories: a fresh
        // install talking to a server with nothing in it. No test-owned
        // fake here on purpose — the point is the whole screen under one
        // consistent, contentless wiring.
        //
        // The viewport is what this test is really guarding. Every other
        // test in this file uses a deliberately oversized surface so each
        // sliver lays out regardless of scroll position (useful for content
        // assertions), which would hide an overflow that only appears once
        // a rail's cards are squeezed into a real ~390px-wide screen.
        tester.view.physicalSize = const Size(390, 844);
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        final container = ProviderContainer(
          overrides: ambientRepositoryOverrides(),
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

        // flutter_test promotes any FlutterError reported during the test
        // (e.g. "A RenderFlex overflowed by N pixels") to a test failure on
        // its own, so settling at this size without one firing is most of
        // what this test is checking. The assertions below pin down that it
        // settled on the *empty state* rather than on a spinner or an error
        // card, so "no overflow" can't be satisfied by a screen that never
        // rendered its content at all.
        expect(find.text('No listings available yet.'), findsOneWidget);
        // Feed-derived, so it hides with the feed — see the empty-state
        // group above.
        expect(find.text('Top Districts'), findsNothing);
        expect(tester.takeException(), isNull);
      },
    );
  });

  group('favourite control role gating', () {
    testWidgets(
      'the favourite heart is visible for a signed-out/buyer session',
      (tester) async {
        final repo = FakeHomeFeedRepository(ads: _fiveAds);
        await pumpHomeFeedScreen(tester, repository: repo);

        expect(find.byKey(const ValueKey('favourite-ad-1000')), findsOneWidget);
      },
    );

    testWidgets('the favourite heart is absent for an agent session', (
      tester,
    ) async {
      final repo = FakeHomeFeedRepository(ads: _fiveAds);
      await pumpHomeFeedScreen(tester, repository: repo, role: UserRole.agent);

      expect(find.byKey(const ValueKey('favourite-ad-1000')), findsNothing);
      expect(find.byKey(const ValueKey('favourite-ad-1003')), findsNothing);
    });

    testWidgets('the favourite heart is absent for a coworker session', (
      tester,
    ) async {
      final repo = FakeHomeFeedRepository(ads: _fiveAds);
      await pumpHomeFeedScreen(
        tester,
        repository: repo,
        role: UserRole.coworker,
      );

      expect(find.byKey(const ValueKey('favourite-ad-1000')), findsNothing);
    });

    testWidgets(
      'tapping the heart optimistically toggles and calls the repository',
      (tester) async {
        final repo = FakeHomeFeedRepository(ads: _fiveAds);
        final favouritesRepo = FakeFavouriteAdIdsRepository(
          savedAdIds: const {},
        );
        await pumpHomeFeedScreen(
          tester,
          repository: repo,
          favouritesRepository: favouritesRepo,
          // Saving needs an account: FavouriteButton checks the session
          // *before* the optimistic flip and turns a signed-out tap into a
          // sign-in invitation instead of a write. This test is about the
          // write, so it needs a signed-in buyer.
          role: UserRole.user,
        );

        final heartFinder = find.descendant(
          of: find.byKey(const ValueKey('favourite-ad-1000')),
          matching: find.byIcon(Icons.favorite_border_rounded),
        );
        expect(heartFinder, findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('favourite-ad-1000')));
        await tester.pumpAndSettle();

        expect(favouritesRepo.saveCallCount, 1);
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('favourite-ad-1000')),
            matching: find.byIcon(Icons.favorite_rounded),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('Top Agents caption', () {
    testWidgets('an agent with no reviews reads "No reviews yet", never zero '
        'stars', (tester) async {
      // `ratingAverage` absent from the wire object entirely — the shape the
      // server actually sends for an unreviewed agent. Collapsing that to
      // 0.0 would paint the worst possible signal onto someone who has
      // simply never been rated.
      final repo = FakeHomeFeedRepository(
        ads: _fiveAds,
        agents: [
          AgentSummary.fromJson(
            _agentJson(
              id: 'agent-b',
              fullName: 'Dilnoza Yusupova',
              adsCount: 7,
            ),
          ),
        ],
      );

      await pumpHomeFeedScreen(tester, repository: repo);

      expect(find.text('Dilnoza'), findsOneWidget);
      expect(find.text('No reviews yet'), findsOneWidget);
      expect(find.textContaining('★'), findsNothing);
      expect(find.text('7 ads'), findsNothing);

      // ...and it is allowed to *wrap* rather than truncate. At the
      // `.agent__c` micro tier (9.25px Poppins) the string measures ~69px
      // against the mockup's 62px column — ~86px in Russian, ~80px in Uzbek
      // — so a one-line caption ships as "No reviews ye…" for every
      // unreviewed agent, which is the one caption that has to be read whole
      // to mean anything. This assertion cannot be made on rendered width:
      // `flutter_test` substitutes its own fixed-width font for Poppins, so
      // the pixel measurements above simply do not occur here.
      expect(tester.widget<Text>(find.text('No reviews yet')).maxLines, 2);
    });
  });

  group('notification bell role gating', () {
    // `GET /notifications` is 403 for anyone who is not an agent/coworker
    // (api/resources/notifications_resource.dart), and the feed behind it is
    // CRM-only. A bell a buyer can tap buys them shimmer → "Couldn't load
    // notifications" → a Retry that can never succeed.
    const bell = ValueKey('homeNotificationsBell');

    testWidgets('the bell is absent for a signed-out visitor', (tester) async {
      await pumpHomeFeedScreen(
        tester,
        repository: FakeHomeFeedRepository(ads: _fiveAds),
      );

      expect(find.byKey(bell), findsNothing);
      // The search icon beside it is unaffected — the header did not simply
      // fail to render.
      expect(find.byKey(const ValueKey('homeSearchIcon')), findsOneWidget);
    });

    testWidgets('the bell is absent for a signed-in buyer', (tester) async {
      await pumpHomeFeedScreen(
        tester,
        repository: FakeHomeFeedRepository(ads: _fiveAds),
        role: UserRole.user,
      );

      expect(find.byKey(bell), findsNothing);
    });

    testWidgets('the bell is present for an agent', (tester) async {
      await pumpHomeFeedScreen(
        tester,
        repository: FakeHomeFeedRepository(ads: _fiveAds),
        role: UserRole.agent,
      );

      expect(find.byKey(bell), findsOneWidget);
    });

    testWidgets('the bell is present for a coworker', (tester) async {
      await pumpHomeFeedScreen(
        tester,
        repository: FakeHomeFeedRepository(ads: _fiveAds),
        role: UserRole.coworker,
      );

      expect(find.byKey(bell), findsOneWidget);
    });
  });

  group('location pill', () {
    testWidgets('carries no dropdown caret, because it opens nothing', (
      tester,
    ) async {
      await pumpHomeFeedScreen(
        tester,
        repository: FakeHomeFeedRepository(ads: _fiveAds),
      );

      // The label still states where the feed is scoped; only the glyph that
      // promised a picker is gone (home_header_row.dart's doc comment).
      expect(find.text('Tashkent, Uzbekistan'), findsOneWidget);
      expect(find.byIcon(Icons.keyboard_arrow_down_rounded), findsNothing);
    });
  });

  group('agent pitch banner', () {
    const getStarted = ValueKey('getStartedAgentPitch');

    testWidgets('pitches to a settled signed-out visitor', (tester) async {
      await pumpHomeFeedScreen(
        tester,
        repository: FakeHomeFeedRepository(ads: _fiveAds),
      );

      expect(find.byKey(getStarted), findsOneWidget);
    });

    testWidgets('says nothing at all while a session is still restoring', (
      tester,
    ) async {
      // The cold-start window: `role` is null but only because `/me` has not
      // answered yet, so a returning agent is momentarily indistinguishable
      // from a visitor. Pitching "become an agent" at them is a claim about
      // the user the app has not yet earned.
      await pumpHomeFeedScreen(
        tester,
        repository: FakeHomeFeedRepository(ads: _fiveAds),
        restoringSession: true,
      );

      expect(find.byKey(getStarted), findsNothing);
      // The rest of the feed is unaffected — this suppresses one banner, not
      // the screen.
      expect(find.text('Test listing number 0'), findsOneWidget);

      // `AuthSessionNotifier._restoreSession` guards `/me` with an 8s
      // `.timeout`, and the held Completer above keeps that request in
      // flight for the whole test — so the timeout's Timer is still armed
      // here. `flutter_test` fails a test that ends with a pending Timer, so
      // let it fire: the restore then degrades to signed-out, which is the
      // real cold-start outcome for a request that never answers.
      await tester.pump(const Duration(seconds: 9));
      await tester.pumpAndSettle();
    });

    testWidgets('stays hidden for a signed-in buyer', (tester) async {
      await pumpHomeFeedScreen(
        tester,
        repository: FakeHomeFeedRepository(ads: _fiveAds),
        role: UserRole.user,
      );

      expect(find.byKey(getStarted), findsNothing);
    });
  });
}
