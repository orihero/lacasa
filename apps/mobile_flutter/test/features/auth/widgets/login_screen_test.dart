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
import 'package:lacasa_mobile/features/auth/widgets/auth_form_widgets.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/auth_test_data.dart';
import '../support/fake_auth_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<
    ({ProviderContainer container, GoRouter router, FakeAuthRepository repo})
  >
  pumpLogin(
    WidgetTester tester, {
    FakeAuthRepository? repository,
    bool withBackStack = true,
    Locale locale = const Locale('en'),
  }) async {
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
          builder: (context, state) =>
              const Scaffold(body: Text('profile-root')),
        ),
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: RoutePaths.register,
          builder: (context, state) =>
              const Scaffold(body: Text('register-stub')),
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

    // Regression guard, and a deliberate statement of intent. An earlier
    // revision seeded both controllers with the approved `AGENT` account's
    // real credentials, gated on `isRunningUnderFlutterTest` — so the one
    // environment where the fields were empty was the only environment no
    // user is ever in, and the suite was structurally incapable of seeing
    // it. This assertion catches any ungated prefill directly; against a
    // test-gated one it is worth writing anyway, because it makes "the
    // fields start empty" an asserted contract of this screen rather than
    // an incidental property, so re-adding a gate means visibly defeating a
    // test that says otherwise instead of quietly slipping past a suite
    // that never looked.
    testWidgets('both fields start empty — no seeded credentials', (
      tester,
    ) async {
      await pumpLogin(tester);

      final email = tester.widget<TextField>(find.byType(TextField).at(0));
      final password = tester.widget<TextField>(find.byType(TextField).at(1));

      expect(email.controller?.text, isEmpty);
      expect(password.controller?.text, isEmpty);
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
    testWidgets(
      'empty fields show "Required fields are not filled" and do not call login',
      (tester) async {
        final result = await pumpLogin(tester);

        await tester.tap(find.text('Sign in'));
        await tester.pumpAndSettle();

        expect(find.text('Required fields are not filled'), findsOneWidget);
        expect(result.repo.loginCallCount, 0);
      },
    );
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
      // §7.4 — the invalid-credentials path used to be a terminal string.
      // §3.12 pins "Invalid email or password" character for character, so
      // the pointer at the recovery link is a second line, not an append.
      expect(find.text('Forgot it? Tap Forgot password.'), findsOneWidget);
    });

    testWidgets('a non-401 failure gets no forgot-password pointer', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        loginError: const NetworkException('offline'),
      );
      await pumpLogin(tester, repository: repo);

      await tester.enterText(find.byType(TextField).at(0), 'buyer@lacasa.uz');
      await tester.enterText(find.byType(TextField).at(1), 'secret1');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      // Being offline is not having forgotten anything.
      expect(find.text('Forgot it? Tap Forgot password.'), findsNothing);
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
      final repo = FakeAuthRepository(
        loginResult: authUser(email: 'buyer@lacasa.uz'),
      );
      await pumpLogin(tester, repository: repo);

      await tester.enterText(find.byType(TextField).at(0), 'buyer@lacasa.uz');
      await tester.enterText(find.byType(TextField).at(1), 'secret1');
      await tester.tap(find.text('Sign in'));
      await tester.pumpAndSettle();

      expect(find.text('home-stub'), findsOneWidget);
      expect(find.text('User successfully logged in.'), findsOneWidget);

      // §10.4 — SCREENS.md §5's floating card toast with a status glyph,
      // not Material's docked dark-grey default.
      final snackBar = tester.widget<SnackBar>(find.byType(SnackBar));
      expect(snackBar.behavior, SnackBarBehavior.floating);
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byIcon(Icons.check_circle_rounded),
        ),
        findsOneWidget,
      );
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

  // §7.4 — before this, a user who forgot their password had exactly three
  // exits (submit, the Sign Up link, the close "X") and none of them
  // recovered an account. There is still no `POST /auth/forgot-password`,
  // so the link opens the §3.11 contact sheet; see login_screen.dart for the
  // swap target once the endpoint lands.
  group('forgot password', () {
    testWidgets('the link sits under the Password field', (tester) async {
      await pumpLogin(tester);

      expect(
        find.byKey(const ValueKey('loginForgotPasswordLink')),
        findsOneWidget,
      );
      expect(find.text('Forgot password?'), findsOneWidget);
    });

    testWidgets('tapping it opens the contact sheet with the typed email', (
      tester,
    ) async {
      await pumpLogin(tester);

      await tester.enterText(find.byType(TextField).at(0), 'buyer@lacasa.uz');
      await tester.tap(find.byKey(const ValueKey('loginForgotPasswordLink')));
      await tester.pumpAndSettle();

      // The §3.11 sheet, seeded so support can act without a round trip
      // asking which account this is.
      expect(
        find.textContaining('We welcome all your concerns'),
        findsOneWidget,
      );
      expect(
        find.textContaining(
          "I forgot the password for buyer@lacasa.uz and can't sign in.",
        ),
        findsOneWidget,
      );
    });

    testWidgets(
      'tapping it before typing anything leaves the account unnamed',
      (tester) async {
        await pumpLogin(tester);

        await tester.tap(find.byKey(const ValueKey('loginForgotPasswordLink')));
        await tester.pumpAndSettle();

        expect(
          find.textContaining("I forgot my password and can't sign in."),
          findsOneWidget,
        );
      },
    );
  });

  // §7.8 — `AutofillHints`, not `keyboardType`, is what registers a field
  // with iOS Keychain / Android Autofill / 1Password / Bitwarden. Nothing in
  // this app set it before, which meant no credential could be filled *or
  // saved* — and with no password reset (§7.4) that made a forgotten
  // password permanent.
  group('debug-only seeded-account shortcut on the hero icon', () {
    // The shortcut is compiled out unless `kDebugMode`, and `flutter test`
    // runs in debug — so these tests exercise the same tree a developer's
    // debug build has, and say nothing about release, where the gesture
    // detector is not in the tree at all.
    Finder heroIcon() => find.byType(AuthHeroIcon);

    Future<void> tapHero(WidgetTester tester, int times) async {
      for (var i = 0; i < times; i++) {
        await tester.tap(heroIcon());
        // Well inside the two-second run window, so the taps accumulate.
        await tester.pump(const Duration(milliseconds: 50));
      }
    }

    /// A press held past the 3s threshold. `tester.longPress` cannot be used:
    /// it holds for `kLongPressTimeout` (500ms), which is exactly the
    /// duration this screen deliberately does not use.
    Future<void> pressHero(WidgetTester tester, Duration hold) async {
      final gesture = await tester.startGesture(tester.getCenter(heroIcon()));
      await tester.pump(hold);
      await gesture.up();
      await tester.pumpAndSettle();
    }

    testWidgets('five taps signs in as the seeded agent', (tester) async {
      final harness = await pumpLogin(
        tester,
        repository: FakeAuthRepository(
          loginResult: authUser(role: UserRole.agent),
        ),
      );

      await tapHero(tester, 5);
      await tester.pumpAndSettle();

      expect(harness.repo.lastLoginEmail, 'agent@lacasa.dev');
      expect(harness.repo.lastLoginPassword, 'password123');
      expect(find.text('home-stub'), findsOneWidget);
    });

    testWidgets('a three-second press signs in as the seeded buyer', (
      tester,
    ) async {
      final harness = await pumpLogin(
        tester,
        repository: FakeAuthRepository(
          loginResult: authUser(role: UserRole.user),
        ),
      );

      await pressHero(tester, const Duration(seconds: 3, milliseconds: 200));

      expect(harness.repo.lastLoginEmail, 'user@lacasa.dev');
      expect(harness.repo.lastLoginPassword, 'password123');
      expect(find.text('home-stub'), findsOneWidget);
    });

    testWidgets('four taps does nothing — the fifth is the trigger', (
      tester,
    ) async {
      final harness = await pumpLogin(tester);

      await tapHero(tester, 4);
      await tester.pumpAndSettle();

      expect(harness.repo.loginCallCount, 0);

      // Let the run window lapse so no Timer outlives the test.
      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a run of taps lapses, so strays never accumulate into a '
        'sign-in', (tester) async {
      final harness = await pumpLogin(tester);

      await tapHero(tester, 4);
      // Past the two-second window: the count resets, so the next tap is a
      // first tap rather than a fifth.
      await tester.pump(const Duration(seconds: 3));
      await tapHero(tester, 1);
      await tester.pumpAndSettle();

      expect(harness.repo.loginCallCount, 0);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('a press shorter than three seconds counts as a tap, not a '
        'buyer sign-in', (tester) async {
      final harness = await pumpLogin(tester);

      // Longer than kLongPressTimeout (500ms) — which is what would have
      // fired a plain GestureDetector's onLongPress — but short of 3s.
      await pressHero(tester, const Duration(milliseconds: 900));

      expect(harness.repo.loginCallCount, 0);

      await tester.pump(const Duration(seconds: 3));
    });

    testWidgets('the shortcut fills the visible fields with what it '
        'submitted', (tester) async {
      // The prefill this screen banned was invisible-by-the-time-it-mattered;
      // this shortcut must not reintroduce that. Whatever it signs in with
      // has to be on screen.
      await pumpLogin(
        tester,
        repository: FakeAuthRepository(
          loginError: const NetworkException('offline'),
        ),
      );

      await tapHero(tester, 5);
      await tester.pumpAndSettle();

      final email = tester.widget<TextField>(find.byType(TextField).at(0));
      final password = tester.widget<TextField>(find.byType(TextField).at(1));
      expect(email.controller?.text, 'agent@lacasa.dev');
      expect(password.controller?.text, 'password123');
    });
  });

  group('password managers', () {
    testWidgets('both fields are one AutofillGroup with the right hints', (
      tester,
    ) async {
      await pumpLogin(tester);

      expect(find.byType(AutofillGroup), findsOneWidget);

      final email = tester.widget<TextField>(find.byType(TextField).at(0));
      final password = tester.widget<TextField>(find.byType(TextField).at(1));

      expect(email.autofillHints?.toList(), [
        AutofillHints.username,
        AutofillHints.email,
      ]);
      expect(password.autofillHints?.toList(), [AutofillHints.password]);
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

  // Russian is routinely 30-50% longer than English and Uzbek can run
  // longer still — re-running the same widths under both catches overflow
  // that only a longer language introduces (see l10n/README.md's plurals
  // section for the same "the ICU block only fixes correctness, not
  // layout" caveat in spirit).
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

          await pumpLogin(tester, locale: locale);

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
