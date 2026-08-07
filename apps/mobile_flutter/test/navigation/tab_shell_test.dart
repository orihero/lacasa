// Proves SCREENS.md §5's "each tab keeps its own back stack" clause: a
// route pushed inside one branch must still be there after switching away
// to another tab and back — StatefulShellRoute.indexedStack's job, wired
// up in lib/navigation/app_router.dart.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/home/home.dart';
import 'package:lacasa_mobile/features/listing_detail/listing_detail.dart';
import 'package:lacasa_mobile/features/search/search.dart';
import 'package:lacasa_mobile/navigation/app_router.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/theme/theme.dart';

void main() {
  Future<GoRouter> pumpApp(
    WidgetTester tester, {
    ProviderContainer? container,
  }) async {
    final c = container ?? ProviderContainer();
    addTearDown(c.dispose);
    final router = c.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: c,
        child: MaterialApp.router(
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
    'the Work tab is hidden signed out and appears immediately on role change',
    (tester) async {
      final container = ProviderContainer();
      addTearDown(container.dispose);
      await pumpApp(tester, container: container);

      // Signed out: 4 tabs, no Work button in the tree at all.
      expect(find.byKey(const ValueKey('navTab-2')), findsNothing);

      // Flip role to agent with no navigation and no restart.
      container.read(authSessionProvider.notifier).setRole(UserRole.agent);
      await tester.pumpAndSettle();

      // Work tab appears immediately, purely from the ref.watch rebuild.
      expect(find.byKey(const ValueKey('navTab-2')), findsOneWidget);
    },
  );

  testWidgets('/work redirects a signed-out session to /home', (tester) async {
    final router = await pumpApp(tester);

    router.go('/work');
    await tester.pumpAndSettle();

    expect(find.byType(HomeFeedScreen), findsOneWidget);
  });
}
