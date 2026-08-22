// Widget tests for `settings` (SCREENS.md §3.19). The screen is pumped
// inside a real GoRouter, not a bare MaterialApp: its back control branches
// on `context.canPop()`, its Connected Accounts row pushes a
// branch-relative route, and its Logout flow navigates on completion — none
// of which exists without a router in the tree. Same shape as
// `test/features/agents/agent_profile_screen_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/auth/state/auth_repository_provider.dart';
import 'package:lacasa_mobile/features/language/language.dart';
import 'package:lacasa_mobile/features/settings/settings.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../auth/support/fake_auth_repository.dart';
import '../language/support/fake_language_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'support/fake_notifications_preference_repository.dart';

void main() {
  /// Pumps `SettingsScreen` at `/profile/settings`, with the profile root
  /// as the route below it (`canPop()` is true — the ordinary case) and a
  /// stub `connected-accounts` route so a push can be observed without
  /// pulling that screen (unbuilt by this task) in.
  Future<ProviderContainer> pumpSettings(
    WidgetTester tester, {
    required FakeAuthRepository authRepository,
    FakeLanguageRepository? languageRepository,
    FakeNotificationsPreferenceRepository? notificationsRepository,
    UserRole? role,
    bool withBackStack = true,
    Locale locale = const Locale('en'),
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(authRepository),
        languageRepositoryProvider.overrideWithValue(
          languageRepository ?? FakeLanguageRepository(),
        ),
        notificationsPreferenceRepositoryProvider.overrideWithValue(
          notificationsRepository ?? FakeNotificationsPreferenceRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    if (role != null) {
      container.read(authSessionProvider.notifier).setRole(role);
    }

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              const Scaffold(body: Text('profile-root')),
          routes: [
            GoRoute(
              path: 'settings',
              builder: (context, state) => const SettingsScreen(),
            ),
            GoRoute(
              path: 'connected-accounts',
              builder: (context, state) =>
                  const Scaffold(body: Text('connected-accounts-stub')),
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
      router.push('/profile/settings');
    } else {
      router.go('/profile/settings');
    }
    await tester.pumpAndSettle();

    return container;
  }

  group('rows (SCREENS.md §3.19)', () {
    testWidgets('shows the header and the always-present rows', (tester) async {
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        role: UserRole.user,
      );

      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Notifications'), findsOneWidget);
      expect(find.text('About'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('Connected Accounts shows for an agent', (tester) async {
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        role: UserRole.agent,
      );

      expect(find.text('Connected Accounts'), findsOneWidget);
    });

    testWidgets('Connected Accounts is hidden for a coworker', (tester) async {
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        role: UserRole.coworker,
      );

      expect(find.text('Connected Accounts'), findsNothing);
    });

    testWidgets('Connected Accounts is hidden for a signed-out/buyer session', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        role: UserRole.user,
      );

      expect(find.text('Connected Accounts'), findsNothing);
    });

    testWidgets('tapping Connected Accounts pushes the branch-relative route', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        role: UserRole.agent,
      );

      await tester.tap(find.text('Connected Accounts'));
      await tester.pumpAndSettle();

      expect(find.text('connected-accounts-stub'), findsOneWidget);
    });
  });

  group('Language row', () {
    testWidgets('shows the current language as its subtitle', (tester) async {
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        languageRepository: FakeLanguageRepository(initial: AppLanguage.ru),
        role: UserRole.user,
      );

      // The subtitle is the language's own name for itself
      // (`AppLanguage.nativeName`), matching the mockup's "English" — not
      // the abbreviated "Ru" the sheet's radio row uses as its title.
      expect(find.text('Русский'), findsOneWidget);
      expect(find.text('Ru'), findsNothing);
    });

    testWidgets('tapping it opens language-sheet', (tester) async {
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        role: UserRole.user,
      );

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      // language-sheet's own three radio rows — proof the real sheet
      // opened, not a stand-in. Only the sheet renders the abbreviated
      // "En"/"Uz" titles now that the settings row's subtitle shows the
      // native name ("English") instead.
      expect(find.text('En'), findsOneWidget);
      expect(find.text('Uz'), findsOneWidget);
    });
  });

  group('Notifications toggle', () {
    testWidgets('is honest that flipping it does not send anything yet', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        role: UserRole.user,
      );

      expect(
        find.textContaining("aren't wired up in this build"),
        findsOneWidget,
      );
    });

    testWidgets('tapping it flips and persists the preference', (tester) async {
      final notifications = FakeNotificationsPreferenceRepository(
        initial: true,
      );
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        notificationsRepository: notifications,
        role: UserRole.user,
      );

      // `find.bySemanticsLabel('Notifications toggle')` can't address this
      // control on its own: `_SettingsRow`'s outer `Semantics(label:
      // 'Notifications')` merges the switch's nested semantics into the
      // same node (no `container: true`/boundary between them), so the
      // switch's own label never surfaces as a distinct semantics node —
      // see `settings_screen.dart`'s own note on
      // `settingsNotificationsSwitch`.
      await tester.tap(
        find.byKey(const ValueKey('settingsNotificationsSwitch')),
      );
      await tester.pumpAndSettle();

      expect(notifications.saved, [false]);

      // `find.bySemanticsLabel('Notifications toggle')` can't address this
      // control on its own: `_SettingsRow`'s outer `Semantics(label:
      // 'Notifications')` merges the switch's nested semantics into the
      // same node (no `container: true`/boundary between them), so the
      // switch's own label never surfaces as a distinct semantics node —
      // see `settings_screen.dart`'s own note on
      // `settingsNotificationsSwitch`.
      await tester.tap(
        find.byKey(const ValueKey('settingsNotificationsSwitch')),
      );
      await tester.pumpAndSettle();

      expect(notifications.saved, [false, true]);
    });
  });

  group('About row', () {
    testWidgets('tapping it shows the app name and version', (tester) async {
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        role: UserRole.user,
      );

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      expect(find.text('La Casa $appVersion'), findsOneWidget);
    });

    // §10.4 — this used to be a bare SnackBar, rendering Material's docked
    // dark-grey bar instead of SCREENS.md §5's floating card toast.
    testWidgets('the toast is a LaCasaToast, and a neutral one', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        role: UserRole.user,
      );

      await tester.tap(find.text('About'));
      await tester.pumpAndSettle();

      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      // Info, not success: the row answered a question, it didn't complete
      // an operation.
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byIcon(Icons.info_outline_rounded),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsNothing,
      );
    });
  });

  group('Logout', () {
    testWidgets(
      'tapping the row opens a confirm dialog, not an immediate sign-out',
      (tester) async {
        final repo = FakeAuthRepository();
        await pumpSettings(tester, authRepository: repo, role: UserRole.agent);

        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();

        expect(find.text('Log out?'), findsOneWidget);
        expect(repo.signOutCallCount, 0);
      },
    );

    testWidgets('Cancel dismisses without signing out', (tester) async {
      final repo = FakeAuthRepository();
      await pumpSettings(tester, authRepository: repo, role: UserRole.agent);

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Log out?'), findsNothing);
      expect(repo.signOutCallCount, 0);
      // Still on the settings screen — never navigated away.
      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets(
      'confirming signs out through AuthRepository and returns to the branch root',
      (tester) async {
        final repo = FakeAuthRepository();
        final container = await pumpSettings(
          tester,
          authRepository: repo,
          role: UserRole.agent,
        );

        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();
        // The dialog's own action button, not the row underneath it — this
        // is now the same shared `confirmSignOut` dialog (and the same key)
        // `profile-buyer`/`profile-agent`'s Logout rows use.
        await tester.tap(find.byKey(const ValueKey('profileLogoutConfirm')));
        await tester.pumpAndSettle();

        expect(repo.signOutCallCount, 1);
        expect(container.read(authSessionProvider).isSignedIn, isFalse);
        expect(find.text('profile-root'), findsOneWidget);
      },
    );

    // §10.4, and the one warning on this screen that genuinely is an error:
    // the account may sign itself back in on next launch.
    testWidgets(
      'a keystore that refuses to drop the token warns through the error toast',
      (tester) async {
        final repo = FakeAuthRepository(
          signOutError: StateError('keystore unavailable'),
        );
        await pumpSettings(tester, authRepository: repo, role: UserRole.agent);

        await tester.tap(find.text('Logout'));
        await tester.pumpAndSettle();
        await tester.tap(find.byKey(const ValueKey('profileLogoutConfirm')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining("the saved session couldn't be removed"),
          findsOneWidget,
        );
        final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
        expect(snackBar.behavior, SnackBarBehavior.floating);
        expect(
          find.descendant(
            of: find.byType(SnackBar),
            matching: find.byIcon(Icons.error_rounded),
          ),
          findsOneWidget,
        );
      },
    );
  });

  group('back navigation', () {
    testWidgets('back pops to the route below when there is one', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        role: UserRole.user,
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('profile-root'), findsOneWidget);
    });

    testWidgets('a deep link with nothing to pop still leaves via back', (
      tester,
    ) async {
      await pumpSettings(
        tester,
        authRepository: FakeAuthRepository(),
        role: UserRole.user,
        withBackStack: false,
      );

      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('profile-root'), findsOneWidget);
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

        await pumpSettings(
          tester,
          authRepository: FakeAuthRepository(),
          role: UserRole.agent,
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

          await pumpSettings(
            tester,
            authRepository: FakeAuthRepository(),
            role: UserRole.agent,
            locale: locale,
          );

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
