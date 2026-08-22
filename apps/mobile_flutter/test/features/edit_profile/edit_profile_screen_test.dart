// Widget tests for `edit-profile` (lib/features/edit_profile/). Pumped
// inside a real GoRouter, like agent_profile_screen_test.dart — the header
// back arrow and Cancel button both branch on `context.canPop()`, and a
// successful save exits the same way.

import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/auth/state/auth_repository_provider.dart';
import 'package:lacasa_mobile/features/edit_profile/edit_profile.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/shared/platform/media_picker.dart';
import 'package:lacasa_mobile/shared/state/uploads_repository.dart';
import 'package:lacasa_mobile/shared/state/uploads_repository_provider.dart';
import 'package:lacasa_mobile/shared/widgets/agent_avatar.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../shared/support/fake_media_picker.dart';
import '../../shared/support/fake_uploads_repository.dart';
import 'support/recording_auth_repository.dart';

AuthUser _user({
  String fullName = 'Dilnoza Yusupova',
  String email = 'buyer@lacasa.uz',
  String? phoneNumber = '+998901112233',
  String? avatar,
}) {
  return AuthUser.fromJson({
    'id': 'user-1',
    'fullName': fullName,
    'email': email,
    'role': 'user',
    'phoneNumber': phoneNumber,
    'avatar': avatar,
    'agentId': null,
    'tgChatIds': <int>[],
    'igAccounts': <Map<String, dynamic>>[],
    'igAssistConsentAt': null,
    'realtor': null,
  });
}

void main() {
  /// Pumps `EditProfileScreen` at `/profile/edit`, with `/profile` as the
  /// route below it so `canPop()` is true — the ordinary case (this screen
  /// is always reached by a push from `profile-buyer`/`profile-agent`).
  Future<
    ({
      ProviderContainer container,
      GoRouter router,
      RecordingAuthRepository repository,
    })
  >
  pumpScreen(
    WidgetTester tester, {
    RecordingAuthRepository? repository,
    AuthUser? signedInUser,
    bool withBackStack = true,
    // Both default to `null` (i.e. "leave the real provider in place"),
    // same reasoning as `add_coworker_screen_test.dart`'s `pumpScreen` —
    // only the "real avatar uploader" group below ever taps the avatar
    // control, so there is nothing for these to fake in every other test.
    MediaPicker? mediaPicker,
    UploadsRepository? uploadsRepository,
    Locale locale = const Locale('en'),
  }) async {
    final repo = repository ?? RecordingAuthRepository();
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        authRepositoryProvider.overrideWithValue(repo),
        hasPersistedAuthTokenProvider.overrideWithValue(false),
        if (mediaPicker != null)
          mediaPickerProvider.overrideWithValue(mediaPicker),
        if (uploadsRepository != null)
          uploadsRepositoryProvider.overrideWithValue(uploadsRepository),
      ],
    );
    addTearDown(container.dispose);

    if (signedInUser != null) {
      container.read(authSessionProvider.notifier).signIn(signedInUser);
    }

    final router = GoRouter(
      initialLocation: '/profile',
      routes: [
        GoRoute(
          path: '/profile',
          builder: (context, state) =>
              const Scaffold(body: Text('profile-root')),
          routes: [
            GoRoute(
              path: 'edit',
              builder: (context, state) =>
                  const EditProfileScreen(branchPrefix: '/profile'),
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
      router.push('/profile/edit');
    } else {
      router.go('/profile/edit');
    }
    await tester.pumpAndSettle();

    return (container: container, router: router, repository: repo);
  }

  group('pre-filled fields', () {
    testWidgets('seeds every field from the signed-in user', (tester) async {
      await pumpScreen(
        tester,
        signedInUser: _user(
          fullName: 'Dilnoza Yusupova',
          email: 'dilnoza@lacasa.uz',
          phoneNumber: '+998901112233',
        ),
      );

      expect(find.text('Edit Profile'), findsOneWidget);
      expect(find.text('Dilnoza Yusupova'), findsOneWidget);
      expect(find.text('dilnoza@lacasa.uz'), findsOneWidget);
      expect(find.text('+998901112233'), findsOneWidget);
      // Password always starts blank — there is no plaintext to seed it
      // with, and a blank field is exactly "not changing" per §3.18.
      expect(find.widgetWithText(TextField, ''), findsWidgets);
    });

    testWidgets('a null phone number seeds an empty field, not "null"', (
      tester,
    ) async {
      await pumpScreen(tester, signedInUser: _user(phoneNumber: null));

      expect(find.text('null'), findsNothing);
    });
  });

  group('signed-out fallback', () {
    testWidgets('shows an honest message instead of a form bound to '
        'nothing', (tester) async {
      final result = await pumpScreen(tester, withBackStack: false);

      expect(find.text('Sign in to edit your profile.'), findsOneWidget);
      expect(find.text('Full name'.toUpperCase()), findsNothing);

      await tester.tap(find.text('Go back'));
      await tester.pumpAndSettle();

      expect(find.text('profile-root'), findsOneWidget);
      // Nothing to leave via the auth foundation when there was never a
      // form to submit.
      expect(result.repository.updateProfileCallCount, 0);
    });
  });

  group('validation', () {
    testWidgets('empty full name blocks submit with §3.18\'s exact message', (
      tester,
    ) async {
      await pumpScreen(tester, signedInUser: _user());

      await tester.enterText(
        find.widgetWithText(TextField, 'Dilnoza Yusupova'),
        '',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('First name is required'), findsOneWidget);
    });

    testWidgets('a malformed phone number is rejected', (tester) async {
      await pumpScreen(tester, signedInUser: _user());

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '+99890111',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Invalid Uzbekistan phone number'), findsOneWidget);
    });

    testWidgets('empty email blocks submit', (tester) async {
      await pumpScreen(tester, signedInUser: _user(email: 'buyer@lacasa.uz'));

      await tester.enterText(
        find.widgetWithText(TextField, 'buyer@lacasa.uz'),
        '',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('Email is required'), findsOneWidget);
    });

    testWidgets('a short password is rejected only when non-empty', (
      tester,
    ) async {
      await pumpScreen(tester, signedInUser: _user());

      await tester.enterText(find.byType(TextField).last, '123');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Password must be at least 6 characters'),
        findsOneWidget,
      );
    });

    testWidgets('a blank password never blocks submit', (tester) async {
      final result = await pumpScreen(
        tester,
        signedInUser: _user(),
        repository: RecordingAuthRepository(updateProfileResult: _user()),
      );

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(result.repository.updateProfileCallCount, 1);
      expect(result.repository.lastUpdateProfileArgs!.password, isNull);
    });
  });

  group('submit — only changed fields are sent', () {
    testWidgets('an untouched form sends every field as null', (tester) async {
      final repo = RecordingAuthRepository(updateProfileResult: _user());
      await pumpScreen(tester, signedInUser: _user(), repository: repo);

      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final args = repo.lastUpdateProfileArgs!;
      expect(args.fullName, isNull);
      expect(args.phoneNumber, isNull);
      expect(args.email, isNull);
      expect(args.password, isNull);
    });

    testWidgets('editing only the phone sends only the phone', (tester) async {
      final repo = RecordingAuthRepository(updateProfileResult: _user());
      await pumpScreen(tester, signedInUser: _user(), repository: repo);

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '+998907654321',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      final args = repo.lastUpdateProfileArgs!;
      expect(args.phoneNumber, '+998907654321');
      expect(args.fullName, isNull);
      expect(args.email, isNull);
      expect(args.password, isNull);
    });

    testWidgets('a changed password is sent; a session refresh follows', (
      tester,
    ) async {
      final updated = _user(fullName: 'Dilnoza Yusupova');
      final repo = RecordingAuthRepository(updateProfileResult: updated);
      final result = await pumpScreen(
        tester,
        signedInUser: _user(),
        repository: repo,
      );

      await tester.enterText(find.byType(TextField).last, 'newpassword');
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(repo.lastUpdateProfileArgs!.password, 'newpassword');
      // AuthSessionNotifier.signIn was called with the server's response —
      // the session must not still be stuck on the pre-edit user.
      expect(result.container.read(authSessionProvider).user, updated);
    });
  });

  group('submit success', () {
    testWidgets('pops and shows §3.18\'s exact success toast', (tester) async {
      final repo = RecordingAuthRepository(updateProfileResult: _user());
      await pumpScreen(tester, signedInUser: _user(), repository: repo);

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '+998907654321',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(find.text('profile-root'), findsOneWidget);
      expect(find.text('Profile successfully updated!'), findsOneWidget);

      // §10.4 — both of this screen's toasts used to be bare SnackBars,
      // rendering Material's docked dark-grey bar with no status glyph while
      // the avatar-upload failures three lines away already used the §5
      // floating card toast.
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
  });

  group('submit failure', () {
    testWidgets('renders the server\'s emailTaken message in the toast '
        'template', (tester) async {
      final repo = RecordingAuthRepository(
        updateProfileError: ApiErrorException(
          statusCode: 409,
          body: const ApiErrorBody(
            code: ApiErrorCode.emailTaken,
            message: 'Email is already registered',
          ),
        ),
      );
      await pumpScreen(tester, signedInUser: _user(), repository: repo);

      await tester.enterText(
        find.widgetWithText(TextField, 'buyer@lacasa.uz'),
        'taken@lacasa.uz',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text('Error updating profile: Email is already registered'),
        findsOneWidget,
      );
      // §10.4 — and an *error* toast, with the 4s budget and the red glyph,
      // not the same anonymous grey bar a success used to get.
      expect(
        find.descendant(
          of: find.byType(SnackBar),
          matching: find.byIcon(Icons.error_rounded),
        ),
        findsOneWidget,
      );
      // The form is left in place with the entered value — a failed save
      // must not lose what the user typed.
      expect(find.text('taken@lacasa.uz'), findsOneWidget);
    });

    testWidgets('a network failure gets a friendly, non-server message', (
      tester,
    ) async {
      final repo = RecordingAuthRepository(
        updateProfileError: const NetworkException('offline'),
      );
      await pumpScreen(tester, signedInUser: _user(), repository: repo);

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '+998907654321',
      );
      await tester.tap(find.text('Save'));
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Error updating profile: No connection. Check your network and '
          'try again.',
        ),
        findsOneWidget,
      );
    });
  });

  group('discard confirmation (SCREENS.md §5)', () {
    testWidgets('Cancel with no changes leaves immediately, no dialog', (
      tester,
    ) async {
      await pumpScreen(tester, signedInUser: _user());

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('profile-root'), findsOneWidget);
    });

    testWidgets('Cancel with changes shows "Discard changes?" and honours '
        '"Cancel" on the dialog', (tester) async {
      await pumpScreen(tester, signedInUser: _user());

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '+998907654321',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);

      // The dialog's own "Cancel" — keep editing, stay on the form.
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('profile-root'), findsNothing);
      expect(find.text('+998907654321'), findsOneWidget);
    });

    testWidgets('"Discard" on the dialog actually leaves', (tester) async {
      await pumpScreen(tester, signedInUser: _user());

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '+998907654321',
      );
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(TextButton, 'Discard'));
      await tester.pumpAndSettle();

      expect(find.text('profile-root'), findsOneWidget);
    });

    testWidgets('reverting a field back to its original value clears the '
        'dirty flag — no dialog on Cancel', (tester) async {
      await pumpScreen(
        tester,
        signedInUser: _user(phoneNumber: '+998901112233'),
      );

      final field = find.widgetWithText(TextField, '+998901112233');
      await tester.enterText(field, '+998907654321');
      await tester.pump();
      await tester.enterText(
        find.widgetWithText(TextField, '+998907654321'),
        '+998901112233',
      );
      await tester.pump();

      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('profile-root'), findsOneWidget);
    });

    testWidgets('PopScope.canPop tracks the live dirty flag', (tester) async {
      await pumpScreen(tester, signedInUser: _user());

      // `find.byType(PopScope)` (no type argument) does not match: the
      // widget in `edit_profile_screen.dart` is constructed as a bare
      // `PopScope(...)`, which Dart infers a concrete type argument for from
      // its `onPopInvokedWithResult` closure — not `dynamic` — so an
      // unparameterized `PopScope` type object never equals its runtime
      // type. A predicate sidesteps the exact type argument entirely (the
      // same reason Flutter's own framework tests spell out
      // `PopScope<Object?>` explicitly rather than relying on inference).
      PopScope popScope() =>
          tester.widget(find.byWidgetPredicate((w) => w is PopScope));

      expect(popScope().canPop, isTrue);

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '+998907654321',
      );
      await tester.pump();

      expect(popScope().canPop, isFalse);
    });

    testWidgets('the header back arrow goes through the same discard check '
        'as Cancel', (tester) async {
      await pumpScreen(tester, signedInUser: _user());

      await tester.enterText(
        find.widgetWithText(TextField, '+998901112233'),
        '+998907654321',
      );
      await tester.tap(find.bySemanticsLabel('Back'));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });

  // Was "avatar uploader unavailability" — that framing (and its literal
  // "Photo upload isn't available in this build yet." caption plus a
  // `PermissionGateway` seam to assert against) described the honest
  // stand-in this screen used before `shared/widgets/avatar_upload_control
  // .dart` and its `MediaPicker`/`UploadsRepository` seams existed.
  // `edit_profile_screen.dart`'s own file doc comment now says plainly
  // that the avatar control is "a real picker" and that this screen
  // deliberately does **not** go through `PermissionGateway` (a second,
  // app-level prompt on top of `image_picker`'s own OS prompt would be a
  // worse experience) — so asserting the old "unavailable" copy and a
  // gateway call would be asserting a screen state that can no longer
  // occur, not a real regression. Rewritten below to exercise the
  // control's actual contract (tap → camera/gallery choice →
  // `MediaPicker.pickImage` → `UploadsRepository.upload` →
  // `onUploaded`/`onError`) via the same `FakeMediaPicker`/
  // `FakeUploadsRepository` seams `test/shared/support/` already provides
  // for exactly this purpose — same pattern as
  // `add_coworker_screen_test.dart`'s "the real avatar uploader" group.
  group('the real avatar uploader (AvatarUploadControl)', () {
    testWidgets('is labelled "Change photo" per §3.18, with the '
        'placeholder initials avatar showing before anything is picked', (
      tester,
    ) async {
      await pumpScreen(tester, signedInUser: _user());

      expect(find.bySemanticsLabel(RegExp('Change photo')), findsOneWidget);
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
        signedInUser: _user(),
        mediaPicker: FakeMediaPicker(imageResult: media),
        uploadsRepository: FakeUploadsRepository(
          result: 'https://example.test/avatars/new.jpg',
        ),
      );

      await tester.tap(find.bySemanticsLabel(RegExp('Change photo')));
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
        signedInUser: _user(),
        mediaPicker: FakeMediaPicker(
          error: const MediaPickerException(
            "La Casa doesn't have permission to use the camera or photo "
            'library. Allow it in system settings, then try again.',
          ),
        ),
      );

      await tester.tap(find.bySemanticsLabel(RegExp('Change photo')));
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

  group('password visibility toggle', () {
    testWidgets('starts obscured and toggles on tap', (tester) async {
      await pumpScreen(tester, signedInUser: _user());

      final passwordField = find.byType(TextField).last;
      expect(tester.widget<TextField>(passwordField).obscureText, isTrue);

      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      expect(tester.widget<TextField>(passwordField).obscureText, isFalse);
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
          signedInUser: _user(
            fullName: 'Shahnoza Yoldosheva-Abdurahmonova',
            email: 'shahnoza.yoldosheva.abdurahmonova@lacasa.uz',
            phoneNumber: '+998901234567',
          ),
        );

        expect(tester.takeException(), isNull);
      });
    }
  });

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

          await pumpScreen(
            tester,
            signedInUser: _user(
              fullName: 'Shahnoza Yoldosheva-Abdurahmonova',
              email: 'shahnoza.yoldosheva.abdurahmonova@lacasa.uz',
              phoneNumber: '+998901234567',
            ),
            locale: locale,
          );

          expect(tester.takeException(), isNull);
        });
      }
    }
  });
}
