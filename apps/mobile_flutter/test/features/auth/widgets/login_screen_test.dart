// Widget tests for `login` (SCREENS.md §3.12, lib/features/auth/widgets/
// login_screen.dart). Pumped inside a real GoRouter — the close "X" branches
// on `context.canPop()` and a successful sign-in navigates via `context.go`,
// same reasoning `edit_profile_screen_test.dart`/`map_view_screen_test.dart`
// give for using a router instead of a bare `home:` widget.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/auth/auth.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/auth_test_data.dart';
import '../support/fake_auth_repository.dart';

void main() {
  Future<
    ({ProviderContainer container, GoRouter router, FakeAuthRepository repo})
  >
  pumpLogin(WidgetTester tester, {FakeAuthRepository? repository, bool withBackStack = true}) async {
    final repo = repository ?? FakeAuthRepository();
    final container = ProviderContainer(
      // Riverpod 3 auto-retries a thrown error; a deterministic call-count
      // assertion needs that switched off, same as every other screen test
      // in this app.
      retry: (retryCount, error) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        hasPersistedAuthTokenProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) => const Scaffold(body: Text('profile-root')),
        ),
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RoutePaths.register,
          builder: (context, state) => const Scaffold(body: Text('register-stub')),
        ),
        GoRoute(
          path: RoutePaths.home,
          builder: (context, state) => const Scaffold(body: Text('home-stub')),
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(theme: AppTheme.light(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    if (withBackStack) {
      router.push(RoutePaths.login);
    } else {
      router.go(RoutePaths.login);
    }
    await tester.pumpAndSettle();

    return (container: container, router: router, repo: repo);
  }

  group('fields and copy', () {
    testWidgets('renders §3.12\'s fields, button and link verbatim', (
      tester,
    ) async {
      await pumpLogin(tester);

      // AuthField renders its label through `.toUpperCase()` (the same
      // visual treatment `contact_sheet.dart`'s `_Field` already uses, and
      // `contact_sheet_test.dart` already asserts against in its own
      // uppercase form) — the underlying copy is still exactly "Email"/
      // "Password", just styled as small caps.
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('Sign in'), findsOneWidget);
      expect(find.text("Don't you have an account?"), findsOneWidget);
    });

    testWidgets('tapping the link pushes to register', (tester) async {
      await pumpLogin(tester);

      await tester.tap(find.text("Don't you have an account?"));
      await tester.pumpAndSettle();

      expect(find.text('register-stub'), findsOneWidget);
    });

    testWidgets('the close "X" pops back when there is a back stack', (
      tester,
    ) async {
      await pumpLogin(tester);

      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('profile-root'), findsOneWidget);
    });
  });

  group('client-side validation', () {
    testWidgets('empty fields show "Required fields are not filled" and do not call login', (
      tester,
    ) async {
      final result = await pumpLogin(tester);

      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Required fields are not filled'), findsOneWidget);
      expect(result.repo.loginCallCount, 0);
    });
  });

  group('server errors', () {
    testWidgets('401 invalidCredentials shows "Invalid email or password"', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        loginError: ApiErrorException(
          statusCode: 401,
          body: const ApiErrorBody(
            code: ApiErrorCode.invalidCredentials,
            message: 'Invalid email or password',
          ),
        ),
      );
      await pumpLogin(tester, repository: repo);

      await tester.enterText(find.byType(TextField).at(0), 'buyer@lacasa.uz');
      await tester.enterText(find.byType(TextField).at(1), 'wrong-password');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid email or password'), findsOneWidget);
      expect(repo.loginCallCount, 1);
    });

    testWidgets('400 validation surfaces the server\'s own message', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        loginError: ApiErrorException(
          statusCode: 400,
          body: const ApiErrorBody(
            code: ApiErrorCode.validation,
            message: 'Email must be a valid email address',
          ),
        ),
      );
      await pumpLogin(tester, repository: repo);

      await tester.enterText(find.byType(TextField).at(0), 'not-an-email');
      await tester.enterText(find.byType(TextField).at(1), 'secret1');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('Email must be a valid email address'), findsOneWidget);
    });
  });

  group('success', () {
    testWidgets('navigates to home-feed and shows the success toast', (
      tester,
    ) async {
      final repo = FakeAuthRepository(loginResult: authUser(email: 'buyer@lacasa.uz'));
      await pumpLogin(tester, repository: repo);

      await tester.enterText(find.byType(TextField).at(0), 'buyer@lacasa.uz');
      await tester.enterText(find.byType(TextField).at(1), 'secret1');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('home-stub'), findsOneWidget);
      expect(find.text('User successfully logged in.'), findsOneWidget);
    });

    testWidgets('a successful login updates authSessionProvider', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        loginResult: authUser(email: 'agent@lacasa.uz', role: UserRole.agent),
      );
      final result = await pumpLogin(tester, repository: repo);

      await tester.enterText(find.byType(TextField).at(0), 'agent@lacasa.uz');
      await tester.enterText(find.byType(TextField).at(1), 'secret1');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(result.container.read(authSessionProvider).role, UserRole.agent);
    });
  });

  group('password visibility', () {
    testWidgets('the password field starts obscured and toggles', (
      tester,
    ) async {
      await pumpLogin(tester);

      final field = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(field.obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      final toggled = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(toggled.obscureText, isFalse);
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

        await pumpLogin(tester);

        expect(tester.takeException(), isNull);
      });
    }
  });
}
