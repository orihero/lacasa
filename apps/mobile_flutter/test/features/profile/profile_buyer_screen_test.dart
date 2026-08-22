// Widget tests for `profile-buyer` (SCREENS.md §3.15). Pumped inside a real
// GoRouter — its rows push branch-relative routes and the Logout flow drives
// `authSessionProvider` — same shape as `test/features/settings/
// settings_screen_test.dart`.

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
import 'package:lacasa_mobile/shared/platform/link_launcher.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../shared/support/fake_link_launcher.dart';
import '../auth/support/fake_auth_repository.dart';
import '../language/support/fake_language_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'support/profile_test_data.dart';

void main() {
  setUp(() {
    // Register as Agent copies a URL to the clipboard — see
    // `test/features/agents/agent_profile_screen_test.dart`'s identical
    // setUp for why this mock is needed at all.
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

  /// Pumps `profile-buyer` at `/profile`, signed in as [user], with stub
  /// routes standing in for `saved-listings`/`edit-profile` so a push can be
  /// observed without dragging either screen (and its own repository) in.
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required AuthUser user,
    FakeAuthRepository? authRepository,
    LinkLauncher? linkLauncher,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        languageRepositoryProvider.overrideWithValue(FakeLanguageRepository()),
        authRepositoryProvider.overrideWithValue(
          authRepository ?? FakeAuthRepository(),
        ),
        // Only overridden by the "Register as Agent" tests below — every
        // other test leaves the real `UrlLauncherLinkLauncher` in place,
        // which simply fails closed (see its own doc comment) under the
        // widget-test harness's unmocked plugin channel, so it never
        // interferes with assertions that don't touch this row.
        if (linkLauncher != null)
          linkLauncherProvider.overrideWithValue(linkLauncher),
      ],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).signIn(user);

    final router = GoRouter(
      initialLocation: RoutePaths.profile,
      routes: [
        GoRoute(
          path: RoutePaths.profile,
          builder: (context, state) => const ProfileBuyerScreen(),
          routes: [
            GoRoute(
              path: 'saved',
              builder: (context, state) =>
                  const Scaffold(body: Text('saved-listings-stub')),
            ),
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  const Scaffold(body: Text('edit-profile-stub')),
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

  final buyer = authUser(
    id: 'user-1',
    fullName: 'Dilnoza Yusupova',
    email: 'dilnoza@example.com',
    role: 'user',
    phoneNumber: '+998901112233',
  );

  group('happy path', () {
    testWidgets('shows the header and the §3.15 info card fields', (
      tester,
    ) async {
      await pumpScreen(tester, user: buyer);

      expect(find.text('Profile'), findsOneWidget);
      expect(find.text('Dilnoza Yusupova'), findsOneWidget);
      expect(find.text('dilnoza@example.com'), findsOneWidget);
      expect(find.text('+998901112233'), findsOneWidget);
      expect(find.text('Saved Listings'), findsOneWidget);
      expect(find.text('Update Profile'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Register as Agent'), findsOneWidget);
      expect(find.text('Logout'), findsOneWidget);
    });

    testWidgets('a missing phone renders as an em dash, not a blank line', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        user: authUser(
          id: 'user-2',
          fullName: 'No Phone',
          email: 'nophone@example.com',
          role: 'user',
        ),
      );

      expect(find.text('—'), findsOneWidget);
    });

    testWidgets('Saved Listings pushes RoutePaths.profileSaved', (
      tester,
    ) async {
      await pumpScreen(tester, user: buyer);

      await tester.tap(find.text('Saved Listings'));
      await tester.pumpAndSettle();

      expect(find.text('saved-listings-stub'), findsOneWidget);
    });

    testWidgets('Update Profile pushes RoutePaths.profileEdit', (tester) async {
      await pumpScreen(tester, user: buyer);

      await tester.tap(find.text('Update Profile'));
      await tester.pumpAndSettle();

      expect(find.text('edit-profile-stub'), findsOneWidget);
    });

    testWidgets('Language opens the language sheet', (tester) async {
      await pumpScreen(tester, user: buyer);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      expect(find.text('En'), findsOneWidget);
    });

    testWidgets('Register as Agent copies the form link and shows a toast', (
      tester,
    ) async {
      // The row now tries a real external-browser launch first (see
      // `profile_buyer_screen.dart`'s doc comment) and only falls back to
      // copy-and-toast when nothing on the device can open the link — a
      // `FakeLinkLauncher(result: false)` is how this suite forces that
      // fallback path deterministically, same pattern as
      // `connected_accounts_screen_test.dart`'s "falls back to copying"
      // case.
      final launcher = FakeLinkLauncher(result: false);
      await pumpScreen(tester, user: buyer, linkLauncher: launcher);

      await tester.tap(find.text('Register as Agent'));
      await tester.pumpAndSettle();

      expect(launcher.opened, [
        Uri.parse('https://forms.gle/1Kr71PzWjqqCQcVTA'),
      ]);
      expect(
        find.textContaining('Registration form link copied'),
        findsOneWidget,
      );
    });

    testWidgets(
      'Register as Agent opens the form in the external browser when one is '
      'available, and never shows the copy toast',
      (tester) async {
        final launcher = FakeLinkLauncher(result: true);
        await pumpScreen(tester, user: buyer, linkLauncher: launcher);

        await tester.tap(find.text('Register as Agent'));
        await tester.pumpAndSettle();

        expect(launcher.opened, [
          Uri.parse('https://forms.gle/1Kr71PzWjqqCQcVTA'),
        ]);
        expect(
          find.textContaining('Registration form link copied'),
          findsNothing,
        );
      },
    );

    testWidgets('Logout, confirmed, signs out and swaps the header back to the '
        'signed-out prompt row set', (tester) async {
      final authRepository = FakeAuthRepository();
      await pumpScreen(tester, user: buyer, authRepository: authRepository);

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // The native alert's own destructive action, distinct from the row
      // that opened it — both currently read "Logout".
      await tester.tap(find.byKey(const ValueKey('profileLogoutConfirm')));
      await tester.pumpAndSettle();

      expect(authRepository.signOutCallCount, 1);
      // ProfileBuyerScreen itself doesn't switch on role — that's
      // `profile_role_screen.dart`'s job — so the only thing this test can
      // assert from inside ProfileBuyerScreen is that signOut happened.
    });

    testWidgets('Logout, cancelled, does not sign out', (tester) async {
      final authRepository = FakeAuthRepository();
      await pumpScreen(tester, user: buyer, authRepository: authRepository);

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(authRepository.signOutCallCount, 0);
    });
  });

  // §7.5 — `RealtorProfile.status` was parsed off the wire and read by
  // nothing, so a person who signed up as a Realtor (which creates a
  // `role: "user"` account pending approval) landed here and was invited to
  // apply again via the Google Form. A rejected applicant was told nothing.
  group('realtor application status', () {
    testWidgets('no application at all keeps §3.15\'s Register as Agent row', (
      tester,
    ) async {
      await pumpScreen(tester, user: buyer);

      expect(
        find.byKey(const ValueKey('profileBuyerRegisterAsAgentRow')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('profileBuyerRealtorPendingCard')),
        findsNothing,
      );
    });

    testWidgets('a pending application replaces the row with an under-review '
        'card and hides the Google Form', (tester) async {
      await pumpScreen(
        tester,
        user: authUser(
          id: 'user-pending',
          fullName: 'Dilnoza Yusupova',
          email: 'dilnoza@example.com',
          role: 'user',
          phoneNumber: '+998901112233',
          realtor: realtorApplication(status: 'pending'),
        ),
      );

      expect(
        find.byKey(const ValueKey('profileBuyerRealtorPendingCard')),
        findsOneWidget,
      );
      expect(find.text('Realtor application under review'), findsOneWidget);
      // The number §3.13's verification note promised to call.
      expect(
        find.text(
          "We'll call +998901112233 — usually within one business day.",
        ),
        findsOneWidget,
      );
      // The whole point: no second application while the first is open.
      expect(find.text('Register as Agent'), findsNothing);
      expect(
        find.byKey(const ValueKey('profileBuyerRegisterAsAgentRow')),
        findsNothing,
      );
    });

    testWidgets('an agency applicant is called on the office phone they gave', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        user: authUser(
          id: 'user-agency',
          fullName: 'Dilnoza Yusupova',
          email: 'dilnoza@example.com',
          role: 'user',
          phoneNumber: '+998901112233',
          realtor: realtorApplication(
            status: 'pending',
            kind: 'agency',
            agencyName: 'La Casa Realty',
            officePhone: '+998712001020',
          ),
        ),
      );

      expect(
        find.text(
          "We'll call +998712001020 — usually within one business day.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('an applicant with no number at all gets the no-phone copy', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        user: authUser(
          id: 'user-nophone',
          fullName: 'Dilnoza Yusupova',
          email: 'dilnoza@example.com',
          role: 'user',
          realtor: realtorApplication(status: 'pending'),
        ),
      );

      expect(
        find.text("We'll call you — usually within one business day."),
        findsOneWidget,
      );
    });

    testWidgets('a pending card shows when the application was submitted', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        user: authUser(
          id: 'user-applied',
          fullName: 'Dilnoza Yusupova',
          email: 'dilnoza@example.com',
          role: 'user',
          phoneNumber: '+998901112233',
          realtor: realtorApplication(
            status: 'pending',
            appliedAt: '2026-08-12T09:30:00.000Z',
          ),
        ),
      );

      // Local time, formatted through Formatters.date — asserted by prefix
      // so the test doesn't depend on the runner's time zone.
      expect(find.textContaining('Applied 1'), findsOneWidget);
    });

    testWidgets('a rejected application says so and offers Contact Us', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        user: authUser(
          id: 'user-rejected',
          fullName: 'Dilnoza Yusupova',
          email: 'dilnoza@example.com',
          role: 'user',
          phoneNumber: '+998901112233',
          realtor: realtorApplication(status: 'rejected'),
        ),
      );

      expect(
        find.byKey(const ValueKey('profileBuyerRealtorRejectedCard')),
        findsOneWidget,
      );
      expect(find.text('Realtor application not approved'), findsOneWidget);
      expect(find.text('Register as Agent'), findsNothing);

      await tester.tap(
        find.byKey(const ValueKey('profileBuyerRealtorContactAction')),
      );
      await tester.pumpAndSettle();

      // The §3.11 sheet, identified by its own subtitle — "Contact Us"
      // itself is on screen twice at this point (the action and the sheet
      // title).
      expect(
        find.textContaining('We welcome all your concerns'),
        findsOneWidget,
      );
    });

    testWidgets('an approved application falls back to today\'s row', (
      tester,
    ) async {
      // Unreachable in practice — approval promotes the account to
      // `role: "agent"`, which renders `profile-agent` — so this pins the
      // deliberate "keep the previous behaviour" fallback rather than a
      // fourth invented state. See profile_buyer_screen.dart.
      await pumpScreen(
        tester,
        user: authUser(
          id: 'user-approved',
          fullName: 'Dilnoza Yusupova',
          email: 'dilnoza@example.com',
          role: 'user',
          phoneNumber: '+998901112233',
          realtor: realtorApplication(status: 'approved'),
        ),
      );

      expect(
        find.byKey(const ValueKey('profileBuyerRegisterAsAgentRow')),
        findsOneWidget,
      );
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
            id: 'user-long',
            fullName: 'Shahnoza Yoldosheva-Abdurahmonova',
            email: 'shahnoza.yoldosheva.abdurahmonova@lacasa.uz',
            role: 'user',
            phoneNumber: '+998901234567',
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
