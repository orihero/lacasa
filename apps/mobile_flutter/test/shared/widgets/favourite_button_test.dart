// Covers three things this widget owns:
//
// 1. The [hideForCoworker] override it grew on promotion out of
//    features/home, which lets `listing-detail` follow SCREENS.md §3.7's
//    literal "shown only if role != 'agent'" text (leaving the heart visible
//    for a coworker) without changing the default rule every card-shaped
//    caller (Home's rails, search results) still relies on — hidden for both
//    agent and coworker.
// 2. The signed-out path. The heart is visible to a signed-out visitor by
//    design, and used to flip optimistically, POST with no token, revert on
//    the 401 and report "Couldn't update favourites" — copy that blames the
//    network for a missing account. It must now check the session *before*
//    the flip and invite the visitor to sign in instead.
// 3. The 48dp hit box, asserted as a size rather than trusted from a code
//    read, since the painted chip stays at its 34dp mockup size and the two
//    numbers are exactly the thing that can silently drift apart.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/fake_favourite_ad_ids_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  const heartKey = ValueKey('favourite-ad-1');

  /// Pumped behind a real router (rather than a bare [MaterialApp]) because
  /// the signed-out prompt's action pushes `/login`, and a fake callback
  /// seam would prove nothing about the destination actually resolving.
  Future<ProviderContainer> pump(
    WidgetTester tester, {
    required UserRole? role,
    bool hideForCoworker = true,
    FakeFavouriteAdIdsRepository? favouritesRepository,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        favouriteAdIdsRepositoryProvider.overrideWithValue(
          favouritesRepository ?? FakeFavouriteAdIdsRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).setRole(role);

    final router = GoRouter(
      initialLocation: '/',
      routes: [
        GoRoute(
          path: '/',
          builder: (context, state) => Scaffold(
            body: FavouriteButton(
              adId: 'ad-1',
              hideForCoworker: hideForCoworker,
            ),
          ),
        ),
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) =>
              const Scaffold(body: Text('login-screen')),
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
    await tester.pumpAndSettle();
    return container;
  }

  group('role gating', () {
    testWidgets('default hides for an agent session', (tester) async {
      await pump(tester, role: UserRole.agent);
      expect(find.byKey(heartKey), findsNothing);
    });

    testWidgets('default hides for a coworker session', (tester) async {
      await pump(tester, role: UserRole.coworker);
      expect(find.byKey(heartKey), findsNothing);
    });

    testWidgets('hideForCoworker: false still hides for an agent session', (
      tester,
    ) async {
      await pump(tester, role: UserRole.agent, hideForCoworker: false);
      expect(find.byKey(heartKey), findsNothing);
    });

    testWidgets(
      'hideForCoworker: false shows for a coworker session (SCREENS.md §3.7)',
      (tester) async {
        await pump(tester, role: UserRole.coworker, hideForCoworker: false);
        expect(find.byKey(heartKey), findsOneWidget);
      },
    );

    testWidgets('visible for a buyer session regardless of the flag', (
      tester,
    ) async {
      await pump(tester, role: UserRole.user);
      expect(find.byKey(heartKey), findsOneWidget);
    });
  });

  group('tap target', () {
    testWidgets('the hit box is 48dp while the chip stays at its size', (
      tester,
    ) async {
      await pump(tester, role: UserRole.user);

      expect(tester.getSize(find.byKey(heartKey)), const Size(48, 48));
      // The default `size: 34` chip — the mockup's `.fav`, unchanged.
      expect(
        tester.getSize(
          find.descendant(
            of: find.byKey(heartKey),
            matching: find.byType(GlassSurface),
          ),
        ),
        const Size(34, 34),
      );
    });

    testWidgets('a tap 20dp off centre still toggles', (tester) async {
      final repo = FakeFavouriteAdIdsRepository();
      final container = await pump(
        tester,
        role: UserRole.user,
        favouritesRepository: repo,
      );

      // Outside the 34dp chip's 17dp half-extent, inside the 48dp box's
      // 24dp one: the miss that used to open the listing underneath.
      await tester.tapAt(
        tester.getCenter(find.byKey(heartKey)) + const Offset(20, 0),
      );
      await tester.pumpAndSettle();

      expect(repo.saveCallCount, 1);
      expect(container.read(favouriteAdIdsProvider).contains('ad-1'), isTrue);
    });

    testWidgets('the label names the outcome of the tap, both ways', (
      tester,
    ) async {
      // Disposed inline at the end of the body, not via addTearDown:
      // `WidgetTester._endOfTestVerifications` asserts every SemanticsHandle
      // is already released, and it runs inside the test body — before any
      // tearDown the test package registered.
      final handle = tester.ensureSemantics();

      await pump(
        tester,
        role: UserRole.user,
        favouritesRepository: FakeFavouriteAdIdsRepository(
          savedAdIds: const {'ad-1'},
        ),
      );

      expect(
        tester.getSemantics(find.byKey(heartKey)),
        isSemantics(label: 'Remove from favourites', isButton: true),
      );

      await tester.tap(find.byKey(heartKey));
      await tester.pumpAndSettle();

      expect(
        tester.getSemantics(find.byKey(heartKey)),
        isSemantics(label: 'Add to favourites', isButton: true),
      );

      handle.dispose();
    });
  });

  group('signed out', () {
    testWidgets('the heart is still shown — saving is what needs the account', (
      tester,
    ) async {
      await pump(tester, role: null);
      expect(find.byKey(heartKey), findsOneWidget);
    });

    testWidgets('tapping neither flips the heart nor calls the repository', (
      tester,
    ) async {
      final repo = FakeFavouriteAdIdsRepository();
      final container = await pump(
        tester,
        role: null,
        favouritesRepository: repo,
      );

      await tester.tap(find.byKey(heartKey));
      await tester.pumpAndSettle();

      expect(repo.saveCallCount, 0);
      expect(container.read(favouriteAdIdsProvider).contains('ad-1'), isFalse);
      // The optimistic flip never happened, so the outline heart is still
      // the one on screen — no fill-then-revert flicker.
      expect(
        find.descendant(
          of: find.byKey(heartKey),
          matching: find.byIcon(Icons.favorite_border_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets('tapping invites the visitor to sign in, and does not blame '
        'the network', (tester) async {
      await pump(tester, role: null);

      await tester.tap(find.byKey(heartKey));
      await tester.pumpAndSettle();

      expect(find.text('Sign in to save listings'), findsOneWidget);
      expect(find.text("Couldn't update favourites"), findsNothing);
      expect(find.widgetWithText(SnackBarAction, 'Sign in'), findsOneWidget);
    });

    testWidgets('the prompt is the themed floating toast, not a bare bar', (
      tester,
    ) async {
      await pump(tester, role: null);

      await tester.tap(find.byKey(heartKey));
      await tester.pumpAndSettle();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.backgroundColor, LaCasaColors.light.card);
      // Neutral, not the red error glyph: nothing failed here.
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byIcon(Icons.info_outline_rounded),
        ),
        findsOneWidget,
      );
    });

    testWidgets("the prompt's action opens the login screen", (tester) async {
      await pump(tester, role: null);

      await tester.tap(find.byKey(heartKey));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('login-screen'), findsOneWidget);
    });
  });

  group('signed in, request fails', () {
    testWidgets('reverts the flip and shows the themed error toast', (
      tester,
    ) async {
      final repo = FakeFavouriteAdIdsRepository(
        saveError: const NetworkException('offline'),
      );
      final container = await pump(
        tester,
        role: UserRole.user,
        favouritesRepository: repo,
      );

      await tester.tap(find.byKey(heartKey));
      await tester.pumpAndSettle();

      expect(repo.saveCallCount, 1);
      expect(container.read(favouriteAdIdsProvider).contains('ad-1'), isFalse);
      expect(find.text("Couldn't update favourites"), findsOneWidget);
      // Still the shared toast, not Material's docked default.
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(snackBar.backgroundColor, LaCasaColors.light.card);
    });
  });
}
