// Widget tests for `profile-agent` (SCREENS.md §3.16). Pumped inside a real
// GoRouter — every row pushes `'$branchPrefix/…'` and the Logout flow drives
// `authSessionProvider` — same shape as
// `test/features/settings/settings_screen_test.dart`.
//
// The screen is mounted in both shells (see `app_router.dart`), so
// [pumpScreen] takes a `branchPrefix` and the Workspace-row group below
// pumps it once per shell: the row is the Browse/Work switch and its
// direction is read off that prefix.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/auth/state/auth_repository_provider.dart';
import 'package:lacasa_mobile/features/language/language.dart';
import 'package:lacasa_mobile/features/profile/profile.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/navigation/workspace_mode.dart';
import 'package:lacasa_mobile/shared/platform/link_launcher.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../shared/support/fake_link_launcher.dart';
import '../auth/support/fake_auth_repository.dart';
import '../language/support/fake_language_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'support/profile_test_data.dart';

void main() {
  setUp(() {
    // The phone row copies the number to the clipboard instead of dialling
    // — see `test/features/agents/agent_profile_screen_test.dart`'s
    // identical setUp for why this mock is needed at all.
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
          SystemChannels.platform,
          (call) async => null,
        );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(SystemChannels.platform, null);
  });

  /// Pumps `profile-agent` at `/profile`, signed in as [user], with stub
  /// routes standing in for every row's destination.
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required AuthUser user,
    FakeAuthRepository? authRepository,
    LinkLauncher? linkLauncher,
    String branchPrefix = RoutePaths.profile,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        languageRepositoryProvider.overrideWithValue(FakeLanguageRepository()),
        authRepositoryProvider.overrideWithValue(
          authRepository ?? FakeAuthRepository(),
        ),
        // Only overridden by the phone-row test below — every other test
        // leaves the real `UrlLauncherLinkLauncher` in place, which never
        // gets a chance to run because nothing else in this suite taps the
        // phone row. Same pattern as `profile_buyer_screen_test.dart`'s
        // "Register as Agent" override.
        if (linkLauncher != null)
          linkLauncherProvider.overrideWithValue(linkLauncher),
      ],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).signIn(user);

    final router = GoRouter(
      initialLocation: branchPrefix,
      routes: [
        GoRoute(
          path: branchPrefix,
          builder: (context, state) =>
              ProfileAgentScreen(branchPrefix: branchPrefix),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  const Scaffold(body: Text('edit-profile-stub')),
            ),
            GoRoute(
              path: 'settings',
              builder: (context, state) =>
                  const Scaffold(body: Text('settings-stub')),
            ),
            GoRoute(
              path: 'connected-accounts',
              builder: (context, state) =>
                  const Scaffold(body: Text('connected-accounts-stub')),
            ),
            GoRoute(
              path: 'messages',
              builder: (context, state) =>
                  const Scaffold(body: Text('messages-stub')),
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

  /// Scrolls [finder] into view from the bottom of the list. The rows below
  /// Language (the Workspace switch, the Session group, Logout) are past the
  /// fold on the 800x600 default test surface *and unbuilt* — a lazy
  /// [ListView] never creates them — so `ensureVisible` alone throws "No
  /// element". Dragging is what builds them.
  Future<void> scrollTo(WidgetTester tester, Finder finder) async {
    await tester.dragUntilVisible(
      finder,
      find.byType(ListView),
      const Offset(0, -120),
    );
    await tester.pumpAndSettle();
  }

  final agent = authUser(
    id: 'agent-1',
    fullName: 'Javlon Rustamov',
    email: 'javlon@lacasa.uz',
    role: 'agent',
    phoneNumber: '+998901112233',
  );

  final coworker = authUser(
    id: 'coworker-1',
    fullName: 'Sardor Abdullayev',
    email: 'sardor@lacasa.uz',
    role: 'coworker',
    phoneNumber: '+998907654321',
    agentId: 'agent-1',
  );

  group('happy path — agent', () {
    testWidgets('shows the header, the raw "agent" role badge, and every row', (
      tester,
    ) async {
      await pumpScreen(tester, user: agent);

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Javlon Rustamov'), findsOneWidget);
      // The RAW wire string, not "Agent" — §3.16 says so explicitly.
      expect(find.text('agent'), findsOneWidget);
      expect(find.text('Agent'), findsNothing);
      expect(find.text('+998901112233'), findsOneWidget);
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Connected Accounts'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      await scrollTo(tester, find.text('Logout'));
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('tapping the phone copies it instead of dialling', (
      tester,
    ) async {
      // The row now dials through `dialOrCopyPhone` (see
      // `lib/shared/widgets/dial_or_copy.dart`) rather than copying
      // unconditionally: it tries a real `tel:` intent first and only
      // falls back to copy-and-toast when nothing on the device answers
      // it. A `FakeLinkLauncher(result: false)` forces that fallback path
      // deterministically instead of relying on the widget-test harness's
      // unmocked plugin channel — same pattern as
      // `profile_buyer_screen_test.dart`'s "Register as Agent" case.
      final launcher = FakeLinkLauncher(result: false);
      await pumpScreen(tester, user: agent, linkLauncher: launcher);

      await tester.tap(find.text('+998901112233'));
      await tester.pumpAndSettle();

      expect(launcher.dialed, ['+998901112233']);
      // Unlike the old copy-only toast this test used to assert,
      // `sharedDialFallbackToastMessage` is honest about *why* it copied.
      expect(
        find.text(
          "Couldn't open the dialer — phone number copied: +998901112233",
        ),
        findsOneWidget,
      );
    });

    testWidgets('Edit Profile pushes RoutePaths.profileEdit', (tester) async {
      await pumpScreen(tester, user: agent);

      await tester.tap(find.text('Edit Profile'));
      await tester.pumpAndSettle();

      expect(find.text('edit-profile-stub'), findsOneWidget);
    });

    testWidgets('Connected Accounts pushes /profile/connected-accounts', (
      tester,
    ) async {
      await pumpScreen(tester, user: agent);

      await tester.tap(find.text('Connected Accounts'));
      await tester.pumpAndSettle();

      expect(find.text('connected-accounts-stub'), findsOneWidget);
    });

    testWidgets('Settings pushes RoutePaths.profileSettings', (tester) async {
      await pumpScreen(tester, user: agent);

      await tester.tap(find.text('Settings'));
      await tester.pumpAndSettle();

      expect(find.text('settings-stub'), findsOneWidget);
    });

    testWidgets('Messages pushes /profile/messages', (tester) async {
      await pumpScreen(tester, user: agent);

      await tester.tap(find.text('Messages'));
      await tester.pumpAndSettle();

      expect(find.text('messages-stub'), findsOneWidget);
    });

    testWidgets('Language opens the language sheet', (tester) async {
      await pumpScreen(tester, user: agent);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      expect(find.text('En'), findsOneWidget);
    });

    testWidgets('Logout, confirmed, calls AuthRepository.signOut', (
      tester,
    ) async {
      final authRepository = FakeAuthRepository();
      await pumpScreen(tester, user: agent, authRepository: authRepository);

      // Logout is the last row — below the fold on the 800x600 default test
      // surface, unlike every row tapped above it.
      await scrollTo(tester, find.text('Logout'));
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();
      expect(find.text('Log out?'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('profileLogoutConfirm')));
      await tester.pumpAndSettle();

      expect(authRepository.signOutCallCount, 1);
    });
  });

  group('happy path — coworker', () {
    testWidgets('shows the raw "coworker" badge and hides Connected Accounts', (
      tester,
    ) async {
      await pumpScreen(tester, user: coworker);

      expect(find.text('coworker'), findsOneWidget);
      expect(find.text('Connected Accounts'), findsNothing);
      // Every other row still renders for a coworker.
      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Settings'), findsOneWidget);
      expect(find.text('Messages'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      await scrollTo(tester, find.text('Logout'));
      expect(find.text('Logout'), findsOneWidget);
    });
  });

  // The Browse/Work switch (`navigation/workspace_mode.dart`). The row only
  // sets the mode — the shell swap is `app_router.dart`'s redirect, which
  // this scoped stub router deliberately does not have, so these assert the
  // mode and the copy rather than a navigation.
  group('workspace mode switch', () {
    testWidgets('in the agent shell it offers Browse and sets browse mode', (
      tester,
    ) async {
      final container = await pumpScreen(
        tester,
        user: agent,
        branchPrefix: RoutePaths.workProfile,
      );
      expect(container.read(workspaceModeProvider), WorkspaceMode.work);

      final row = find.byKey(const ValueKey('profileAgentWorkspaceModeRow'));
      await scrollTo(tester, row);
      expect(find.text('Browse listings'), findsOneWidget);
      expect(find.text('Go to workspace'), findsNothing);

      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(container.read(workspaceModeProvider), WorkspaceMode.browse);
    });

    testWidgets('in the buyer shell it offers the way back to the workspace', (
      tester,
    ) async {
      final container = await pumpScreen(tester, user: agent);
      container
          .read(workspaceModeProvider.notifier)
          .setMode(WorkspaceMode.browse);
      await tester.pumpAndSettle();

      final row = find.byKey(const ValueKey('profileAgentWorkspaceModeRow'));
      await scrollTo(tester, row);
      expect(find.text('Go to workspace'), findsOneWidget);
      expect(find.text('Browse listings'), findsNothing);

      await tester.tap(row);
      await tester.pumpAndSettle();

      expect(container.read(workspaceModeProvider), WorkspaceMode.work);
    });

    testWidgets('a coworker gets the switch too', (tester) async {
      await pumpScreen(
        tester,
        user: coworker,
        branchPrefix: RoutePaths.workProfile,
      );

      await scrollTo(
        tester,
        find.byKey(const ValueKey('profileAgentWorkspaceModeRow')),
      );
      expect(find.text('Browse listings'), findsOneWidget);
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
          user: authUser(
            id: 'agent-long',
            fullName: 'Shahnoza Yoldosheva-Abdurahmonova',
            email: 'shahnoza@lacasa.uz',
            role: 'agent',
            phoneNumber: '+998901234567',
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
