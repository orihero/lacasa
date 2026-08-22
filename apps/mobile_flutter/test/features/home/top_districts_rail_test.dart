// Widget tests for Home's Top Districts rail
// (lib/features/home/widgets/top_districts_rail.dart).
//
// The rail used to be four hardcoded names on invented gradients, so there
// was nothing here to test. It is now derived from the browse feed
// (state/top_districts_provider.dart), which means it has the same
// loading/error/empty obligations as its sibling rails plus one of its own:
// a "ranking" of a single district is not a ranking, so it hides.
//
// The pumps below use MaterialApp.router rather than a plain MaterialApp
// because a tile's tap both writes appliedSearchFiltersProvider and calls
// context.go(RoutePaths.search) — without a GoRouter ancestor the second
// half throws and the first can't be observed.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/home/data/home_feed_repository.dart';
import 'package:lacasa_mobile/features/home/state/home_feed_repository_provider.dart';
import 'package:lacasa_mobile/features/home/widgets/top_districts_rail.dart';
import 'package:lacasa_mobile/features/search/state/search_providers.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../support/ambient_repository_overrides.dart';
import 'support/fake_home_feed_repository.dart';

Ad _ad({required String id, required String district}) {
  return Ad.fromJson({
    'id': id,
    'title': 'Listing $id',
    'city': 'Toshkent',
    'district': district,
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
  });
}

/// A feed whose [fetchFeed] never completes on its own — the only way to
/// hold the rail in its loading state, since [FakeHomeFeedRepository]
/// resolves within the same microtask drain as `pumpWidget`.
class _PendingHomeFeedRepository implements HomeFeedRepository {
  final completer = Completer<List<Ad>>();

  @override
  Future<List<Ad>> fetchFeed({AdFilters filters = const AdFilters()}) =>
      completer.future;

  @override
  Future<List<AgentSummary>> fetchTopAgents() async => const [];
}

void main() {
  Future<ProviderContainer> pumpRail(
    WidgetTester tester,
    HomeFeedRepository repository, {
    bool settle = true,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        ...ambientRepositoryOverrides(homeFeed: false),
        homeFeedRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) =>
              const Scaffold(body: SafeArea(child: TopDistrictsRail())),
        ),
        GoRoute(
          path: RoutePaths.search,
          builder: (context, state) =>
              const Scaffold(body: Text('search-tab-root')),
        ),
      ],
    );
    addTearDown(router.dispose);

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
    if (settle) await tester.pumpAndSettle();
    return container;
  }

  group('data', () {
    testWidgets(
      'ranks districts by how many feed listings carry them, and states the count',
      (tester) async {
        // Mirobod 3, Chilonzor 2, Yunusobod 1 — deliberately not the order
        // the ads arrive in, so a rail that merely preserved feed order
        // would fail this.
        final repo = FakeHomeFeedRepository(
          ads: [
            _ad(id: 'a1', district: 'Chilonzor tumani'),
            _ad(id: 'a2', district: 'Mirobod tumani'),
            _ad(id: 'a3', district: 'Yunusobod tumani'),
            _ad(id: 'a4', district: 'Mirobod tumani'),
            _ad(id: 'a5', district: 'Chilonzor tumani'),
            _ad(id: 'a6', district: 'Mirobod tumani'),
            // Free text server-side, so a blank district is reachable and
            // must not become a tile of its own.
            _ad(id: 'a7', district: '   '),
          ],
        );

        await pumpRail(tester, repo);

        expect(find.text('Top Districts'), findsOneWidget);
        expect(find.text('Mirobod tumani'), findsOneWidget);
        expect(find.text('3 listings'), findsOneWidget);
        expect(find.text('Chilonzor tumani'), findsOneWidget);
        expect(find.text('2 listings'), findsOneWidget);
        // The ICU plural's singular branch, not "1 listings".
        expect(find.text('Yunusobod tumani'), findsOneWidget);
        expect(find.text('1 listing'), findsOneWidget);

        // Exactly three tiles — the blank district is not one of them.
        expect(find.byType(GlassSurface), findsNWidgets(3));

        // Highest count first.
        final mirobod = tester.getTopLeft(
          find.byKey(const ValueKey('district-Mirobod tumani')),
        );
        final chilonzor = tester.getTopLeft(
          find.byKey(const ValueKey('district-Chilonzor tumani')),
        );
        final yunusobod = tester.getTopLeft(
          find.byKey(const ValueKey('district-Yunusobod tumani')),
        );
        expect(mirobod.dx, lessThan(chilonzor.dx));
        expect(chilonzor.dx, lessThan(yunusobod.dx));
      },
    );

    testWidgets('a tile carries no photo, no scrim and no glass name pill', (
      tester,
    ) async {
      final repo = FakeHomeFeedRepository(
        ads: [
          _ad(id: 'a1', district: 'Chilonzor tumani'),
          _ad(id: 'a2', district: 'Mirobod tumani'),
        ],
      );

      await pumpRail(tester, repo);

      // The redesigned tile *is* the glass: one GlassSurface per district,
      // not a gradient box with a second lens floating inside it.
      expect(find.byType(GlassSurface), findsNWidgets(2));
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('district-Chilonzor tumani')),
          matching: find.byType(GlassSurface),
        ),
        findsOneWidget,
      );
      expect(
        tester.getSize(find.byKey(const ValueKey('district-Chilonzor tumani'))),
        const Size(132, 116),
      );
    });

    testWidgets('tapping a tile pre-filters search on that exact district', (
      tester,
    ) async {
      final repo = FakeHomeFeedRepository(
        ads: [
          _ad(id: 'a1', district: 'Chilonzor tumani'),
          _ad(id: 'a2', district: 'Mirobod tumani'),
        ],
      );

      final container = await pumpRail(tester, repo);
      expect(container.read(appliedSearchFiltersProvider).district, isNull);

      await tester.tap(find.byKey(const ValueKey('district-Mirobod tumani')));
      await tester.pumpAndSettle();

      // The verbatim feed string, which is what GET /ads?district= matches
      // on — a regions.json spelling would silently return nothing.
      expect(
        container.read(appliedSearchFiltersProvider).district,
        'Mirobod tumani',
      );
      expect(
        activeFilterCount(container.read(appliedSearchFiltersProvider)),
        1,
      );
      expect(find.text('search-tab-root'), findsOneWidget);
    });
  });

  group('loading', () {
    testWidgets('shows tile-shaped shimmer placeholders, not an empty rail', (
      tester,
    ) async {
      final repo = _PendingHomeFeedRepository();
      addTearDown(() => repo.completer.complete(const []));

      await pumpRail(tester, repo, settle: false);
      await tester.pump();

      expect(find.text('Top Districts'), findsOneWidget);
      expect(find.byType(ShimmerBox), findsNWidgets(3));
      expect(
        tester.getSize(find.byType(ShimmerBox).first),
        const Size(132, 116),
      );
    });
  });

  group('empty and degraded states', () {
    testWidgets('hides the rail and its header when the feed is empty', (
      tester,
    ) async {
      await pumpRail(tester, FakeHomeFeedRepository(ads: const []));

      expect(find.text('Top Districts'), findsNothing);
      expect(find.byType(GlassSurface), findsNothing);
    });

    testWidgets('hides the rail when the feed yields a single district', (
      tester,
    ) async {
      // A one-tile "ranking" is not a ranking — see the widget's doc
      // comment. This is the case that used to be impossible, back when the
      // four names were hardcoded.
      final repo = FakeHomeFeedRepository(
        ads: [
          _ad(id: 'a1', district: 'Chilonzor tumani'),
          _ad(id: 'a2', district: 'Chilonzor tumani'),
        ],
      );

      await pumpRail(tester, repo);

      expect(find.text('Top Districts'), findsNothing);
      expect(find.text('Chilonzor tumani'), findsNothing);
    });

    testWidgets(
      'renders nothing when the feed fails, leaving the one retry card to Featured Listings',
      (tester) async {
        final repo = FakeHomeFeedRepository(
          ads: const [],
          feedError: const NetworkException('offline'),
        );

        await pumpRail(tester, repo);

        expect(find.text('Top Districts'), findsNothing);
        expect(find.byType(RailRetryCard), findsNothing);
        expect(find.text('Retry'), findsNothing);
      },
    );
  });
}
