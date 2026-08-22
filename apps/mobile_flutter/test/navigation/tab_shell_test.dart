// Proves SCREENS.md §5's "each tab keeps its own back stack" clause: a
// route pushed inside one branch must still be there after switching away
// to another tab and back — StatefulShellRoute.indexedStack's job, wired
// up in lib/navigation/app_router.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/coworkers/coworkers.dart';
import 'package:lacasa_mobile/features/home/home.dart';
import 'package:lacasa_mobile/features/leads/leads.dart';
import 'package:lacasa_mobile/features/listing_detail/listing_detail.dart';
import 'package:lacasa_mobile/features/my_listings/my_listings.dart';
import 'package:lacasa_mobile/features/search/search.dart';
import 'package:lacasa_mobile/features/work_dashboard/work_dashboard.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/app_router.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/navigation/workspace_mode.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/ambient_repository_overrides.dart';

void main() {
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    ProviderContainer? container,
  }) async {
    final c =
        container ?? ProviderContainer(overrides: ambientRepositoryOverrides());
    addTearDown(c.dispose);
    final router = c.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
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

  testWidgets('a pushed route survives switching tabs away and back', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    // Starts on the Home tab root.
    expect(find.byType(HomeFeedScreen), findsOneWidget);

    // Push a detail route within the Home branch (not a tab switch).
    router.push('/home/listing/ad-1001');
    await tester.pumpAndSettle();
    expect(find.byType(ListingDetailScreen), findsOneWidget);
    expect(find.byType(HomeFeedScreen), findsNothing);

    // Switch to the Search tab via the real tab bar button.
    await tester.tap(find.byKey(const ValueKey('navTab-1')));
    await tester.pumpAndSettle();
    // Was `screen-Search` (the PlaceholderScreen key) until /search started
    // rendering the real screen — same assertion, now against the widget
    // type rather than a placeholder's debug key.
    expect(find.byType(SearchScreen), findsOneWidget);
    // The Home branch's IndexedStack entry is offstage, not disposed, but
    // it should no longer be the visible screen.
    expect(find.byType(ListingDetailScreen), findsNothing);

    // Switch back to Home.
    await tester.tap(find.byKey(const ValueKey('navTab-0')));
    await tester.pumpAndSettle();

    // The pushed detail screen is still there — Home's back stack was
    // preserved across the round trip, not reset to its tab root.
    expect(find.byType(ListingDetailScreen), findsOneWidget);
    expect(find.byType(HomeFeedScreen), findsNothing);
  });

  testWidgets('tapping the current tab again resets that branch to its root', (
    tester,
  ) async {
    final router = await pumpApp(tester);

    router.push('/home/listing/ad-1001');
    await tester.pumpAndSettle();
    expect(find.byType(ListingDetailScreen), findsOneWidget);

    // Home is already the current branch — tapping it again is the
    // "initialLocation" case: pop back to the branch's root.
    await tester.tap(find.byKey(const ValueKey('navTab-0')));
    await tester.pumpAndSettle();

    expect(find.byType(HomeFeedScreen), findsOneWidget);
    expect(find.byType(ListingDetailScreen), findsNothing);
  });

  testWidgets(
    'a signed-out session gets the 4-tab buyer shell, and becoming an agent '
    'swaps the whole shell for the 5-tab agent one — no restart',
    (tester) async {
      final container = ProviderContainer(
        overrides: ambientRepositoryOverrides(),
      );
      addTearDown(container.dispose);
      await pumpApp(tester, container: container);

      // Buyer shell: exactly four tabs, and Home is what tab 0 shows.
      expect(find.byKey(const ValueKey('navTab-3')), findsOneWidget);
      expect(find.byKey(const ValueKey('navTab-4')), findsNothing);
      expect(find.byType(HomeFeedScreen), findsOneWidget);

      // Flip role to agent with no navigation and no restart. The default
      // workspace mode is `work`, so `_redirect` moves the session into the
      // agent shell on its own — this is the whole two-shell mechanism.
      container.read(authSessionProvider.notifier).setRole(UserRole.agent);
      await tester.pumpAndSettle();

      // Agent shell: five tabs, dashboard first, and no Home anywhere.
      expect(find.byKey(const ValueKey('navTab-4')), findsOneWidget);
      expect(find.byType(DashboardScreen), findsOneWidget);
      expect(find.byType(HomeFeedScreen), findsNothing);
    },
  );

  testWidgets('/work redirects a signed-out session to /home', (tester) async {
    final router = await pumpApp(tester);

    router.go('/work');
    await tester.pumpAndSettle();

    expect(find.byType(HomeFeedScreen), findsOneWidget);
  });

  testWidgets(
    'the agent shell keeps its own per-branch back stacks, same as the buyer '
    'one',
    (tester) async {
      final container = ProviderContainer(
        overrides: ambientRepositoryOverrides(),
      );
      addTearDown(container.dispose);
      final router = await pumpApp(tester, container: container);

      container.read(authSessionProvider.notifier).setRole(UserRole.agent);
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Drill into the Coworkers branch, leave for Leads, come back. `go`,
      // not `push`, matching `WORK_TAB_CONTRACT.md` §2.2's rule for
      // `coworker-detail` (and what `coworker_statistics_section.dart`
      // actually calls).
      router.go(
        RoutePaths.workCoworkerDetail.replaceFirst(':id', 'coworker-1'),
      );
      await tester.pumpAndSettle();
      expect(find.byType(CoworkerDetailScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('navTab-2')));
      await tester.pumpAndSettle();
      expect(find.byType(LeadsListScreen), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('navTab-3')));
      await tester.pumpAndSettle();
      expect(find.byType(CoworkerDetailScreen), findsOneWidget);
    },
  );

  testWidgets(
    'the Browse switch moves an agent into the buyer shell, and back',
    (tester) async {
      final container = ProviderContainer(
        overrides: ambientRepositoryOverrides(),
      );
      addTearDown(container.dispose);
      await pumpApp(tester, container: container);

      container.read(authSessionProvider.notifier).setRole(UserRole.agent);
      await tester.pumpAndSettle();
      expect(find.byType(DashboardScreen), findsOneWidget);

      // Setting the mode is the entire gesture — `_AuthRouterRefresh`
      // listens to this provider and the redirect swaps the shell.
      container
          .read(workspaceModeProvider.notifier)
          .setMode(WorkspaceMode.browse);
      await tester.pumpAndSettle();

      expect(find.byType(HomeFeedScreen), findsOneWidget);
      expect(find.byType(DashboardScreen), findsNothing);
      // Four tabs again, the buyer set.
      expect(find.byKey(const ValueKey('navTab-4')), findsNothing);

      container.read(workspaceModeProvider.notifier).setMode(WorkspaceMode.work);
      await tester.pumpAndSettle();

      expect(find.byType(DashboardScreen), findsOneWidget);
    },
  );

  testWidgets('a coworker in work mode lands on my-listings, not the dashboard', (
    tester,
  ) async {
    final container = ProviderContainer(
      overrides: ambientRepositoryOverrides(),
    );
    addTearDown(container.dispose);
    await pumpApp(tester, container: container);

    container.read(authSessionProvider.notifier).setRole(UserRole.coworker);
    await tester.pumpAndSettle();

    expect(find.byType(MyListingsScreen), findsOneWidget);
    expect(find.byType(DashboardScreen), findsNothing);
  });
}
