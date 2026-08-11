// Widget tests for `notifications` (SCREENS.md §3.22). Pumped inside a real
// GoRouter — its rows route contextually via `context.go` to absolute Work
// paths (contract §2.2), which does not exist without a router in the tree.
// Same shape as `test/features/settings/settings_screen_test.dart`.
//
// **Cross-feature dependency (contract §3.4).** `notifications` imports
// `showLeadDetailSheet` from `features/leads/leads.dart` (feature D's own
// directory) — the one place in this build where a feature imports another
// feature directly rather than through a route. That dependency has landed,
// so the lead-kind row's own test below exercises the real sheet.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/work_misc/state/notifications_repository_provider.dart';
import 'package:lacasa_mobile/features/work_misc/work_misc.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import 'support/fake_notifications_repository.dart';

void main() {
  /// Pumps `NotificationsScreen` at `/work/notifications`, with the Work
  /// root as the route below it, plus stub routes for every non-sheet tap
  /// target §22 names.
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required FakeNotificationsRepository repository,
    bool withBackStack = true,
    Locale locale = const Locale('en'),
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        notificationsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RoutePaths.work,
      routes: [
        GoRoute(
          path: RoutePaths.work,
          builder: (context, state) => const Scaffold(body: Text('work-root')),
          routes: [
            GoRoute(
              path: 'notifications',
              builder: (context, state) => const NotificationsScreen(),
            ),
            GoRoute(
              path: 'edit-listing/:id',
              builder: (context, state) => Scaffold(
                body: Text('edit-listing-stub-${state.pathParameters['id']}'),
              ),
            ),
            GoRoute(
              path: 'publish-status/:id',
              builder: (context, state) => Scaffold(
                body: Text('publish-status-stub-${state.pathParameters['id']}'),
              ),
            ),
            GoRoute(
              path: 'coworkers/:id',
              builder: (context, state) => Scaffold(
                body: Text('coworker-detail-stub-${state.pathParameters['id']}'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(locale: locale, localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, theme: AppTheme.light(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    if (withBackStack) {
      router.push('${RoutePaths.work}/notifications');
    } else {
      router.go('${RoutePaths.work}/notifications');
    }
    await tester.pumpAndSettle();

    return container;
  }

  group('header', () {
    testWidgets('shows the §3.22 title', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeNotificationsRepository(),
      );
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('back pops to the route below', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeNotificationsRepository(),
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('work-root'), findsOneWidget);
    });

    testWidgets('a deep link with nothing to pop still leaves via back', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeNotificationsRepository(),
        withBackStack: false,
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('work-root'), findsOneWidget);
    });
  });

  group('rows', () {
    testWidgets('empty state is §22 copy verbatim', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeNotificationsRepository(notifications: const []),
      );

      expect(find.text('No notifications yet.'), findsOneWidget);
    });

    testWidgets('shows a shimmer skeleton while loading, then settles', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = FakeNotificationsRepository(hold: gate);

      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [notificationsRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const NotificationsScreen(),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Notifications'), findsOneWidget);
      expect(find.byType(ShimmerBox), findsWidgets);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.byType(ShimmerBox), findsNothing);
    });

    testWidgets('a load failure shows Retry and re-fetches', (tester) async {
      final repo = FakeNotificationsRepository(
        error: const NetworkException('offline'),
      );

      await pumpScreen(tester, repository: repo);

      expect(find.text("Couldn't load your notifications."), findsOneWidget);
      expect(repo.fetchCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.fetchCallCount, 2);
    });

    testWidgets('renders every row with its title and relative time', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeNotificationsRepository(
          notifications: workNotificationsFixture,
        ),
      );

      for (final n in workNotificationsFixture) {
        expect(find.text(n.title), findsOneWidget);
        expect(find.text(n.relativeTime), findsOneWidget);
      }
    });
  });

  group('tap-through (SCREENS.md §22)', () {
    testWidgets('sold -> edit-listing', (tester) async {
      const notification = WorkNotificationFixture(
        id: 'n-sold',
        kind: WorkNotificationKind.sold,
        title: 'Listing sold — Two-room flat in Mirobod marked as Sold',
        relativeTime: 'Yesterday',
        unread: false,
        targetId: 'ad-1005',
      );
      await pumpScreen(
        tester,
        repository: FakeNotificationsRepository(
          notifications: const [notification],
        ),
      );

      await tester.tap(find.text(notification.title));
      await tester.pumpAndSettle();

      expect(find.text('edit-listing-stub-ad-1005'), findsOneWidget);
    });

    testWidgets('publish -> publish-status', (tester) async {
      const notification = WorkNotificationFixture(
        id: 'n-publish',
        kind: WorkNotificationKind.publish,
        title: 'Instagram post published',
        relativeTime: '1 h ago',
        unread: true,
        targetId: 'ad-1001',
      );
      await pumpScreen(
        tester,
        repository: FakeNotificationsRepository(
          notifications: const [notification],
        ),
      );

      await tester.tap(find.text(notification.title));
      await tester.pumpAndSettle();

      expect(find.text('publish-status-stub-ad-1001'), findsOneWidget);
    });

    testWidgets('coworker activity -> coworker-detail', (tester) async {
      const notification = WorkNotificationFixture(
        id: 'n-coworker',
        kind: WorkNotificationKind.coworkerActivity,
        title: 'Coworker added a new listing',
        relativeTime: '2 days ago',
        unread: false,
        targetId: 'coworker-sardor',
      );
      await pumpScreen(
        tester,
        repository: FakeNotificationsRepository(
          notifications: const [notification],
        ),
      );

      await tester.tap(find.text(notification.title));
      await tester.pumpAndSettle();

      expect(find.text('coworker-detail-stub-coworker-sardor'), findsOneWidget);
    });

    testWidgets(
      'lead -> opens the real lead-detail sheet (contract §3.4)',
      (tester) async {
        // `lead-2001` (Dilnoza Yusupova) is a real id in `workLeadsFixtures`
        // — this exercises `leads`' actual `showLeadDetailSheet`, not a
        // stub, since that cross-feature dependency has landed (see this
        // file's header comment).
        const notification = WorkNotificationFixture(
          id: 'n-lead',
          kind: WorkNotificationKind.lead,
          title: 'New lead: Dilnoza Yusupova',
          relativeTime: '2 min ago',
          unread: true,
          targetId: 'lead-2001',
        );
        await pumpScreen(
          tester,
          repository: FakeNotificationsRepository(
            notifications: const [notification],
          ),
        );

        await tester.tap(find.text(notification.title));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
        // The sheet's own close control — unambiguous proof the real
        // `lead-detail` opened, not one of the three route-based targets.
        expect(find.byKey(const ValueKey('leadDetail-close')), findsOneWidget);
        expect(find.text('edit-listing-stub-lead-2001'), findsNothing);
        expect(find.text('publish-status-stub-lead-2001'), findsNothing);
        expect(find.text('coworker-detail-stub-lead-2001'), findsNothing);
      },
    );
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
          repository: FakeNotificationsRepository(
            notifications: workNotificationsFixture,
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

  group('layout holds at real phone widths under ru/uz', () {
    for (final locale in const [Locale('ru'), Locale('uz')]) {
      for (final size in const [
        (label: 'small android', size: Size(360, 800)),
        (label: 'iphone 14', size: Size(390, 844)),
        (label: 'pro max', size: Size(430, 932)),
      ]) {
        testWidgets('no overflow at ${size.label} (${locale.languageCode})', (
          tester,
        ) async {
          tester.view.physicalSize = size.size;
          tester.view.devicePixelRatio = 1.0;
          addTearDown(tester.view.resetPhysicalSize);
          addTearDown(tester.view.resetDevicePixelRatio);

          await pumpScreen(
            tester,
            repository: FakeNotificationsRepository(
              notifications: workNotificationsFixture,
            ),
            locale: locale,
          );

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
