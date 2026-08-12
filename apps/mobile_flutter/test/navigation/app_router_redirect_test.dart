// Regression tests for two `app_router.dart` bugs found in the live
// 4-emulator sweep, both about the Work branch's `_redirect`/
// `_AuthRouterRefresh` pairing:
//
// - M5: switching accounts without an app restart used to leak the
//   previous session's pushed Work route into the new one, because the old
//   refresh check only compared `role` — two agent accounts (same role,
//   different person) never tripped it.
// - M7: a hardware/OS Back from a route declared as a direct child of
//   `/work` (`edit-listing/:id`, `publish-status/:id`) used to strand the
//   user on the permanently blank `/work` placeholder, because that pop
//   bypasses go_router's `redirect` pipeline entirely.
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
import 'package:lacasa_mobile/features/home/home.dart';
import 'package:lacasa_mobile/features/listing_editor/listing_editor.dart';
import 'package:lacasa_mobile/features/work_dashboard/work_dashboard.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/app_router.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

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
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = await pumpApp(tester, container: container);

      container.read(authSessionProvider.notifier).signIn(
        _agentUser(id: 'agent-a'),
      );
      await tester.pumpAndSettle();

      // Agent A drills into a coworker's detail page.
      router.go('${RoutePaths.work}/coworkers/coworker-sardor');
      await tester.pumpAndSettle();
      expect(find.byType(CoworkerDetailScreen), findsOneWidget);

      // Leave the Work tab — as the repro does — before switching accounts,
      // so the stale route lives only in the Work branch's own remembered
      // state, not in the location currently on screen. This is the harder
      // of the two paths `_AuthRouterRefresh`'s `_workBranchNeedsReset` flag
      // exists for: an immediate `refresh()` while still on `/work/...`
      // would have caught this on its own; a flag that survives until the
      // branch is re-entered later would not.
      await tester.tap(find.byKey(const ValueKey('navTab-0')));
      await tester.pumpAndSettle();
      expect(find.byType(HomeFeedScreen), findsOneWidget);

      // A different agent signs in — same role (UserRole.agent), different
      // id/session. This is exactly the case the old role-only refresh
      // check missed: `previous.role == next.role` for both accounts.
      container.read(authSessionProvider.notifier).signIn(
        _agentUser(id: 'agent-b'),
      );
      await tester.pumpAndSettle();

      // Tapping back into the Work tab must land agent B on the correct
      // role-based initial screen, never on agent A's pushed coworker.
      await tester.tap(find.byKey(const ValueKey('navTab-2')));
      await tester.pumpAndSettle();

      expect(find.byType(CoworkerDetailScreen), findsNothing);
      expect(find.byType(DashboardScreen), findsOneWidget);
    },
  );

  testWidgets(
    'M7: a hardware Back from a route parented directly on the Work '
    'placeholder bounces onward instead of stranding on a blank screen',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      final router = await pumpApp(tester, container: container);

      container.read(authSessionProvider.notifier).signIn(
        _agentUser(id: 'agent-a'),
      );
      await tester.pumpAndSettle();

      // `publish-status/:id` is a direct child of `/work` (a sibling of
      // `dashboard`/`my-listings`/…), so its Navigator stack parent is the
      // `/work` placeholder itself — exactly the M7 setup.
      router.go('${RoutePaths.work}/publish-status/ad-1001');
      await tester.pumpAndSettle();
      expect(find.byType(PublishStatusScreen), findsOneWidget);

      // Simulate a real hardware/OS Back press — NOT the screen's own
      // in-app back arrow, which already calls `context.pop()`/`context.go`
      // and was never broken. `handlePopRoute` is what actually reproduces
      // M7: go_router's `GoRouterDelegate.popRoute()` calls
      // `NavigatorState.maybePop()` on the branch Navigator directly,
      // bypassing `GoRouter.pop()`'s own `restore()` call and therefore
      // `redirect` entirely.
      final popped = await tester.binding.handlePopRoute();
      expect(popped, isTrue);
      await tester.pumpAndSettle();

      // Before the fix this would still be the blank `/work` placeholder
      // (`PlaceholderScreen` with name "Work") forever, with a second Back
      // exiting the app. After the fix it must have bounced onward to the
      // agent's real initial Work screen.
      expect(find.byType(PublishStatusScreen), findsNothing);
      expect(find.byType(DashboardScreen), findsOneWidget);
    },
  );
}
