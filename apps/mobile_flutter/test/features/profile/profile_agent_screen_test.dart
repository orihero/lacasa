// Widget tests for `profile-agent` (SCREENS.md §3.16). Pumped inside a real
// GoRouter — its rows push branch-relative routes (two of them literal,
// not-yet-`RoutePaths` strings — see `profile_agent_screen.dart`'s doc
// comment) and the Logout flow drives `authSessionProvider` — same shape as
// `test/features/settings/settings_screen_test.dart`.

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
import 'package:lacasa_mobile/theme/theme.dart';

import '../auth/support/fake_auth_repository.dart';
import '../language/support/fake_language_repository.dart';
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
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        languageRepositoryProvider.overrideWithValue(FakeLanguageRepository()),
        authRepositoryProvider.overrideWithValue(
          authRepository ?? FakeAuthRepository(),
        ),
      ],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).signIn(user);

    final router = GoRouter(
      initialLocation: RoutePaths.profile,
      routes: [
        GoRoute(
          path: RoutePaths.profile,
          builder: (context, state) => const ProfileAgentScreen(),
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
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return container;
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
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('tapping the phone copies it instead of dialling', (
      tester,
    ) async {
      await pumpScreen(tester, user: agent);

      await tester.tap(find.text('+998901112233'));
      await tester.pump();

      expect(find.text('Phone number copied: +998901112233'), findsOneWidget);
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
      await tester.ensureVisible(find.text('Logout'));
      await tester.pumpAndSettle();
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
      expect(find.text('Logout'), findsOneWidget);
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
