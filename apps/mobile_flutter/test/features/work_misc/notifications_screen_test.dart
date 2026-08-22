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

import '../../support/ambient_repository_overrides.dart';
import 'support/notification_test_data.dart';
import 'package:lacasa_mobile/features/work_misc/data/work_notification.dart';
import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/work_misc/state/notifications_repository_provider.dart';
import 'package:lacasa_mobile/features/work_misc/work_misc.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import 'support/fake_notifications_repository.dart';

void main() {
  /// Pumps `NotificationsScreen` at `/work/notifications`, with the Work
  /// root as the route below it, plus stub routes for every non-sheet tap
  /// target §22 names.
  /// [role] defaults to [UserRole.agent] because `GET /notifications` 403s
  /// for anyone else, and the screen now refuses to subscribe at all
  /// without `canAccessWork` rather than issuing a request it knows will be
  /// forbidden and offering a Retry that can only fail again. Every §22
  /// behaviour below is therefore an agent-session behaviour; the gated
  /// branch has its own test at the end of this file.
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required FakeNotificationsRepository repository,
    bool withBackStack = true,
    Locale locale = const Locale('en'),
    UserRole? role = UserRole.agent,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        ...ambientRepositoryOverrides(notifications: false),
        notificationsRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    if (role != null) {
      container.read(authSessionProvider.notifier).setRole(role);
    }

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
            // Both live under `my-listings` in `app_router.dart`, not on
            // `/work` — a §22 tap is a cross-branch `go` to an absolute
            // path, and nesting is what makes that path resolve to a real
            // stack (`[my-listings, edit-listing]`) instead of a lone page
            // over a blank parent. Mirrored here so the stub tree can't
            // pass on a shape the real one would fail on.
            GoRoute(
              path: 'my-listings',
              builder: (context, state) =>
                  const Scaffold(body: Text('my-listings-stub')),
              routes: [
                GoRoute(
                  path: 'edit-listing/:id',
                  builder: (context, state) => Scaffold(
                    body: Text(
                      'edit-listing-stub-${state.pathParameters['id']}',
                    ),
                  ),
                ),
                GoRoute(
                  path: 'publish-status/:id',
                  builder: (context, state) => Scaffold(
                    body: Text(
                      'publish-status-stub-${state.pathParameters['id']}',
                    ),
                  ),
                ),
              ],
            ),
            GoRoute(
              path: 'coworkers/:id',
              builder: (context, state) => Scaffold(
                body: Text(
                  'coworker-detail-stub-${state.pathParameters['id']}',
                ),
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
        child: MaterialApp.router(
          locale: locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
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
      await pumpScreen(tester, repository: FakeNotificationsRepository());
      expect(find.text('Notifications'), findsOneWidget);
    });

    testWidgets('back pops to the route below', (tester) async {
      await pumpScreen(tester, repository: FakeNotificationsRepository());

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

    testWidgets('Mark all read is hidden when nothing is unread', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeNotificationsRepository(
          notifications: notificationTestRows
              .where((row) => !row.unread)
              .toList(),
        ),
      );

      expect(find.text('Mark all read'), findsNothing);
    });

    testWidgets('Mark all read clears every dot and confirms', (tester) async {
      final repo = FakeNotificationsRepository(
        notifications: notificationTestRows,
      );
      await pumpScreen(tester, repository: repo);

      expect(find.text('Mark all read'), findsOneWidget);

      await tester.tap(find.text('Mark all read'));
      await tester.pumpAndSettle();

      expect(repo.markAllReadCallCount, 1);
      expect(find.text('All notifications marked read'), findsOneWidget);
      // The link retires once there is nothing left to clear.
      expect(find.text('Mark all read'), findsNothing);
      // Every row is still there, just no longer announced as unread.
      expect(find.bySemanticsLabel(RegExp(', unread\$')), findsNothing);
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
        overrides: [
          ...ambientRepositoryOverrides(notifications: false),
          notificationsRepositoryProvider.overrideWithValue(repo),
        ],
      );
      addTearDown(container.dispose);
      // This case builds its own container rather than going through
      // `pumpScreen`, so it has to establish the agent session itself —
      // without it the screen renders the agent-only state and never
      // subscribes, so there is no loading phase to observe.
      container.read(authSessionProvider.notifier).setRole(UserRole.agent);

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

      // A `NetworkException` now resolves through `describeReadError`, so
      // the card names the one fact that explains it — the screen-specific
      // "Couldn't load your notifications." is demoted to the fallback for
      // every other failure, asserted in the case below.
      expect(
        find.text('No connection. Check your network and try again.'),
        findsOneWidget,
      );
      expect(repo.fetchCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.fetchCallCount, 2);
    });

    testWidgets('a non-connectivity failure keeps the screen-specific copy', (
      tester,
    ) async {
      final repo = FakeNotificationsRepository(error: StateError('boom'));

      await pumpScreen(tester, repository: repo);

      expect(find.text("Couldn't load your notifications."), findsOneWidget);
      expect(
        find.text('No connection. Check your network and try again.'),
        findsNothing,
      );
    });

    testWidgets('renders every row with its title and relative time', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeNotificationsRepository(
          notifications: notificationTestRows,
        ),
      );

      // Each seed title is a fused "headline — detail" sentence, which the
      // row splits into the mockup's two type roles (`.lrow__t` over
      // `.lrow__s`), so the headline half is what is on screen as one Text.
      for (final n in notificationTestRows) {
        expect(find.text(_headline(n.title)), findsOneWidget);
        expect(find.text(n.relativeTime), findsOneWidget);
      }
    });
  });

  group('tap-through (SCREENS.md §22)', () {
    testWidgets('sold -> edit-listing', (tester) async {
      const notification = WorkNotification(
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

      await tester.tap(find.text(_headline(notification.title)));
      await tester.pumpAndSettle();

      expect(find.text('edit-listing-stub-ad-1005'), findsOneWidget);
    });

    testWidgets('publish -> publish-status', (tester) async {
      const notification = WorkNotification(
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

      await tester.tap(find.text(_headline(notification.title)));
      await tester.pumpAndSettle();

      expect(find.text('publish-status-stub-ad-1001'), findsOneWidget);
    });

    testWidgets('coworker activity -> coworker-detail', (tester) async {
      const notification = WorkNotification(
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

      await tester.tap(find.text(_headline(notification.title)));
      await tester.pumpAndSettle();

      expect(find.text('coworker-detail-stub-coworker-sardor'), findsOneWidget);
    });

    testWidgets('lead -> opens the real lead-detail sheet (contract §3.4)', (
      tester,
    ) async {
      // This exercises `leads`' actual `showLeadDetailSheet`, not a stub,
      // since that cross-feature dependency has landed (see this file's
      // header comment). The lead itself is resolved through the ambient
      // (inert) leads repository, so the sheet renders its loaded form for
      // an empty lead — enough to prove the real sheet opened, which is all
      // this test is about. Lead *content* is `leads`' own tests' job.
      const notification = WorkNotification(
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

      await tester.tap(find.text(_headline(notification.title)));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      // The sheet's own close control — unambiguous proof the real
      // `lead-detail` opened, not one of the three route-based targets.
      expect(find.byKey(const ValueKey('leadDetail-close')), findsOneWidget);
      expect(find.text('edit-listing-stub-lead-2001'), findsNothing);
      expect(find.text('publish-status-stub-lead-2001'), findsNothing);
      expect(find.text('coworker-detail-stub-lead-2001'), findsNothing);
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
          repository: FakeNotificationsRepository(
            notifications: notificationTestRows,
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
              notifications: notificationTestRows,
            ),
            locale: locale,
          );

          expect(tester.takeException(), isNull);
        });
      }
    }
  });

  group('access (SCREENS.md §22 is an agent surface)', () {
    // `GET /notifications` 403s for a buyer or a signed-out visitor
    // (`api/resources/notifications_resource.dart`). Before the guard, the
    // screen subscribed regardless, so anyone who reached it by deep link
    // or a stale back-stack entry got shimmer -> "Couldn't load your
    // notifications." -> a Retry that re-fired the same forbidden request
    // forever. These pin that the request is never issued at all.
    // Signed-in-but-not-an-agent and signed-out are different situations
    // and get different copy: the first can only be told this is not their
    // screen, the second has something to do about it.
    for (final (name, role, stateKey) in <(String, UserRole?, String)>[
      ('a buyer', UserRole.user, 'notificationsAgentOnlyState'),
      ('a signed-out visitor', null, 'notificationsSignInState'),
    ]) {
      testWidgets('$name sees the gated state, and no request is made', (
        tester,
      ) async {
        final repository = FakeNotificationsRepository();

        await pumpScreen(tester, repository: repository, role: role);

        expect(find.byKey(ValueKey(stateKey)), findsOneWidget);
        // The load-failure state is what the old behaviour produced here.
        expect(
          find.byKey(const ValueKey('notificationsErrorState')),
          findsNothing,
        );
        expect(repository.fetchCallCount, 0);
      });
    }

    testWidgets('an agent still reaches the real feed', (tester) async {
      final repository = FakeNotificationsRepository();

      await pumpScreen(tester, repository: repository, role: UserRole.agent);

      expect(
        find.byKey(const ValueKey('notificationsAgentOnlyState')),
        findsNothing,
      );
      expect(repository.fetchCallCount, greaterThan(0));
    });
  });
}

/// The first half of a fused notification title — mirrors
/// `NotificationRow`'s own split, so these tests target the same string the
/// row actually renders as its headline.
String _headline(String title) {
  for (final separator in [': ', ' — ', ' - ']) {
    final at = title.indexOf(separator);
    if (at > 0) return title.substring(0, at);
  }
  return title;
}
