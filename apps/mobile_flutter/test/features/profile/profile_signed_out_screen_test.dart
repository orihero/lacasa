// Widget tests for `profile-signed-out` (SCREENS.md §3.14). Pumped inside a
// real GoRouter — its Sign In/Sign Up buttons push top-level routes
// (`RoutePaths.login`/`register`), which doesn't exist without a router in
// the tree — same shape as `test/features/saved_listings/
// saved_listings_screen_test.dart`'s stub-route pattern.

import 'dart:async';

import 'package:flutter/material.dart';
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
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<ProviderContainer> pumpScreen(WidgetTester tester) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        languageRepositoryProvider.overrideWithValue(FakeLanguageRepository()),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RoutePaths.profile,
      routes: [
        GoRoute(
          path: RoutePaths.profile,
          builder: (context, state) => const ProfileSignedOutScreen(),
        ),
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const Scaffold(body: Text('login-stub')),
        ),
        GoRoute(
          path: RoutePaths.register,
          builder: (context, state) =>
              const Scaffold(body: Text('register-stub')),
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

  group('happy path', () {
    testWidgets('shows the header, the §3.14 prompt sentence and both rows', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(find.text('Profile'), findsOneWidget);
      expect(
        find.text(
          'Sign in to save listings, message agents, and manage your '
          'business.',
        ),
        findsOneWidget,
      );
      expect(find.text('Sign In'), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Contact Us'), findsOneWidget);
    });

    testWidgets('Sign In pushes RoutePaths.login', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('login-stub'), findsOneWidget);
    });

    testWidgets('Sign Up pushes RoutePaths.register', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Sign Up'));
      await tester.pumpAndSettle();

      expect(find.text('register-stub'), findsOneWidget);
    });

    testWidgets('Language opens the language sheet', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();

      // §3.20's sheet title and the "En"/"Uz"/"Ru" radio labels, quoted
      // exactly.
      expect(find.text('Language'), findsNWidgets(2)); // row + sheet title
      expect(find.text('En'), findsOneWidget);
      expect(find.text('Uz'), findsOneWidget);
      expect(find.text('Ru'), findsOneWidget);
    });

    testWidgets('Contact Us opens the contact sheet', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.text('Contact Us'));
      await tester.pumpAndSettle();

      // §3.11's sheet title and button label, quoted exactly.
      expect(find.text('Contact Us'), findsNWidgets(2)); // row + sheet title
      expect(find.text('Send message'), findsOneWidget);
    });
  });

  // §7.6 — `role == null` also covers the cold-start window in which
  // `AuthSessionNotifier` is still validating a persisted token, so a
  // returning agent was shown "Sign in to … manage your business" for a
  // round trip. Nothing in `lib/` read `isRestoring` before this.
  group('cold start while the session is being restored', () {
    /// Same tree as [pumpScreen], but with a persisted token and a `/me`
    /// call that never resolves — frozen in the restoring window. No
    /// `pumpAndSettle`: `ShimmerBox` animates for as long as it is mounted.
    Future<Completer<void>> pumpRestoring(WidgetTester tester) async {
      final gate = Completer<void>();
      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [
          languageRepositoryProvider.overrideWithValue(
            FakeLanguageRepository(),
          ),
          hasPersistedAuthTokenProvider.overrideWithValue(true),
          authRepositoryProvider.overrideWithValue(
            FakeAuthRepository(
              currentUserHold: gate,
              currentUserError: ApiErrorException(
                statusCode: 401,
                body: const ApiErrorBody(
                  code: ApiErrorCode.unauthorized,
                  message: 'Unauthorized',
                ),
              ),
            ),
          ),
        ],
      );
      addTearDown(container.dispose);
      // Reading the notifier starts the restore, the same way building the
      // app over this provider does in `main.dart`.
      container.read(authSessionProvider);

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            theme: AppTheme.light(),
            home: const ProfileSignedOutScreen(),
          ),
        ),
      );
      await tester.pump();
      return gate;
    }

    testWidgets('the prompt card is a skeleton, not a claim about the user', (
      tester,
    ) async {
      final gate = await pumpRestoring(tester);

      expect(
        find.byKey(const ValueKey('profileSignedOutRestoringSkeleton')),
        findsOneWidget,
      );
      expect(
        find.text(
          'Sign in to save listings, message agents, and manage your '
          'business.',
        ),
        findsNothing,
      );
      expect(find.text('Sign In'), findsNothing);
      expect(find.text('Sign Up'), findsNothing);

      // The two rows below need no session at all, so they stay: hiding a
      // working control to fix a sentence would be the wrong trade.
      expect(find.text('Language'), findsOneWidget);
      expect(find.text('Contact Us'), findsOneWidget);
      // …as does the header, so the user knows where they are meanwhile.
      expect(find.text('Profile'), findsOneWidget);

      // Drain the `/me` timeout timer before the test ends.
      gate.complete();
      await tester.pumpAndSettle();
    });

    testWidgets('a settled restore puts §3.14\'s prompt back', (tester) async {
      final gate = await pumpRestoring(tester);

      gate.complete();
      await tester.pumpAndSettle();

      expect(
        find.byKey(const ValueKey('profileSignedOutRestoringSkeleton')),
        findsNothing,
      );
      expect(
        find.text(
          'Sign in to save listings, message agents, and manage your '
          'business.',
        ),
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

        await pumpScreen(tester);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
