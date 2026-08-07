// Widget tests for `register` (SCREENS.md §3.13, lib/features/auth/widgets/
// register_screen.dart).

import 'dart:async';

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

/// [AuthRepository.register] never resolves until [complete] is called —
/// used to put the full-screen spinner (§3.13's literal instruction) on
/// screen long enough to assert against, the same technique
/// `agents_directory_screen_test.dart`'s loading group uses a bare
/// `Completer` for.
class _HoldingAuthRepository implements AuthRepository {
  final Completer<AuthUser> _registerGate = Completer<AuthUser>();
  int registerCallCount = 0;
  Map<String, Object?>? lastRegisterArgs;

  void complete(AuthUser user) => _registerGate.complete(user);

  @override
  Future<AuthUser> register({
    required String fullName,
    required String email,
    required String password,
    String? phoneNumber,
    RealtorApplicationInput? realtor,
  }) async {
    registerCallCount++;
    lastRegisterArgs = {
      'fullName': fullName,
      'email': email,
      'password': password,
      'phoneNumber': phoneNumber,
      'realtor': realtor?.toJson(),
    };
    return _registerGate.future;
  }

  @override
  Future<AuthUser> login({required String email, required String password}) =>
      throw UnimplementedError();

  @override
  Future<AuthUser> currentUser() => throw UnimplementedError();

  @override
  Future<AuthUser> updateProfile({
    String? fullName,
    String? phoneNumber,
    String? email,
    String? avatar,
    String? password,
  }) => throw UnimplementedError();

  @override
  Future<void> signOut() async {}
}

void main() {
  Future<
    ({ProviderContainer container, GoRouter router, FakeAuthRepository repo})
  >
  pumpRegister(
    WidgetTester tester, {
    FakeAuthRepository? repository,
    bool withBackStack = true,
  }) async {
    final repo = repository ?? FakeAuthRepository();
    final container = ProviderContainer(
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
          builder: (context, state) => const Scaffold(body: Text('login-stub')),
        ),
        GoRoute(
          path: RoutePaths.register,
          builder: (context, state) => const RegisterScreen(),
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
      router.push(RoutePaths.register);
    } else {
      router.go(RoutePaths.register);
    }
    await tester.pumpAndSettle();

    return (container: container, router: router, repo: repo);
  }

  Future<
    ({ProviderContainer container, GoRouter router})
  >
  pumpRegisterWith(WidgetTester tester, AuthRepository repository) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(repository),
        hasPersistedAuthTokenProvider.overrideWithValue(false),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RoutePaths.register,
      routes: [
        GoRoute(
          path: RoutePaths.register,
          builder: (context, state) => const RegisterScreen(),
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

    return (container: container, router: router);
  }

  Future<void> fillBuyerFields(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).at(0), 'Dilnoza Yusupova');
    await tester.enterText(find.byType(TextField).at(1), '+998901234567');
    await tester.enterText(find.byType(TextField).at(2), 'dilnoza@lacasa.uz');
    await tester.enterText(find.byType(TextField).at(3), 'secret1');
  }

  /// `register` is a long single-column form — the Agency chip, the submit
  /// button and the footer link all sit below the fold on the 800x600
  /// default test surface, exactly the situation
  /// `listing_detail_screen_test.dart`'s own `scrollToAndTap` documents.
  /// `ensureVisible` before every tap (a no-op for anything already on
  /// screen) rather than shrinking the form to fit the test.
  Future<void> scrollToAndTap(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  group('fields and copy', () {
    testWidgets('renders §3.13\'s fields and the default "Sign up" button', (
      tester,
    ) async {
      await pumpRegister(tester);

      // Section labels ("I'm signing up as", the AuthField labels below) all
      // render through `.toUpperCase()` — the same small-caps visual
      // treatment `contact_sheet.dart`'s `_Field` already uses, asserted the
      // same (uppercase) way in `contact_sheet_test.dart`. The underlying
      // copy is still exactly the spec's text, just styled. Card/chip/button
      // labels (Buyer/Realtor/Sign up/…) are not uppercased.
      expect(find.text("I'M SIGNING UP AS"), findsOneWidget);
      expect(find.text('Buyer'), findsOneWidget);
      expect(find.text('Realtor'), findsOneWidget);
      expect(find.text('FULL NAME'), findsOneWidget);
      expect(find.text('PHONE NUMBER'), findsOneWidget);
      expect(find.text('EMAIL'), findsOneWidget);
      expect(find.text('PASSWORD'), findsOneWidget);
      expect(find.text('Sign up'), findsOneWidget);
      // The realtor-only controls stay hidden for the default buyer state.
      expect(find.text('REALTOR TYPE'), findsNothing);
    });

    testWidgets('choosing Realtor reveals Realtor type and swaps the button', (
      tester,
    ) async {
      await pumpRegister(tester);

      await scrollToAndTap(tester, find.text('Realtor'));

      expect(find.text('REALTOR TYPE'), findsOneWidget);
      expect(find.text('Solo agent'), findsOneWidget);
      expect(find.text('Agency'), findsOneWidget);
      expect(find.text('Create realtor account'), findsOneWidget);
      expect(find.text('Sign up'), findsNothing);
      // Solo is the default realtor kind — agency-only fields stay hidden.
      expect(find.text('Agency name'), findsNothing);
    });

    testWidgets('choosing Agency reveals agency-only fields and team size', (
      tester,
    ) async {
      await pumpRegister(tester);

      await scrollToAndTap(tester, find.text('Realtor'));
      await scrollToAndTap(tester, find.text('Agency'));

      expect(find.text('AGENCY NAME'), findsOneWidget);
      // "OFFICE PHONE", not "OFFICE PHONE (OPTIONAL)". §3.13 bolds the label
      // and leaves "(optional, same rule)" outside it, exactly as it does for
      // "Agency name" (required; …) — the field-label style uppercases, but
      // it must not add words the spec put outside the quotes.
      expect(find.text('OFFICE PHONE'), findsOneWidget);
      expect(find.text('TEAM SIZE'), findsOneWidget);
      expect(find.text('Just me for now'), findsOneWidget);
      expect(find.text('2–5'), findsOneWidget);
      expect(find.text('6–15'), findsOneWidget);
      expect(find.text('16+'), findsOneWidget);
      expect(
        find.text(
          'Realtor accounts are verified before the Work tab unlocks. '
          "We'll call the number above — usually within one business day.",
        ),
        findsOneWidget,
      );
    });

    testWidgets('the reciprocal footer link pushes to login', (tester) async {
      await pumpRegister(tester);

      await scrollToAndTap(tester, find.text('Already have an account? Sign in'));

      expect(find.text('login-stub'), findsOneWidget);
    });
  });

  group('client-side validation', () {
    testWidgets('empty required fields show "Required fields are not filled"', (
      tester,
    ) async {
      final result = await pumpRegister(tester);

      await scrollToAndTap(tester, find.text('Sign up'));

      expect(find.text('Required fields are not filled'), findsOneWidget);
      expect(result.repo.registerCallCount, 0);
    });

    testWidgets('a malformed phone shows "Invalid phone number format"', (
      tester,
    ) async {
      await pumpRegister(tester);

      await tester.enterText(find.byType(TextField).at(0), 'Dilnoza Yusupova');
      await tester.enterText(find.byType(TextField).at(1), '901234567');
      await tester.enterText(find.byType(TextField).at(2), 'dilnoza@lacasa.uz');
      await tester.enterText(find.byType(TextField).at(3), 'secret1');
      await scrollToAndTap(tester, find.text('Sign up'));

      expect(find.text('Invalid phone number format'), findsOneWidget);
    });

    testWidgets('agency without an agency name is blocked', (tester) async {
      final result = await pumpRegister(tester);

      await scrollToAndTap(tester, find.text('Realtor'));
      await scrollToAndTap(tester, find.text('Agency'));

      await fillBuyerFields(tester);
      await scrollToAndTap(tester, find.text('Create realtor account'));

      expect(find.text('Required fields are not filled'), findsOneWidget);
      expect(result.repo.registerCallCount, 0);
    });
  });

  group('success', () {
    testWidgets('a buyer signup calls registerAccount with no realtor block, then navigates home', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        registerResult: authUser(email: 'dilnoza@lacasa.uz'),
      );
      await pumpRegister(tester, repository: repo);

      await fillBuyerFields(tester);
      await scrollToAndTap(tester, find.text('Sign up'));

      expect(find.text('home-stub'), findsOneWidget);
      expect(find.text('User successfully created.'), findsOneWidget);
      expect(repo.registerCallCount, 1);
    });

    testWidgets('a solo realtor signup shows the realtor toast', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        registerResult: authUser(email: 'dilnoza@lacasa.uz'),
      );
      await pumpRegister(tester, repository: repo);

      await scrollToAndTap(tester, find.text('Realtor'));
      await fillBuyerFields(tester);
      await scrollToAndTap(tester, find.text('Create realtor account'));

      expect(find.text('home-stub'), findsOneWidget);
      expect(
        find.text(
          "Account created. We'll verify your realtor profile shortly.",
        ),
        findsOneWidget,
      );
    });
  });

  group('server errors', () {
    testWidgets('409 emailTaken renders under the Email field', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        registerError: ApiErrorException(
          statusCode: 409,
          body: const ApiErrorBody(
            code: ApiErrorCode.emailTaken,
            message: 'Email is already registered',
          ),
        ),
      );
      await pumpRegister(tester, repository: repo);

      await fillBuyerFields(tester);
      await scrollToAndTap(tester, find.text('Sign up'));

      expect(find.text('Email is already registered'), findsOneWidget);
    });

    testWidgets('a 400 validation failure shows the server message as a form banner', (
      tester,
    ) async {
      final repo = FakeAuthRepository(
        registerError: ApiErrorException(
          statusCode: 400,
          body: const ApiErrorBody(
            code: ApiErrorCode.validation,
            message: 'Password must be at least 6 characters',
          ),
        ),
      );
      await pumpRegister(tester, repository: repo);

      await fillBuyerFields(tester);
      await scrollToAndTap(tester, find.text('Sign up'));

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });
  });

  group('full-screen spinner', () {
    testWidgets('shows while the request is in flight, per §3.13', (
      tester,
    ) async {
      final holding = _HoldingAuthRepository();
      await pumpRegisterWith(tester, holding);

      await fillBuyerFields(tester);
      await tester.ensureVisible(find.text('Sign up'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Sign up'));
      await tester.pump();

      expect(find.byType(AuthFullScreenSpinner), findsOneWidget);

      holding.complete(authUser(email: 'dilnoza@lacasa.uz'));
      await tester.pumpAndSettle();

      expect(find.byType(AuthFullScreenSpinner), findsNothing);
      expect(find.text('home-stub'), findsOneWidget);
    });
  });

  group('layout holds at real phone widths', () {
    for (final size in const [
      (label: 'small android', size: Size(360, 800)),
      (label: 'iphone 14', size: Size(390, 844)),
      (label: 'pro max', size: Size(430, 932)),
    ]) {
      testWidgets('no overflow at ${size.label} with the agency form open', (
        tester,
      ) async {
        tester.view.physicalSize = size.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpRegister(tester);
        await tester.tap(find.text('Realtor'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Agency'));
        await tester.pumpAndSettle();

        expect(tester.takeException(), isNull);
      });
    }
  });
}
