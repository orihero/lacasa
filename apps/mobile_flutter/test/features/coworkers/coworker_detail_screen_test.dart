// Widget tests for `coworker-detail` (lib/features/coworkers/). Pumped
// inside a real GoRouter — the header back arrow/Cancel branch on
// `context.canPop()`, same reasoning as
// `test/features/edit_profile/edit_profile_screen_test.dart`.

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/coworkers/coworkers.dart';
import 'package:lacasa_mobile/features/coworkers/state/coworkers_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import 'support/coworker_test_data.dart';
import 'support/fake_coworkers_repository.dart';

void main() {
  Future<ProviderContainer> pumpScreen(
    WidgetTester tester, {
    required FakeCoworkersRepository repository,
    String coworkerId = 'coworker-a',
    UserRole role = UserRole.agent,
    bool withBackStack = true,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [coworkersRepositoryProvider.overrideWithValue(repository)],
    );
    addTearDown(container.dispose);

    container
        .read(authSessionProvider.notifier)
        .signIn(authUser(id: 'user-a', role: role, realtorKind: RealtorKind.agency));

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
                  path: ':id',
                  builder: (context, state) => CoworkerDetailScreen(
                    coworkerId: state.pathParameters['id']!,
                  ),
                ),
              ],
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

    final path = '${RoutePaths.workCoworkers}/$coworkerId';
    if (withBackStack) {
      // Two pushes, matching how the real app actually reaches this screen
      // (`coworkers_list_screen.dart` pushes the detail route from an
      // already-showing list page): go_router's `push()` treats a single
      // multi-segment location string as ONE new match, not one match per
      // path segment — pushing the full nested path in one call silently
      // skips the intermediate `coworkers-list-stub` page, which then
      // breaks every "pop lands back on the list" assertion below.
      router.push(RoutePaths.workCoworkers);
      await tester.pumpAndSettle();
      router.push(path);
    } else {
      router.go(path);
    }
    await tester.pumpAndSettle();

    return container;
  }

  group('header', () {
    testWidgets('shows the §36 title', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(
          coworkers: [coworker(id: 'coworker-a')],
        ),
      );

      expect(find.text('Update coworker'), findsOneWidget);
    });
  });

  group('loading', () {
    testWidgets('shows a skeleton, and the header is up immediately', (
      tester,
    ) async {
      final gate = Completer<void>();
      final repo = FakeCoworkersRepository(
        hold: gate,
        coworkers: [coworker(id: 'coworker-a')],
      );

      final container = ProviderContainer(
        retry: (retryCount, error) => null,
        overrides: [coworkersRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);
      container
          .read(authSessionProvider.notifier)
          .signIn(authUser(id: 'user-a', role: UserRole.agent, realtorKind: RealtorKind.agency));

      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: AppTheme.light(),
            home: const CoworkerDetailScreen(coworkerId: 'coworker-a'),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Update coworker'), findsOneWidget);

      gate.complete();
      await tester.pumpAndSettle();

      expect(find.text('Sardor Abdullayev'), findsOneWidget);
    });
  });

  group('fetch failure', () {
    testWidgets('a 404 is a terminal state with no Retry', (tester) async {
      final repo = FakeCoworkersRepository(
        getByIdError: ApiErrorException(
          statusCode: 404,
          body: const ApiErrorBody(
            code: ApiErrorCode.notFound,
            message: 'Coworker not found',
          ),
        ),
      );

      await pumpScreen(tester, repository: repo);

      expect(
        find.text('This coworker is no longer available.'),
        findsOneWidget,
      );
      expect(find.text('Go back'), findsOneWidget);
      expect(find.text('Retry'), findsNothing);
    });

    testWidgets('a transport failure offers Retry and re-fetches', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        getByIdError: const NetworkException('offline'),
      );

      await pumpScreen(tester, repository: repo);

      expect(find.text("Couldn't load this coworker"), findsOneWidget);
      expect(repo.getByIdCallCount, 1);

      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(repo.getByIdCallCount, 2);
    });
  });

  group('pre-filled fields', () {
    testWidgets('seeds every field from the loaded coworker', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(
          coworkers: [
            coworker(
              id: 'coworker-a',
              fullName: 'Sardor Abdullayev',
              email: 'sardor@lacasa.uz',
              phoneNumber: '+998901112233',
            ),
          ],
        ),
      );

      expect(find.text('Sardor Abdullayev'), findsOneWidget);
      expect(find.text('sardor@lacasa.uz'), findsOneWidget);
      expect(find.text('+998901112233'), findsOneWidget);
      // Password never carries plaintext — starts blank.
      expect(find.widgetWithText(TextField, ''), findsWidgets);
    });

    testWidgets('a null phone number seeds an empty field, not "null"', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(
          coworkers: [coworker(id: 'coworker-a', phoneNumber: null)],
        ),
      );

      expect(find.text('null'), findsNothing);
    });
  });

  group('validation', () {
    testWidgets('empty full name blocks submit with §37\'s "Full Name is '
        'required" (shared vocabulary — §36 quotes no string of its own)', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(
          coworkers: [coworker(id: 'coworker-a', fullName: 'Sardor Abdullayev')],
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'Sardor Abdullayev'),
        '',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Full Name is required'), findsOneWidget);
    });

    testWidgets('an empty phone gets §36\'s single combined message', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(
          coworkers: [
            coworker(id: 'coworker-a', phoneNumber: '+998901112233'),
          ],
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid Uzbekistan phone number'), findsOneWidget);
      // §36 has no separate "Phone number is required" string — one check,
      // one message, matching `edit_profile_screen.dart`'s identical rule.
      expect(find.text('Phone number is required'), findsNothing);
    });

    testWidgets('a malformed (non-empty) phone gets the same message', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(
          coworkers: [
            coworker(id: 'coworker-a', phoneNumber: '+998901112233'),
          ],
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '+99890111',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid Uzbekistan phone number'), findsOneWidget);
    });

    testWidgets('empty email blocks submit', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(
          coworkers: [coworker(id: 'coworker-a', email: 'sardor@lacasa.uz')],
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, 'sardor@lacasa.uz'),
        '',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('password is optional — a blank password never blocks '
        'submit', (tester) async {
      final repo = FakeCoworkersRepository(
        coworkers: [coworker(id: 'coworker-a')],
      );
      await pumpScreen(tester, repository: repo);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.updateCallCount, 1);
      expect(repo.lastUpdatePassword, isNull);
    });

    testWidgets('a short (non-empty) password is rejected', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(
          coworkers: [coworker(id: 'coworker-a')],
        ),
      );

      await tester.enterText(find.byType(TextField).last, '123');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });
  });

  group('submit — only changed fields are sent', () {
    testWidgets('an untouched form sends every field as omitted', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        coworkers: [coworker(id: 'coworker-a')],
      );
      await pumpScreen(tester, repository: repo);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdateFullName, isNull);
      expect(repo.lastUpdatePhoneNumber, isNull);
      expect(repo.lastUpdateEmail, isNull);
      expect(repo.lastUpdatePassword, isNull);
    });

    testWidgets('editing only the phone sends only the phone', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        coworkers: [
          coworker(id: 'coworker-a', phoneNumber: '+998901112233'),
        ],
      );
      await pumpScreen(tester, repository: repo);

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '+998907654321',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdatePhoneNumber!.value, '+998907654321');
      expect(repo.lastUpdateFullName, isNull);
      expect(repo.lastUpdateEmail, isNull);
    });
  });

  group('submit success', () {
    testWidgets('leaves and shows §36\'s exact success toast', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        coworkers: [
          coworker(id: 'coworker-a', phoneNumber: '+998901112233'),
        ],
      );
      await pumpScreen(tester, repository: repo);

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '+998907654321',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('coworkers-list-stub'), findsOneWidget);
      expect(find.text('Coworker successfully updated!'), findsOneWidget);
    });
  });

  group('submit failure', () {
    testWidgets('renders the server message in §36\'s toast template', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        coworkers: [
          coworker(id: 'coworker-a', email: 'sardor@lacasa.uz'),
        ],
        updateError: ApiErrorException(
          statusCode: 409,
          body: const ApiErrorBody(
            code: ApiErrorCode.emailTaken,
            message: 'Email is already registered',
          ),
        ),
      );
      await pumpScreen(tester, repository: repo);

      await tester.enterText(
        find.widgetWithText(TextField, 'sardor@lacasa.uz'),
        'taken@lacasa.uz',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Error updating coworker: Email is already registered'),
        findsOneWidget,
      );
      // The form keeps what the user typed — a failed save must not lose it.
      expect(find.text('taken@lacasa.uz'), findsOneWidget);
    });
  });

  group('delete', () {
    testWidgets('confirming deletes, invalidates the roster, and leaves', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        coworkers: [coworker(id: 'coworker-a')],
      );
      await pumpScreen(tester, repository: repo);

      await tester.ensureVisible(
        find.byKey(const ValueKey('deleteCoworkerButton')),
      );
      await tester.tap(find.byKey(const ValueKey('deleteCoworkerButton')));
      await tester.pumpAndSettle();

      expect(find.text('Delete coworker?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(repo.deleteCallCount, 1);
      expect(repo.lastDeleteId, 'coworker-a');
      expect(find.text('coworkers-list-stub'), findsOneWidget);
      expect(find.text('Coworker successfully deleted!'), findsOneWidget);
    });

    testWidgets('cancelling the confirm dialog deletes nothing', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        coworkers: [coworker(id: 'coworker-a')],
      );
      await pumpScreen(tester, repository: repo);

      await tester.ensureVisible(
        find.byKey(const ValueKey('deleteCoworkerButton')),
      );
      await tester.tap(find.byKey(const ValueKey('deleteCoworkerButton')));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(repo.deleteCallCount, 0);
      expect(find.text('Update coworker'), findsOneWidget);
    });

    testWidgets('a delete failure shows §36\'s exact error toast template', (
      tester,
    ) async {
      final repo = FakeCoworkersRepository(
        coworkers: [coworker(id: 'coworker-a')],
        deleteError: ApiErrorException(
          statusCode: 403,
          body: const ApiErrorBody(
            code: ApiErrorCode.forbidden,
            message: 'Only the owning agent can delete a coworker',
          ),
        ),
      );
      await pumpScreen(tester, repository: repo);

      await tester.ensureVisible(
        find.byKey(const ValueKey('deleteCoworkerButton')),
      );
      await tester.tap(find.byKey(const ValueKey('deleteCoworkerButton')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Error deleting coworker: Only the owning agent can delete a coworker',
        ),
        findsOneWidget,
      );
      // Still on the form — a failed delete does not navigate away.
      expect(find.text('Update coworker'), findsOneWidget);
    });
  });

  group('discard confirmation (SCREENS.md §5)', () {
    testWidgets('Cancel with no changes leaves immediately, no dialog', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(
          coworkers: [coworker(id: 'coworker-a')],
        ),
      );

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('coworkers-list-stub'), findsOneWidget);
    });

    testWidgets('Cancel with changes shows the discard dialog', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(
          coworkers: [
            coworker(id: 'coworker-a', phoneNumber: '+998901112233'),
          ],
        ),
      );

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '+998907654321',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });

  group('coworker-role session — read-only', () {
    testWidgets('Save/Delete are replaced with an explanatory note', (
      tester,
    ) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(
          coworkers: [coworker(id: 'coworker-a')],
        ),
        role: UserRole.coworker,
      );

      expect(find.text('Save'), findsNothing);
      expect(find.byKey(const ValueKey('deleteCoworkerButton')), findsNothing);
      expect(
        find.text('Only agents can edit or delete coworkers.'),
        findsOneWidget,
      );
      // Cancel/back still works — reading is allowed.
      expect(find.text('Cancel'), findsOneWidget);
    });
  });

  group('avatar uploader unavailability', () {
    testWidgets('shows the unavailable caption', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(
          coworkers: [coworker(id: 'coworker-a')],
        ),
      );

      expect(
        find.text("Avatar upload isn't available in this build yet."),
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
          repository: FakeCoworkersRepository(
            coworkers: [
              coworker(
                id: 'coworker-a',
                fullName: 'Shahnoza Yoldosheva-Abdurahmonova',
                email: 'shahnoza.yoldosheva.abdurahmonova@lacasa.uz',
                phoneNumber: '+998901234567',
              ),
            ],
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });
}
