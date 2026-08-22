// Widget tests for `add-coworker` (lib/features/coworkers/). Pumped inside
// a real GoRouter — Cancel/back both branch on `context.canPop()`/explicit
// `context.go`, same reasoning as
// `test/features/edit_profile/edit_profile_screen_test.dart`.

import 'dart:typed_data';

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
import 'package:lacasa_mobile/shared/platform/media_picker.dart';
import 'package:lacasa_mobile/shared/state/uploads_repository.dart';
import 'package:lacasa_mobile/shared/state/uploads_repository_provider.dart';
import 'package:lacasa_mobile/shared/widgets/agent_avatar.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../shared/support/fake_media_picker.dart';
import '../../shared/support/fake_uploads_repository.dart';
import '../work_dashboard/support/fake_dashboard_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
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
    // Both default to `null` (i.e. "leave the real provider in place") —
    // every test in this file except the "real avatar uploader" group
    // below never taps the avatar control, so there is nothing for these
    // to fake and no reason to force every other test to pass a fake it
    // doesn't use.
    MediaPicker? mediaPicker,
    UploadsRepository? uploadsRepository,
  }) async {
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        coworkersRepositoryProvider.overrideWithValue(repository),
        if (dashboardRepository != null)
          dashboardRepositoryProvider.overrideWithValue(dashboardRepository),
        if (mediaPicker != null) mediaPickerProvider.overrideWithValue(mediaPicker),
        if (uploadsRepository != null)
          uploadsRepositoryProvider.overrideWithValue(uploadsRepository),
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
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
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

  // Was "avatar uploader unavailability" — that framing (and its literal
  // "Avatar upload isn't available in this build yet." caption) described
  // `MediaUploadUnavailableNotice`, the honest stand-in this screen used
  // before `shared/widgets/avatar_upload_control.dart` and its
  // `MediaPicker`/`UploadsRepository` seams existed. `add_coworker_screen
  // .dart`'s own doc comment now says plainly that it renders "a real
  // avatar uploader ([AvatarUploadControl])", so asserting the old
  // "unavailable" copy would be asserting a screen state that can no
  // longer occur — not a real regression, just stale test intent. Rewritten
  // below to exercise the control's actual contract (tap → camera/gallery
  // choice → `MediaPicker.pickImage` → `UploadsRepository.upload` →
  // `onUploaded`/`onError`) via the same `FakeMediaPicker`/
  // `FakeUploadsRepository` seams `test/shared/support/` already provides
  // for exactly this purpose.
  group('the real avatar uploader (AvatarUploadControl)', () {
    testWidgets('is labelled "Add photo" per §37, with the placeholder '
        'initials avatar showing before anything is picked', (tester) async {
      await pumpScreen(tester, repository: FakeCoworkersRepository());

      expect(find.bySemanticsLabel(RegExp('Add photo')), findsOneWidget);
      final avatar = tester.widget<AgentAvatar>(find.byType(AgentAvatar));
      expect(avatar.avatarUrl, isNull);
    });

    testWidgets('tapping it opens the camera/gallery choice, and picking '
        'gallery uploads the photo and swaps in its URL', (tester) async {
      final media = PickedMedia(
        bytes: Uint8List.fromList([1, 2, 3]),
        fileName: 'selfie.jpg',
        mimeType: 'image/jpeg',
      );
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        mediaPicker: FakeMediaPicker(imageResult: media),
        uploadsRepository: FakeUploadsRepository(
          result: 'https://example.test/avatars/new.jpg',
        ),
      );

      await tester.tap(find.bySemanticsLabel(RegExp('Add photo')));
      await tester.pumpAndSettle();

      // The camera/gallery choice sheet (media_source_sheet.dart) — both
      // rows are on screen once the sheet has settled.
      expect(find.text('Camera'), findsOneWidget);
      expect(find.text('Choose from library'), findsOneWidget);

      await tester.tap(find.bySemanticsLabel(RegExp('Choose from library')));
      await tester.pumpAndSettle();

      final avatar = tester.widget<AgentAvatar>(find.byType(AgentAvatar));
      expect(avatar.avatarUrl, 'https://example.test/avatars/new.jpg');
    });

    testWidgets('a denied-permission failure from the picker is shown as '
        'an error toast, not silently swallowed', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeCoworkersRepository(),
        mediaPicker: FakeMediaPicker(
          error: const MediaPickerException(
            "La Casa doesn't have permission to use the camera or photo "
            'library. Allow it in system settings, then try again.',
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel(RegExp('Add photo')));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('Choose from library')));
      await tester.pumpAndSettle();

      expect(
        find.text(
          "La Casa doesn't have permission to use the camera or photo "
          'library. Allow it in system settings, then try again.',
        ),
        findsOneWidget,
      );
      // The picker never got as far as producing bytes, so the avatar
      // stays on the initials placeholder rather than showing a broken
      // preview.
      final avatar = tester.widget<AgentAvatar>(find.byType(AgentAvatar));
      expect(avatar.avatarUrl, isNull);
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
