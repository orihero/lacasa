// Widget tests for `saved-listings` (lib/features/saved_listings/). Pumped
// inside a real GoRouter, not a bare MaterialApp: the header's back control
// branches on `context.canPop()` and a card tap pushes a branch-relative
// listing route, neither of which exists without a router in the tree —
// same reasoning as `test/features/agents/agent_profile_screen_test.dart`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/saved_listings/saved_listings.dart';
import 'package:lacasa_mobile/features/saved_listings/state/saved_listings_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../shared/support/fake_favourite_ad_ids_repository.dart';
import 'support/fake_saved_listings_repository.dart';

Ad savedAd({
  required String id,
  required String title,
  String district = 'Chilonzor',
  num price = 90000,
}) {
  return Ad.fromJson({
    'id': id,
    'title': title,
    'city': 'Tashkent',
    'district': district,
    'address': null,
    'reference': null,
    'type': 'residential',
    'category': 'sale',
    'rooms': 3,
    'area': 72,
    'storey': 4,
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
    'agentId': 'agent-a',
    'coworkerId': '',
    'photos': <String>[],
    'media': <Map<String, dynamic>>[],
    'createdAt': {'seconds': 1700000000},
    'updatedAt': {'seconds': 1700000000},
  });
}

void main() {
  /// Pumps `saved-listings` at `/profile/saved`, with the Profile root as
  /// the route below it so `canPop()` is true — the ordinary case. Stub
  /// routes stand in for `listing-detail` and `login` so a push can be
  /// observed without dragging either whole screen in.
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required FakeSavedListingsRepository repository,
    Set<String>? favouriteAdIds,
    UserRole? role = UserRole.user,
    bool withBackStack = true,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        savedListingsRepositoryProvider.overrideWithValue(repository),
        favouriteAdIdsRepositoryProvider.overrideWithValue(
          FakeFavouriteAdIdsRepository(savedAdIds: favouriteAdIds ?? const {}),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).setRole(role);

    final router = GoRouter(
      initialLocation: RoutePaths.profile,
      routes: [
        GoRoute(
          path: RoutePaths.profile,
          builder: (context, state) =>
              const Scaffold(body: Text('profile-root')),
          routes: [
            GoRoute(
              path: 'listing/:id',
              builder: (context, state) => Scaffold(
                body: Text('listing-stub-${state.pathParameters['id']}'),
              ),
            ),
            GoRoute(
              path: 'saved',
              builder: (context, state) => const SavedListingsScreen(),
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const Scaffold(body: Text('login-stub')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();

    if (withBackStack) {
      router.push('${RoutePaths.profile}/saved');
    } else {
      router.go('${RoutePaths.profile}/saved');
    }
    await tester.pumpAndSettle();

    return container;
  }

  group('header', () {
    testWidgets('shows the §3.17 title', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeSavedListingsRepository(),
      );
      expect(find.text('Saved Listings'), findsOneWidget);
    });

    testWidgets('back pops to the route below', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeSavedListingsRepository(),
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('profile-root'), findsOneWidget);
    });

    testWidgets('a deep link with nothing to pop still leaves via back', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeSavedListingsRepository(),
        withBackStack: false,
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('profile-root'), findsOneWidget);
    });
  });

  group('grid', () {
    testWidgets('renders saved ads as cards', (tester) async {
      final repo = FakeSavedListingsRepository(
        ads: [
          savedAd(id: 'ad-1', title: 'Bright 3-room apartment'),
          savedAd(id: 'ad-2', title: 'Quiet studio near the metro'),
        ],
      );

      await pumpScreen(tester, repository: repo);

      expect(find.text('Bright 3-room apartment'), findsOneWidget);
      expect(find.text('Quiet studio near the metro'), findsOneWidget);
    });

    testWidgets('empty state is §3.17 copy verbatim', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeSavedListingsRepository(ads: const []),
      );

      expect(
        find.text("You haven't saved any listings yet."),
        findsOneWidget,
      );
    });

    testWidgets('a load failure shows Retry and re-fetches', (tester) async {
      final repo = FakeSavedListingsRepository(
        error: const NetworkException('offline'),
      );

      await pumpScreen(tester, repository: repo);

      expect(find.text("Couldn't load your saved listings"), findsOneWidget);
      expect(repo.fetchCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.fetchCallCount, 2);
    });

    testWidgets('tapping a card pushes it into the Profile branch', (
      tester,
    ) async {
      final repo = FakeSavedListingsRepository(
        ads: [savedAd(id: 'ad-1', title: 'Bright 3-room apartment')],
      );

      await pumpScreen(tester, repository: repo);

      await tester.tap(find.byKey(const ValueKey('exploreCard-ad-1')));
      await tester.pumpAndSettle();

      // Resolved from branchPrefix — `/profile/listing/ad-1`.
      expect(find.text('listing-stub-ad-1'), findsOneWidget);
    });

    testWidgets('shows a shimmer skeleton while loading, then settles', (
      tester,
    ) async {
      // Built directly (no GoRouter, no `pumpScreen`'s `pumpAndSettle`):
      // `ShimmerBox` animates continuously while its state is on screen, so
      // settling before `gate` completes would hang — same reasoning as
      // `agent_profile_screen_test.dart`'s identically-shaped loading test.
      final gate = Completer<void>();
      final repo = FakeSavedListingsRepository(hold: gate, ads: const []);

      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          savedListingsRepositoryProvider.overrideWithValue(repo),
          favouriteAdIdsRepositoryProvider.overrideWithValue(
            FakeFavouriteAdIdsRepository(),
          ),
        ],
      );
      addTearDown(container.dispose);
      container.read(authSessionProvider.notifier).setRole(UserRole.user);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const SavedListingsScreen(),
          ),
        ),
      );
      await tester.pump();

      // The title is outside the AsyncValue branch on purpose — a user
      // should know what screen they are on before its content lands.
      expect(find.text('Saved Listings'), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(ShimmerBox), findsNothing);
    });
  });

  group('un-hearting on this screen (SCREENS.md §3.17 — favourites ARE the content)', () {
    testWidgets(
      'un-hearting a card removes it from the grid immediately',
      (tester) async {
        final repo = FakeSavedListingsRepository(
          ads: [
            savedAd(id: 'ad-1', title: 'Bright 3-room apartment'),
            savedAd(id: 'ad-2', title: 'Quiet studio near the metro'),
          ],
        );

        await pumpScreen(
          tester,
          repository: repo,
          favouriteAdIds: {'ad-1', 'ad-2'},
        );

        expect(find.text('Bright 3-room apartment'), findsOneWidget);
        expect(find.text('Quiet studio near the metro'), findsOneWidget);

        await tester.tap(find.byKey(const ValueKey('favourite-ad-1')));
        await tester.pumpAndSettle();

        expect(find.text('Bright 3-room apartment'), findsNothing);
        // The untouched card stays exactly where it was.
        expect(find.text('Quiet studio near the metro'), findsOneWidget);
      },
    );

    testWidgets(
      "a favourite set that hasn't seeded yet doesn't hide freshly-loaded "
      'cards (the race the diff-based pruning avoids)',
      (tester) async {
        // The favourites repository seeds asynchronously; this test asserts
        // the grid still shows both cards once everything settles, i.e. the
        // still-empty-momentarily shared set never gets read as "not
        // actually saved" — see `saved_listings_providers.dart`.
        final repo = FakeSavedListingsRepository(
          ads: [
            savedAd(id: 'ad-1', title: 'Bright 3-room apartment'),
            savedAd(id: 'ad-2', title: 'Quiet studio near the metro'),
          ],
        );

        await pumpScreen(
          tester,
          repository: repo,
          favouriteAdIds: {'ad-1', 'ad-2'},
        );

        expect(find.text('Bright 3-room apartment'), findsOneWidget);
        expect(find.text('Quiet studio near the metro'), findsOneWidget);
      },
    );
  });

  group('signed-out deep link (SCREENS.md §3.17 — only linked from profile-buyer)', () {
    testWidgets('shows a sign-in prompt instead of an empty grid', (
      tester,
    ) async {
      final repo = FakeSavedListingsRepository(
        ads: [savedAd(id: 'ad-1', title: 'Bright 3-room apartment')],
      );

      await pumpScreen(tester, repository: repo, role: null);

      expect(
        find.text('Sign in to see your saved listings.'),
        findsOneWidget,
      );
      expect(find.text("You haven't saved any listings yet."), findsNothing);
      // The gate is before the fetch — a signed-out session never calls the
      // (would-401) endpoint.
      expect(repo.fetchCallCount, 0);
    });

    testWidgets('Sign In opens `login`', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeSavedListingsRepository(),
        role: null,
      );

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('login-stub'), findsOneWidget);
    });
  });

  group('layout holds at real phone widths', () {
    for (final size in const [
      (label: 'small android', size: Size(360, 800)),
      (label: 'iphone 14', size: Size(390, 844)),
      (label: 'pro max', size: Size(430, 932)),
    ]) {
      testWidgets('no overflow at ${size.label}', (tester) async {
        tester.view.physicalSize = size.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpScreen(
          tester,
          repository: FakeSavedListingsRepository(
            ads: [
              savedAd(
                id: 'ad-1',
                title: 'Bright 3-room apartment in Chilonzor with a view',
              ),
              savedAd(id: 'ad-2', title: 'Quiet studio near the metro'),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
      });

      testWidgets('signed-out state has no overflow at ${size.label}', (
        tester,
      ) async {
        tester.view.physicalSize = size.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpScreen(
          tester,
          repository: FakeSavedListingsRepository(),
          role: null,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
