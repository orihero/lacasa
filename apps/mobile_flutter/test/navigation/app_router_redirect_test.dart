// Regression tests for two `app_router.dart` bugs found in the live
// 4-emulator sweep, both about the Work branch's `_redirect`/
// `_AuthRouterRefresh` pairing:
//
// - M5: switching accounts without an app restart used to leak the
//   previous session's pushed Work route into the new one, because the old
//   refresh check only compared `role` — two agent accounts (same role,
//   different person) never tripped it.
// - M7: a hardware/OS Back out of `edit-listing/:id`/`publish-status/:id`
//   used to strand the user on a permanently blank `/work` placeholder,
//   because both were declared as direct children of `/work` and that pop
//   bypasses go_router's `redirect` pipeline entirely. The first answer was
//   a self-correcting placeholder widget; the structural one, pinned here,
//   is that both routes are declared under `my-listings` — the row they are
//   opened from — so the pop lands on a real screen with the agent's
//   filters and paged scroll position still on it, and no placeholder is
//   ever in that stack to begin with.
//
// Both need the *real* `goRouterProvider` (not a scoped stub router, the
// way most per-feature screen tests use) — the bug lives in the shared
// route tree/redirect logic itself, not in any one screen. Same reasoning
// `tab_shell_test.dart` and `sheet_occlusion_test.dart` already use.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/coworkers/coworkers.dart';
import 'package:lacasa_mobile/features/listing_editor/listing_editor.dart';
import 'package:lacasa_mobile/features/my_listings/my_listings.dart';
import 'package:lacasa_mobile/features/work_dashboard/work_dashboard.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/app_router.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/placeholder_screen.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/ambient_repository_overrides.dart';

/// Same wire-shaped builder `test/features/my_listings/support/
/// my_listings_test_data.dart` uses — duplicated locally rather than
/// imported cross-feature, matching this codebase's own per-feature test
/// fixture convention.
AuthUser _agentUser({required String id, String fullName = 'Test Agent'}) {
  return AuthUser.fromJson({
    'id': id,
    'fullName': fullName,
    'email': '$id@lacasa.uz',
    'role': 'agent',
    'phoneNumber': null,
    'avatar': null,
    'agentId': null,
    'tgChatIds': <int>[],
    'igAccounts': <Map<String, dynamic>>[],
    'igAssistConsentAt': null,
    'realtor': null,
  });
}

void main() {
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    required ProviderContainer container,
  }) async {
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
    return router;
  }

  testWidgets(
    'M5: switching to a different same-role account discards the previous '
    "session's pushed Work route",
    (tester) async {
      // Building the real router mounts the whole app shell, which touches
      // nearly every repository — all of them live/networked by default now.
      // Every flag stays on: this file drives sessions straight through
      // `authSessionProvider.notifier.signIn`, never through
      // `AuthRepository`, and `hasPersistedAuthTokenProvider` defaults to
      // `false`, so no startup restore consults it either. Redirect
      // behaviour is what's under test; repository *content* is not, so the
      // empty ambient repositories are exactly right here.
      final container = ProviderContainer(
        overrides: [...ambientRepositoryOverrides()],
      );
      addTearDown(container.dispose);
      final router = await pumpApp(tester, container: container);

      container.read(authSessionProvider.notifier).signIn(
        _agentUser(id: 'agent-a'),
      );
      await tester.pumpAndSettle();

      // Agent A drills into a coworker's detail page (agent-shell branch 3).
      router.go(
        RoutePaths.workCoworkerDetail.replaceFirst(':id', 'coworker-sardor'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CoworkerDetailScreen), findsOneWidget);

      // Leave that tab — as the repro does — before switching accounts, so
      // the stale route lives only in the Coworkers branch's own remembered
      // state, not in the location currently on screen. This is the harder
      // of the two paths `_AuthRouterRefresh`'s stale-branch bookkeeping
      // exists for: an immediate `refresh()` while still on
      // `/work/coworkers/...` would have caught this on its own; a design
      // that only resets the branch that happens to be on screen would not.
      await tester.tap(find.byKey(const ValueKey('navTab-0')));
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);

      // A different agent signs in — same role (UserRole.agent), different
      // id/session. This is exactly the case the old role-only refresh
      // check missed: `previous.role == next.role` for both accounts.
      container.read(authSessionProvider.notifier).signIn(
        _agentUser(id: 'agent-b'),
      );
      await tester.pumpAndSettle();

      // Tapping back into Coworkers must land agent B on that branch's own
      // root, never on agent A's pushed coworker.
      await tester.tap(find.byKey(const ValueKey('navTab-3')));
      await tester.pumpAndSettle();

      expect(find.byType(CoworkerDetailScreen), findsNothing);
      expect(find.byType(CoworkersListScreen), findsOneWidget);
    },
  );

  group('M7: the listing editor is parented on my-listings, not on /work', () {
    /// Signs an agent in and puts the agent shell on My Ads, the screen
    /// every entry into the editor is supposed to come back to.
    ///
    /// Building the real router mounts a whole shell, which touches nearly
    /// every repository — all of them live/networked by default now. Every
    /// ambient flag stays on: this file drives sessions straight through
    /// `authSessionProvider.notifier.signIn`, never through
    /// `AuthRepository`. Route *shape* is what's under test; repository
    /// content is not, so the empty ambient repositories are exactly right.
    Future<GoRouter> pumpOnMyListings(WidgetTester tester) async {
      final container = ProviderContainer(
        overrides: [...ambientRepositoryOverrides()],
      );
      addTearDown(container.dispose);
      final router = await pumpApp(tester, container: container);

      container.read(authSessionProvider.notifier).signIn(
        _agentUser(id: 'agent-a'),
      );
      await tester.pumpAndSettle();

      router.go(RoutePaths.workMyListings);
      await tester.pumpAndSettle();
      expect(find.byType(MyListingsScreen), findsOneWidget);
      return router;
    }

    testWidgets(
      'Back out of edit-listing returns to the same My Ads screen, still '
      'mounted',
      (tester) async {
        final router = await pumpOnMyListings(tester);
        // The identity of the `State` object is the assertion that matters:
        // `push` leaves this exact screen — its applied filters, its paged
        // scroll position — sitting under the editor, where the old
        // `context.go` disposed it and rebuilt a fresh one (if it came
        // back at all).
        final before = tester.state<State>(find.byType(MyListingsScreen));

        router.push(RoutePaths.workEditListing.replaceFirst(':id', 'ad-1001'));
        await tester.pumpAndSettle();
        expect(find.byType(EditListingScreen), findsOneWidget);

        // A real hardware/OS Back press — NOT the screen's own in-app back
        // arrow, which calls `context.pop()` and was never broken.
        // `handlePopRoute` is what reproduces M7: go_router's
        // `GoRouterDelegate.popRoute()` calls `NavigatorState.maybePop()` on
        // the branch Navigator directly, bypassing `GoRouter.pop()`'s own
        // `restore()` call and therefore `redirect` entirely.
        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();

        expect(find.byType(EditListingScreen), findsNothing);
        expect(find.byType(MyListingsScreen), findsOneWidget);
        expect(tester.state<State>(find.byType(MyListingsScreen)), same(before));
        // Never the blank page M7 stranded on, and never its bounce onward
        // to Statistics.
        expect(find.byType(PlaceholderScreen), findsNothing);
        expect(find.byType(DashboardScreen), findsNothing);
      },
    );

    testWidgets(
      "a cross-branch `go` to the editor — notifications' sold row — still "
      'resolves onto a My Ads stack',
      (tester) async {
        final container = ProviderContainer(
          overrides: [...ambientRepositoryOverrides()],
        );
        addTearDown(container.dispose);
        final router = await pumpApp(tester, container: container);

        container.read(authSessionProvider.notifier).signIn(
          _agentUser(id: 'agent-a'),
        );
        await tester.pumpAndSettle();

        // `notifications_screen.dart`'s `_handleTap` does exactly this: an
        // absolute-path `go`, per build contract §2.2, from whichever
        // branch the bell was tapped in.
        router.go(RoutePaths.workEditListing.replaceFirst(':id', 'ad-1005'));
        await tester.pumpAndSettle();
        expect(find.byType(EditListingScreen), findsOneWidget);

        expect(await tester.binding.handlePopRoute(), isTrue);
        await tester.pumpAndSettle();

        // Nesting is what makes this work: `go` builds the *whole* matched
        // stack, so My Ads is underneath even though nobody pushed it.
        expect(find.byType(MyListingsScreen), findsOneWidget);
        expect(find.byType(EditListingScreen), findsNothing);
      },
    );

    testWidgets('publish-status lands on the same My Ads stack', (
      tester,
    ) async {
      final router = await pumpOnMyListings(tester);

      router.push(
        RoutePaths.workPublishStatus.replaceFirst(':id', 'ad-1001'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(PublishStatusScreen), findsOneWidget);

      expect(await tester.binding.handlePopRoute(), isTrue);
      await tester.pumpAndSettle();

      expect(find.byType(PublishStatusScreen), findsNothing);
      expect(find.byType(MyListingsScreen), findsOneWidget);
      expect(find.byType(PlaceholderScreen), findsNothing);
      expect(find.byType(DashboardScreen), findsNothing);
    });
  });
}
