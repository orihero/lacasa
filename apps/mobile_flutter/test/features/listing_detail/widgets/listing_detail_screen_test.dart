// Widget tests for `listing-detail` (SCREENS.md §3.7).
//
// These drive the REAL GoRouter from `goRouterProvider` and navigate to
// `/home/listing/:id`, rather than pumping ListingDetailScreen bare. Two
// reasons: the route wiring (both branches, the path param, the screen
// keeping the tab bar) is part of what this screen has to get right, and
// the screen itself calls `context.push` / `context.canPop`, which need a
// router in the tree anyway.
//
// `retry: (_, _) => null` on the ProviderScope disables Riverpod 3's
// automatic exponential-backoff retry, which is on in the app deliberately
// (see listing_detail_providers.dart) and would otherwise race every error
// assertion here against a timer. Same thing home_feed_screen_test.dart does.

import '../../../support/ambient_repository_overrides.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/agents/agents.dart';
import 'package:lacasa_mobile/features/listing_detail/listing_detail.dart';
// Not exported from the feature barrel — the hero is an internal piece, and
// this is the only place outside the screen that needs to name it (to tap
// it).
import 'package:lacasa_mobile/features/listing_detail/widgets/listing_hero.dart';
import 'package:lacasa_mobile/features/photo_gallery/photo_gallery.dart';
import 'package:lacasa_mobile/navigation/app_router.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/workspace_mode.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../../shared/support/fake_favourite_ad_ids_repository.dart';
import '../support/fake_listing_detail_repository.dart';
import '../support/listing_detail_test_ads.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  /// Pumps the app at `/home/listing/<id>` with [repository] wired in, and
  /// returns the container so a test can flip roles or inspect providers.
  Future<ProviderContainer> pumpDetail(
    WidgetTester tester,
    FakeListingDetailRepository repository, {
    String adId = 'ad-1001',
    bool settle = true,
  }) async {
    final container = ProviderContainer(
      retry: (_, _) => null,
      overrides: [
        ...ambientRepositoryOverrides(favourites: false, listingDetail: false),
        listingDetailRepositoryProvider.overrideWithValue(repository),
        favouriteAdIdsRepositoryProvider.overrideWithValue(
          FakeFavouriteAdIdsRepository(),
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

    router.push('/home/listing/$adId');
    if (settle) {
      await tester.pumpAndSettle();
    } else {
      await tester.pump();
    }
    return container;
  }

  /// The agent block and Save the Place sit well below the fold on the
  /// 800x600 default test surface — this screen is a long scroll by design.
  /// Scroll them into view before tapping, rather than shrinking the
  /// content to fit the test.
  Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('states', () {
    testWidgets('renders the listing once it loads', (tester) async {
      final repository = FakeListingDetailRepository(
        ad: testAd(
          title: 'Bright 3-room apartment in Chilonzor',
          district: 'Chilonzor',
          rooms: 3,
          area: 65,
          storey: 4,
          floors: 9,
          description: 'A bright, well-kept apartment.',
        ),
        agent: testAgent(),
      );

      await pumpDetail(tester, repository);

      expect(find.byType(ListingDetailScreen), findsOneWidget);
      expect(find.text('Bright 3-room apartment in Chilonzor'), findsOneWidget);
      expect(find.text('Chilonzor, Tashkent'), findsOneWidget);
      // The hero pill and the price footer both carry the price; the bottom
      // bar carries it a third time. All three are intentional.
      expect(find.textContaining(r'$78,000'), findsWidgets);
      expect(find.text('Javlon Rustamov'), findsOneWidget);
      expect(find.text('Submit an application'), findsOneWidget);
    });

    testWidgets('shows a skeleton, not an error, while loading', (
      tester,
    ) async {
      final repository = FakeListingDetailRepository()..adHangs = true;

      // Deliberately not settling: a hanging fetch never settles, and the
      // point is what the user sees before it resolves.
      await pumpDetail(tester, repository, settle: false);
      await tester.pump();

      expect(find.byType(ShimmerBox), findsWidgets);
      expect(find.text('Retry'), findsNothing);
      expect(find.textContaining("Couldn't load"), findsNothing);
    });

    testWidgets('a failed fetch offers Retry, which re-fetches', (
      tester,
    ) async {
      final repository = FakeListingDetailRepository()
        ..adError = const NetworkException('offline');

      await pumpDetail(tester, repository);

      expect(find.text("Couldn't load this listing."), findsOneWidget);
      expect(repository.fetchAdCalls, 1);

      // The next call succeeds without clearing `adError` first would prove
      // nothing, so let it succeed and assert on the call count as well as
      // the recovered UI.
      repository
        ..adError = null
        ..ad = testAd(title: 'Recovered listing');

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repository.fetchAdCalls, 2);
      expect(find.text('Recovered listing'), findsOneWidget);
    });

    testWidgets('a 404 says the listing is gone and offers no Retry', (
      tester,
    ) async {
      // Distinct copy on purpose: "try again" is bad advice for a listing
      // that has been sold or removed.
      final repository = FakeListingDetailRepository(); // no ad -> 404

      await pumpDetail(tester, repository);

      expect(
        find.textContaining('This listing is no longer available.'),
        findsOneWidget,
      );
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('back is available even when the listing failed to load', (
      tester,
    ) async {
      final repository = FakeListingDetailRepository()
        ..adError = const NetworkException('offline');

      await pumpDetail(tester, repository);

      // A user who deep-linked into a dead listing must be able to leave.
      expect(find.bySemanticsLabel('Back'), findsOneWidget);
      // ...but there is nothing to share or save yet.
      expect(find.bySemanticsLabel('Share'), findsNothing);
    });
  });

  group('honest gaps (SCREENS.md sections drop rather than render empty)', () {
    testWidgets('an ad with no optional data shows no empty sections', (
      tester,
    ) async {
      // Everything optional absent: no description, no options, no nearby
      // places, no rooms/area/floor — and a type/category this build does
      // not recognize, so even the info tags resolve to nothing. The tags
      // now live *inside* the Description pane (the mockup nests `.tags`
      // in `data-pane-body="description"`), so they have to be gone too
      // before that segment is genuinely empty.
      final repository = FakeListingDetailRepository(
        ad: testAd(type: 'not-a-known-type', category: 'not-a-known-category'),
        agent: testAgent(),
      );

      await pumpDetail(tester, repository);

      expect(find.text('Description'), findsNothing);
      expect(find.text('Additional Information'), findsNothing);
      expect(find.text('Sizes'), findsNothing);
      expect(find.text('Nearby Places'), findsNothing);
      // Location is the documented exception — "we don't know where this
      // is" is information the buyer acts on. It is the only surviving
      // pane, so it is also the selected one and its body is on screen.
      expect(find.text('Location'), findsOneWidget);
      expect(
        find.text('No location provided for this listing.'),
        findsOneWidget,
      );
    });

    testWidgets('the Description pane survives on its info tags alone', (
      tester,
    ) async {
      // No description paragraph, but a stated type and category. The tags
      // are that pane's body in the mockup, so the segment is not empty and
      // must not be dropped — the counterpart to the test above.
      final repository = FakeListingDetailRepository(
        ad: testAd(type: 'residential', category: 'sale'),
        agent: testAgent(),
      );

      await pumpDetail(tester, repository);

      expect(find.text('Description'), findsOneWidget);
      // Description is pane 0, so its body — the tags — is the one on screen.
      expect(find.text('Residential'), findsOneWidget);
      expect(find.text('Sale'), findsOneWidget);
    });

    testWidgets('a malformed optionList drops the section without throwing', (
      tester,
    ) async {
      final repository = FakeListingDetailRepository(
        ad: testAd(
          optionList: 'malformed-not-a-list',
          nearPlacesList: const [],
        ),
        agent: testAgent(),
      );

      await pumpDetail(tester, repository);

      expect(tester.takeException(), isNull);
      expect(find.text('Additional Information'), findsNothing);
      expect(find.byType(ListingDetailScreen), findsOneWidget);
    });

    testWidgets('info tags show only the attributes the ad states', (
      tester,
    ) async {
      final repository = FakeListingDetailRepository(
        // No repairment, no furniture — ad-1003's shape.
        ad: testAd(type: 'residential', category: 'sale'),
        agent: testAgent(),
      );

      await pumpDetail(tester, repository);

      expect(find.text('Residential'), findsWidgets);
      expect(find.text('Sale'), findsOneWidget);
      expect(find.text('Normal'), findsNothing);
      expect(find.text('With furniture'), findsNothing);
    });

    testWidgets('populated sections render their content', (tester) async {
      final repository = FakeListingDetailRepository(
        ad: testAd(
          rooms: 3,
          area: 65,
          storey: 4,
          floors: 9,
          repairment: 'normal',
          furniture: 'withFurniture',
          description: 'South-facing living room.',
          nearPlacesList: const ['Chilonzor metro station (7 min walk)'],
          optionList: const [
            {'key': 'Parking', 'value': 'Yes'},
          ],
          lat: 41.281,
          lng: 69.205,
        ),
        agent: testAgent(),
      );

      await pumpDetail(tester, repository);

      // The bodies are `.pane`s behind a `.segs` segmented control now, not
      // five stacked sections: Description is on by default, every other
      // body is one tap on its segment away.
      Future<void> openPane(String label) async {
        final segment = find.text(label);
        await tester.ensureVisible(segment);
        await tester.pumpAndSettle();
        await tester.tap(segment);
        await tester.pumpAndSettle();
      }

      expect(find.text('South-facing living room.'), findsOneWidget);
      expect(find.text('Sizes'), findsOneWidget);

      await openPane('Additional Information');
      expect(find.text('Parking · Yes'), findsOneWidget);

      await openPane('Sizes');
      expect(find.text('4 / 9'), findsOneWidget);

      await openPane('Nearby Places');
      expect(find.text('Chilonzor metro station (7 min walk)'), findsOneWidget);

      await openPane('Location');
      expect(find.text('41.2810, 69.2050'), findsOneWidget);

      // Price per m²: 78000 / 65 = 1200. The footer is outside the panes,
      // so it stays on screen whichever segment is selected.
      expect(find.textContaining(r'$1,200 / m²'), findsOneWidget);
    });
  });

  group('agent block', () {
    testWidgets('degrades on its own without taking the listing down', (
      tester,
    ) async {
      // fetchAgent resolving to null is what a deleted agent, a coworker
      // id, and an offline device all look like from here.
      final repository = FakeListingDetailRepository(
        ad: testAd(title: 'Still renders'),
      );

      await pumpDetail(tester, repository);

      expect(find.text('Agent details unavailable'), findsOneWidget);
      expect(find.text('Still renders'), findsOneWidget);
      expect(find.text('Submit an application'), findsOneWidget);
    });

    testWidgets('skips the fetch entirely for an ad with no agentId', (
      tester,
    ) async {
      final repository = FakeListingDetailRepository(
        ad: testAd(agentId: ''),
        agent: testAgent(),
      );

      await pumpDetail(tester, repository);

      expect(repository.fetchAgentCalls, 0);
      expect(find.text('Agent details unavailable'), findsOneWidget);
    });

    testWidgets('shows the agent rating, not a sales tally', (tester) async {
      final repository = FakeListingDetailRepository(
        ad: testAd(),
        agent: testAgent(
          adsCount: 24,
          dealsClosedCount: 9,
          ratingAverage: 4.6,
          ratingCount: 12,
        ),
      );

      await pumpDetail(tester, repository);

      expect(
        find.byKey(const ValueKey('listingAgentRating')),
        findsOneWidget,
      );
      expect(find.text('Review: 4.6/5'), findsOneWidget);
      // `dealsClosedCount` is a sales-performance metric and has no place
      // on a buyer surface; `adsCount` is an all-time AD_CREATED tally that
      // disagrees with the agent-profile figure a tap away. Neither may
      // come back — this is the assertion that says so.
      expect(find.textContaining('9 closed'), findsNothing);
      expect(find.textContaining('24 listings'), findsNothing);
    });

    testWidgets('an unreviewed agent gets copy, never a zero-star row', (
      tester,
    ) async {
      final repository = FakeListingDetailRepository(
        ad: testAd(),
        agent: testAgent(),
      );

      await pumpDetail(tester, repository);

      expect(find.text('No reviews yet'), findsOneWidget);
      expect(find.textContaining('/5'), findsNothing);
    });
  });

  // §9.6 — the hero used to put a play glyph on a video slide and hand the
  // tap to a gallery with no player in it. These tests pin the replacement:
  // the slide *names* the medium and never advertises playback.
  group('hero video slide', () {
    const videoMedia = <Map<String, dynamic>>[
      {'url': 'https://example.test/tour.mp4', 'mediaType': 'video', 'position': 0},
    ];
    const photoThenVideo = <Map<String, dynamic>>[
      {'url': 'https://example.test/a.jpg', 'mediaType': 'photo', 'position': 0},
      {'url': 'https://example.test/tour.mp4', 'mediaType': 'video', 'position': 1},
    ];

    testWidgets('badges a video slide instead of promising playback', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        FakeListingDetailRepository(
          ad: testAd(media: videoMedia),
          agent: testAgent(),
        ),
      );

      expect(find.byKey(const ValueKey('listingHeroVideoBadge')), findsOneWidget);
      expect(find.text('Video'), findsOneWidget);
      // The whole point of the change: the "press here and it plays" glyph
      // must not come back while the gallery still refuses to play it.
      expect(find.byIcon(Icons.play_circle_outline_rounded), findsNothing);
      expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    });

    testWidgets('leaves a photo-only hero unbadged', (tester) async {
      await pumpDetail(
        tester,
        FakeListingDetailRepository(
          ad: testAd(photos: const ['https://example.test/a.jpg']),
          agent: testAgent(),
        ),
      );

      expect(find.byKey(const ValueKey('listingHeroVideoBadge')), findsNothing);
      expect(find.text('Video'), findsNothing);
    });

    testWidgets('the badge follows the visible slide, not the ad', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        FakeListingDetailRepository(
          ad: testAd(media: photoThenVideo),
          agent: testAgent(),
        ),
      );

      // Slide 1 is a photo — badging it would mislabel it just as surely as
      // the old play glyph mislabeled the video.
      expect(find.byKey(const ValueKey('listingHeroVideoBadge')), findsNothing);

      // A plain `drag` of half the 800px viewport does not turn the page:
      // `tester.drag` eats `kTouchSlop` first, so the release lands just
      // under the 50% mark at zero velocity and `PageScrollPhysics` snaps
      // back to slide 1. A fling carries the velocity that commits the page.
      await tester.fling(find.byType(PageView), const Offset(-400, 0), 1000);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('listingHeroVideoBadge')), findsOneWidget);
    });
  });

  group('navigation', () {
    testWidgets('tapping the hero opens photo-gallery with this ad', (
      tester,
    ) async {
      // The link that was missing: before this screen existed, nothing in
      // the app pushed /photo-gallery at all.
      final repository = FakeListingDetailRepository(
        ad: testAd(photos: const ['https://example.test/a.jpg']),
        agent: testAgent(),
      );

      await pumpDetail(tester, repository);
      await tester.tap(find.byType(ListingHero));
      await tester.pumpAndSettle();

      expect(find.byType(PhotoGalleryScreen), findsOneWidget);
    });

    testWidgets('tapping the agent block pushes into the same branch', (
      tester,
    ) async {
      await pumpDetail(
        tester,
        FakeListingDetailRepository(ad: testAd(), agent: testAgent()),
      );

      await scrollToAndTap(tester, find.text('Javlon Rustamov'));

      // `agent-profile` is a real screen now, so this reads its own
      // arguments rather than a placeholder's name. `branchPrefix` is what
      // proves the push resolved `/home/agent/:id` (the Home branch's own
      // child route) rather than the Agents-tab `/agents/:id`, which would
      // have reset the user out of the tab they were browsing in.
      final profile = tester.widget<AgentProfileScreen>(
        find.byType(AgentProfileScreen),
      );
      expect(profile.agentId, 'agent-javlon');
      expect(profile.branchPrefix, '/home');
      expect(find.byType(ListingDetailScreen), findsNothing);
    });
  });

  // The same guard `test/phone_width_overflow_test.dart` applies to the app
  // shell, aimed at this screen specifically — it is the densest layout in
  // the app (hero caption, four chip lists, a definition list, a two-element
  // floating bar), and several of its rows are built from free text an agent
  // typed rather than from anything length-bounded.
  //
  // It lives here rather than in that file because it needs a controlled ad:
  // the widest row on this screen is the bottom bar, and whether it fits
  // depends on how many digits the price has. Driving the bundled fixtures
  // would test whichever price `ad-1001` happens to carry; this states the
  // hard case (a seven-figure price next to a fixed-copy CTA) outright.
  //
  // This found a real bug on first run — the CTA was inflexible and
  // overflowed the bar by 13px at 360pt. See `listing_detail_bottom_bar.dart`.
  //
  // Note the handler below captures *every* error and restores
  // FlutterError.onError before asserting. The obvious version — forward
  // non-overflow errors to the previous handler, restore in addTearDown —
  // turns any such error into a confusing "test overrode FlutterError.onError"
  // binding assertion followed by a ten-minute suite timeout, with the real
  // cause nowhere in the output. That is exactly what happened here.
  group('layout holds at real phone widths', () {
    const phones = <String, Size>{
      'small android 360x800': Size(360, 800),
      'iphone 14 390x844': Size(390, 844),
      'pro max 430x932': Size(430, 932),
    };

    phones.forEach((label, size) {
      testWidgets('no overflow at $label', (tester) async {
        final overflows = <String>[];
        final others = <String>[];
        final previous = FlutterError.onError;
        // Every error is captured, not just overflows, and onError is
        // restored before the first expect() below. Forwarding the rest to
        // the previous handler instead would file them as pending
        // exceptions that the binding then reports as an unrelated
        // "test overrode FlutterError.onError" assertion, hiding whatever
        // actually went wrong.
        FlutterError.onError = (details) {
          final text = details.exceptionAsString();
          if (text.contains('overflowed')) {
            overflows.add(text.split('\n').first);
          } else {
            others.add(text.split('\n').first);
          }
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = previous;
        });

        // Deliberately maximal: every optional section populated, long free
        // text in the places that take it, so nothing is skipped for being
        // absent and the widest rows actually get laid out.
        await pumpDetail(
          tester,
          FakeListingDetailRepository(
            ad: testAd(
              title:
                  'Exceptionally bright five-room apartment with a garden '
                  'terrace in the Mirzo Ulugbek district',
              district: 'Mirzo Ulugbek',
              price: 1250000,
              rooms: 5,
              area: 140.5,
              storey: 12,
              floors: 17,
              repairment: 'excellent',
              furniture: 'withoutFurniture',
              description: 'A long description. ' * 20,
              nearPlacesList: const [
                'Amir Temur Square metro station (7 minutes on foot)',
                'School #158',
                'Mega Planet shopping centre',
              ],
              optionList: const [
                {'key': 'Parking', 'value': 'Underground, two spaces'},
                {'key': 'Heating', 'value': 'Central'},
              ],
              lat: 41.335,
              lng: 69.32,
            ),
            agent: testAgent(fullName: 'Shahnoza Yoldosheva-Abdullayeva'),
          ),
        );

        // Scroll to the bottom — the agent row, Save the Place button and
        // price footer are below the fold on every phone in this range, so a
        // fold-height-only check would never lay them out at all.
        await tester.drag(find.byType(ListView).first, const Offset(0, -2000));
        await tester.pumpAndSettle();

        FlutterError.onError = previous;

        expect(
          overflows,
          isEmpty,
          reason: 'overflow at $label:\n${overflows.join('\n')}',
        );
        expect(
          others,
          isEmpty,
          reason: 'non-overflow error at $label:\n${others.join('\n')}',
        );
      });
    });
  });

  group('save affordances (SCREENS.md §3.7 role rule)', () {
    testWidgets('both the heart and Save the Place show for a buyer', (
      tester,
    ) async {
      final container = await pumpDetail(
        tester,
        FakeListingDetailRepository(ad: testAd(), agent: testAgent()),
      );
      container.read(authSessionProvider.notifier).setRole(UserRole.user);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('favourite-ad-1001')), findsOneWidget);
      expect(find.text('Save the Place'), findsOneWidget);
    });

    testWidgets('neither shows for an agent', (tester) async {
      final container = await pumpDetail(
        tester,
        FakeListingDetailRepository(ad: testAd(), agent: testAgent()),
      );
      // Browse mode before the role, for the same reason the coworker case
      // below needs it: in the default `WorkspaceMode.work`, `_redirect`
      // bounces an agent off `/home/listing/:id` altogether, and this test
      // would then pass on an empty screen instead of on the role rule.
      container
          .read(workspaceModeProvider.notifier)
          .setMode(WorkspaceMode.browse);
      container.read(authSessionProvider.notifier).setRole(UserRole.agent);
      await tester.pumpAndSettle();

      // The screen is genuinely still here — i.e. the two absences below are
      // the rule firing, not the router having navigated away.
      expect(find.byType(ListingDetailScreen), findsOneWidget);

      expect(find.byKey(const ValueKey('favourite-ad-1001')), findsNothing);
      expect(find.text('Save the Place'), findsNothing);
    });

    testWidgets('both show for a coworker, per the spec\'s literal wording', (
      tester,
    ) async {
      // SCREENS.md §3.7 says `role != "agent"`, which leaves a coworker in
      // — narrower than the rule every listing card follows. Flagged in
      // FavouriteButton's own doc comment, asserted here.
      final container = await pumpDetail(
        tester,
        FakeListingDetailRepository(ad: testAd(), agent: testAgent()),
      );
      // Browse mode first, *then* the role. `_redirect` bounces any
      // agent/coworker session out of a buyer-shell location while
      // `WorkspaceMode.work` (the default) is in force, so a coworker put on
      // `/home/listing/:id` in work mode never reaches this screen at all —
      // the listing detail a coworker can actually open is the browse-shell
      // one, which is the session this rule is about.
      container
          .read(workspaceModeProvider.notifier)
          .setMode(WorkspaceMode.browse);
      container.read(authSessionProvider.notifier).setRole(UserRole.coworker);
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('favourite-ad-1001')), findsOneWidget);
      expect(find.text('Save the Place'), findsOneWidget);
    });

    testWidgets('the two stay in sync because there is one piece of state', (
      tester,
    ) async {
      final container = await pumpDetail(
        tester,
        FakeListingDetailRepository(ad: testAd(), agent: testAgent()),
      );
      container.read(authSessionProvider.notifier).setRole(UserRole.user);
      await tester.pumpAndSettle();

      await scrollToAndTap(tester, find.text('Save the Place'));

      expect(find.text('Saved'), findsOneWidget);
      expect(
        container.read(favouriteAdIdsProvider).contains('ad-1001'),
        isTrue,
      );
    });
  });
}
