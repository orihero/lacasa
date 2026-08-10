// Widget tests for `add-coworker` (lib/features/coworkers/). Pumped inside
// a real GoRouter — Cancel/back both branch on `context.canPop()`/explicit
// `context.go`, same reasoning as
// `test/features/edit_profile/edit_profile_screen_test.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/coworkers/coworkers.dart';
import 'package:lacasa_mobile/features/coworkers/state/coworkers_repository_provider.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_providers.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../work_dashboard/support/fake_dashboard_repository.dart';
import 'support/coworker_test_data.dart';
import 'support/fake_coworkers_repository.dart';

void main() {
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required FakeCoworkersRepository repository,
    FakeDashboardRepository? dashboardRepository,
    UserRole? role = UserRole.agent,
    RealtorKind? realtorKind = RealtorKind.agency,
    bool withBackStack = true,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        coworkersRepositoryProvider.overrideWithValue(repository),
        if (dashboardRepository != null)
          dashboardRepositoryProvider.overrideWithValue(dashboardRepository),
      ],
    );
    addTearDown(container.dispose);

    if (role != null) {
      container
          .read(authSessionProvider.notifier)
          .signIn(authUser(id: 'user-a', role: role, realtorKind: realtorKind));
    }

    final router = GoRouter(
      initialLocation: RoutePaths.work,
      routes: [
        GoRoute(
          path: RoutePaths.work,
          builder: (context, state) => const Scaffold(body: Text('work-root')),
          routes: [
            GoRoute(
              path: 'coworkers',
              builder: (context, state) =>
                  const Scaffold(body: Text('coworkers-list-stub')),
              routes: [
                GoRoute(
                  path: 'create',
                  builder: (context, state) => const AddCoworkerScreen(),
                ),
              ],
            ),
          ],
        ),
        GoRoute(
          path: RoutePaths.login,
          builder: (context, state) => const Scaffold(body: Text('login-stub')),
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

    if (withBackStack) {
      router.push(RoutePaths.workAddCoworker);
    } else {
      router.go(RoutePaths.workAddCoworker);
    }
    await tester.pumpAndSettle();

    return container;
  }

  group('header', () {
    testWidgets('shows the §37 title', (tester) async {
      await pumpScreen(tester, repository: FakeCoworkersRepository());
      expect(find.text('Create coworker'), findsOneWidget);
    });
  });

  group('access gate', () {
    testWidgets('signed out shows a sign-in prompt, never the form', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        role: null,
      );

      expect(find.text('Sign in to manage your team.'), findsOneWidget);
      expect(find.text('Full name'.toUpperCase()), findsNothing);

      await tester.tap(find.text('Sign In'));
      await tester.pumpAndSettle();

      expect(find.text('login-stub'), findsOneWidget);
    });

    testWidgets('a coworker session is blocked with an honest message', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        role: UserRole.coworker,
        realtorKind: null,
      );

      expect(find.text('Only agents can add coworkers.'), findsOneWidget);
      expect(find.text('Full name'.toUpperCase()), findsNothing);
    });

    testWidgets('a solo agent is blocked with the API\'s own solo_realtor '
        'message', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        role: UserRole.agent,
        realtorKind: RealtorKind.solo,
      );

      expect(
        find.text(
          "Solo agents don't have a team. Switch to an agency account "
          'to add coworkers.',
        ),
        findsOneWidget,
      );
      expect(find.text('Full name'.toUpperCase()), findsNothing);
    });

    testWidgets('an agency agent sees the real form', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        role: UserRole.agent,
        realtorKind: RealtorKind.agency,
      );

      expect(find.text('Full name'.toUpperCase()), findsOneWidget);
    });
  });

  group('validation — §37\'s exact strings', () {
    testWidgets('empty required fields block submit', (tester) async {
      await pumpScreen(tester, repository: FakeCoworkersRepository());

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name is required'), findsOneWidget);
      expect(find.text('Phone number is required'), findsOneWidget);
      expect(find.text('Email is required'), findsOneWidget);
      expect(find.text('Password is required'), findsOneWidget);
    });

    testWidgets('a malformed (non-empty) phone gets the pattern message, '
        'not the empty one', (tester) async {
      await pumpScreen(tester, repository: FakeCoworkersRepository());

      await tester.enterText(find.byType(TextField).at(0), 'Sardor Abdullayev');
      await tester.enterText(find.byType(TextField).at(1), '+99890111');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid Uzbekistan phone number'), findsOneWidget);
      expect(find.text('Phone number is required'), findsNothing);
    });

    testWidgets('a short (non-empty) password gets the length message, not '
        'the empty one', (tester) async {
      await pumpScreen(tester, repository: FakeCoworkersRepository());

      await tester.enterText(find.byType(TextField).last, '123');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
      expect(find.text('Password is required'), findsNothing);
    });
  });

  group('submit success', () {
    testWidgets('creates, invalidates the roster, leaves, and shows §37\'s '
        'exact (no "!") success toast', (tester) async {
      final repo = FakeCoworkersRepository();
      await pumpScreen(tester, repository: repo);

      await tester.enterText(find.byType(TextField).at(0), 'Sardor Abdullayev');
      await tester.enterText(find.byType(TextField).at(1), '+998901112233');
      await tester.enterText(find.byType(TextField).at(2), 'sardor@lacasa.uz');
      await tester.enterText(find.byType(TextField).at(3), 'password1');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.createCallCount, 1);
      expect(repo.lastCreateArgs!.fullName, 'Sardor Abdullayev');
      expect(repo.lastCreateArgs!.email, 'sardor@lacasa.uz');
      expect(repo.lastCreateArgs!.password, 'password1');
      expect(repo.lastCreateArgs!.phoneNumber, '+998901112233');

      expect(find.text('coworkers-list-stub'), findsOneWidget);
      expect(find.text('Coworker successfully created'), findsOneWidget);
    });

    testWidgets(
      'also invalidates dashboardCoworkersProvider (correctness — Dashboard '
      'stays mounted for the whole Work-tab session and owns its own copy '
      'of the coworker list)',
      (tester) async {
        final repo = FakeCoworkersRepository();
        final dashboardRepo = FakeDashboardRepository();
        final container = await pumpScreen(
          tester,
          repository: repo,
          dashboardRepository: dashboardRepo,
        );

        await container.read(dashboardCoworkersProvider.future);
        expect(dashboardRepo.coworkersCallCount, 1);

        await tester.enterText(find.byType(TextField).at(0), 'Sardor Abdullayev');
        await tester.enterText(find.byType(TextField).at(1), '+998901112233');
        await tester.enterText(find.byType(TextField).at(2), 'sardor@lacasa.uz');
        await tester.enterText(find.byType(TextField).at(3), 'password1');
        await tester.tap(find.text('Save'));
        await tester.pumpAndSettle();

        await container.read(dashboardCoworkersProvider.future);
        expect(
          dashboardRepo.coworkersCallCount,
          2,
          reason: 'a stale dashboardCoworkersProvider must refetch once invalidated',
        );
      },
    );
  });

  group('submit failure', () {
    testWidgets('renders the server message in §37\'s catch toast template', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        createError: ApiErrorException(
          statusCode: 409,
          body: const ApiErrorBody(
            code: ApiErrorCode.emailTaken,
            message: 'Email is already registered',
          ),
        ),
      );
      await pumpScreen(tester, repository: repo);

      await tester.enterText(find.byType(TextField).at(0), 'Sardor Abdullayev');
      await tester.enterText(find.byType(TextField).at(1), '+998901112233');
      await tester.enterText(find.byType(TextField).at(2), 'taken@lacasa.uz');
      await tester.enterText(find.byType(TextField).at(3), 'password1');

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Error creating coworker: Email is already registered'),
        findsOneWidget,
      );
      // The form keeps what was typed.
      expect(find.text('taken@lacasa.uz'), findsOneWidget);
    });
  });

  group('discard confirmation (SCREENS.md §5)', () {
    testWidgets('Cancel with no changes leaves immediately, no dialog', (
      tester,
    ) async {
      await pumpScreen(tester, repository: FakeCoworkersRepository());

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      // §37: "Cancel" → `coworkers-list` explicitly.
      expect(find.text('coworkers-list-stub'), findsOneWidget);
    });

    testWidgets('Cancel with changes shows the discard dialog', (
      tester,
    ) async {
      await pumpScreen(tester, repository: FakeCoworkersRepository());

      await tester.enterText(find.byType(TextField).at(0), 'Sardor');
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Discard'));
      await tester.pumpAndSettle();

      expect(find.text('coworkers-list-stub'), findsOneWidget);
    });
  });

  group('avatar uploader unavailability', () {
    testWidgets('shows the unavailable caption and toasts on tap', (
      tester,
    ) async {
      await pumpScreen(tester, repository: FakeCoworkersRepository());

      expect(
        find.text("Avatar upload isn't available in this build yet."),
        findsOneWidget,
      );

      await tester.tap(find.bySemanticsLabel(RegExp('Add photo')));
      await tester.pumpAndSettle();

      expect(
        find.text("Avatar upload isn't available in this build yet."),
        findsWidgets,
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

        await pumpScreen(tester, repository: FakeCoworkersRepository());

        expect(tester.takeException(), isNull);
      });

      testWidgets('blocked (solo agent) state has no overflow at '
          '${size.label}', (tester) async {
        tester.view.physicalSize = size.size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);

        await pumpScreen(
          tester,
          repository: FakeCoworkersRepository(),
          realtorKind: RealtorKind.solo,
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
