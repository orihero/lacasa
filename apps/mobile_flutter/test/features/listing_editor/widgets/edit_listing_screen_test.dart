// Widget tests for `edit-listing` (SCREENS.md §27).

import 'dart:async';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/listing_editor/listing_editor.dart';
import 'package:lacasa_mobile/features/listing_editor/state/listing_editor_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/shared/platform/media_picker.dart';
import 'package:lacasa_mobile/shared/state/uploads_repository_provider.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../../shared/support/fake_media_picker.dart';
import '../../../shared/support/fake_uploads_repository.dart';
import '../../../support/ambient_repository_overrides.dart';
import '../support/fake_listing_editor_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<
    ({ProviderContainer container, GoRouter router, FakeListingEditorRepository repository})
  >
  pumpScreen(
    WidgetTester tester, {
    FakeListingEditorRepository? repository,
    String adId = 'ad-1001',
    UserRole role = UserRole.agent,
    FakeMediaPicker? mediaPicker,
    FakeUploadsRepository? uploadsRepository,
  }) async {
    final repo = repository ?? FakeListingEditorRepository(ad: testAd(id: adId));
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        ...ambientRepositoryOverrides(
          listingEditor: false,
          uploads: uploadsRepository == null,
        ),
        listingEditorRepositoryProvider.overrideWithValue(repo),
        // §27 embeds `create-listing`'s own PhotosStep as the "new-upload
        // picker", so this screen needs the same two platform seams that
        // file's tests do — see `create_listing_screen_test.dart`.
        if (mediaPicker != null)
          mediaPickerProvider.overrideWithValue(mediaPicker),
        if (uploadsRepository != null)
          uploadsRepositoryProvider.overrideWithValue(uploadsRepository),
      ],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).setRole(role);

    // Both routes are declared as *children* of `my-listings`, not as flat
    // top-level siblings of it, because that is how `app_router.dart`
    // declares the real ones (`/work/my-listings/edit-listing/:id`,
    // `/work/my-listings/publish-status/:id`). The nesting is the thing
    // under test as much as the screen is: it is what makes either path
    // resolve to a stack with My Ads underneath it — so a Back, a discard,
    // or a `go` from another branch all reveal that list rather than
    // nothing. A flat stub tree would happily pass a shape the real tree
    // would fail on, which is exactly the defect this mirrors away.
    final router = GoRouter(
      initialLocation: RoutePaths.workMyListings,
      routes: [
        GoRoute(
          path: RoutePaths.workMyListings,
          builder: (context, state) => const Scaffold(body: Text('my-listings-root')),
          routes: [
            GoRoute(
              path: 'edit-listing/:id',
              builder: (context, state) =>
                  EditListingScreen(adId: state.pathParameters['id']!),
            ),
            // §29's own screen stands in as a stub: what these tests are
            // about is *how* the Publish Status link navigates (push, not
            // go — see `publish_section.dart`), not what it lands on.
            // `publish-status` has its own test file.
            GoRoute(
              path: 'publish-status/:id',
              builder: (context, state) => Scaffold(
                body: Text('publish-status-stub-${state.pathParameters['id']}'),
              ),
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(localizationsDelegates: AppLocalizations.localizationsDelegates, supportedLocales: AppLocalizations.supportedLocales, theme: AppTheme.light(), routerConfig: router),
      ),
    );
    await tester.pumpAndSettle();

    // `push`, matching `my_listings_screen.dart`'s real edit icon. The
    // `withBackStack: false` knob this helper used to carry (a `go` to the
    // same path, to simulate arriving with nothing underneath) is gone
    // along with the flat route shape that made it mean anything: now that
    // `edit-listing` is declared under `my-listings`, a `go` builds the
    // same two-page `[my-listings, edit-listing]` stack this `push` does,
    // so there is no "entered with no back stack" state left to set up.
    // That is the re-parenting working, not a case left untested.
    router.push(RoutePaths.workEditListing.replaceFirst(':id', adId));
    await tester.pumpAndSettle();

    return (container: container, router: router, repository: repo);
  }

  // The form's Save/Delete buttons sit below the fold of the form's
  // `SingleChildScrollView` at the default 800x600 test surface. A
  // simulated `tester.drag`/`ensureVisible` gesture on the scroll view
  // proved unreliable here (a touch-slop-consuming drag starting mid-form
  // can get contested by a field's own gesture detector and net only a few
  // pixels of scroll), so jump the underlying `ScrollPosition` directly —
  // deterministic and immune to gesture-arena contention.
  //
  // A prior `enterText` leaves the field focused, and `EditableText`
  // schedules its own one-shot "scroll the caret into view" animation for
  // the next frame — `pumpAndSettle()` here would let that animation run
  // to completion and scroll the form back toward the (still-focused)
  // field, undoing this jump. Callers that call `enterText` first must
  // `pumpAndSettle()` themselves right after so that follow-caret scroll
  // settles *before* this jump runs; this helper deliberately pumps once
  // (enough for `jumpTo`'s own synchronous position change to relayout)
  // rather than settling, so it never re-triggers or races that animation.
  Future<void> scrollToBottom(WidgetTester tester) async {
    final scrollable = tester.state<ScrollableState>(find.byType(Scrollable).first);
    scrollable.position.jumpTo(scrollable.position.maxScrollExtent);
    await tester.pump();
  }

  group('states', () {
    testWidgets('shows a skeleton while loading, then the pre-filled form', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeListingEditorRepository(
          ad: testAd(title: 'Bright 3-room apartment', city: 'Tashkent'),
        ),
      );

      expect(find.text('Bright 3-room apartment'), findsOneWidget);
      expect(find.text('Tashkent'), findsOneWidget);
      // No Hashtags field, per §27.
      expect(find.byKey(const ValueKey('listingField-hashtags')), findsNothing);
    });

    testWidgets('a failed fetch offers Retry, which re-fetches', (tester) async {
      final repository = FakeListingEditorRepository()
        ..getByIdError = const NetworkException('offline');
      await pumpScreen(tester, repository: repository);

      expect(find.text("Couldn't load this listing."), findsOneWidget);

      repository
        ..getByIdError = null
        ..ad = testAd(title: 'Recovered listing');
      await tester.tap(find.text('Retry'));
      await tester.pumpAndSettle();

      expect(find.text('Recovered listing'), findsOneWidget);
    });
  });

  group('validation', () {
    testWidgets('Save blocks with inline errors when a required field is cleared', (
      tester,
    ) async {
      await pumpScreen(tester, repository: FakeListingEditorRepository(ad: testAd()));

      await tester.enterText(find.byKey(const ValueKey('listingField-title')), '');
      await tester.pumpAndSettle();
      await scrollToBottom(tester);
      await tester.tap(find.byKey(const ValueKey('editListing-save')));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
    });
  });

  group('save', () {
    testWidgets('sends the edited fields and shows the success toast', (tester) async {
      // A gate on the fake's `update()` — otherwise a bare `async` method
      // with no real `await` resolves within the same microtask flush that
      // `tap()` itself already triggers, and the pending "Updating" toast
      // gets replaced by the success toast before this test's own single
      // `pump()` ever gets to observe it (see the fake's own doc comment).
      final gate = Completer<void>();
      final repository = FakeListingEditorRepository(ad: testAd(id: 'ad-2002'), hold: gate);
      final result = await pumpScreen(tester, repository: repository, adId: 'ad-2002');

      await tester.enterText(
        find.byKey(const ValueKey('listingField-title')),
        'Updated title',
      );
      await tester.pumpAndSettle();
      await scrollToBottom(tester);
      await tester.tap(find.byKey(const ValueKey('editListing-save')));
      await tester.pump();
      expect(find.text('Updating'), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();

      expect(result.repository.updateCalls, 1);
      expect(result.repository.lastUpdateId, 'ad-2002');
      expect(result.repository.lastUpdateInput!.title!.value, 'Updated title');
      // No Hashtags on edit — never sent.
      expect(result.repository.lastUpdateInput!.hashtags, isNull);
      expect(find.text('Successfully updated'), findsOneWidget);
    });

    testWidgets('deleting an existing photo persists on Save', (tester) async {
      final repository = FakeListingEditorRepository(
        ad: testAd(photos: const ['https://example.test/a.jpg', 'https://example.test/b.jpg']),
      );
      final result = await pumpScreen(tester, repository: repository);

      expect(find.byKey(const ValueKey('existingPhoto-0')), findsOneWidget);
      await tester.ensureVisible(find.byKey(const ValueKey('existingPhoto-remove-0')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('existingPhoto-remove-0')));
      await tester.pumpAndSettle();

      await scrollToBottom(tester);
      await tester.tap(find.byKey(const ValueKey('editListing-save')));
      await tester.pumpAndSettle();

      expect(result.repository.lastUpdateInput!.photos!.value, [
        'https://example.test/b.jpg',
      ]);
    });

    testWidgets('a server failure shows "Something went wrong." and stays on the form', (
      tester,
    ) async {
      final repository = FakeListingEditorRepository(ad: testAd())
        ..updateError = Exception('boom');
      await pumpScreen(tester, repository: repository);

      await scrollToBottom(tester);
      await tester.tap(find.byKey(const ValueKey('editListing-save')));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.text('Update New Post'), findsOneWidget);
    });
  });

  group('a failed new-upload blocks Save (never silently dropped)', () {
    testWidgets('Save refuses, toasts, and never calls the repository', (
      tester,
    ) async {
      final repository = FakeListingEditorRepository(
        ad: testAd(photos: const ['https://example.test/a.jpg']),
      );
      await pumpScreen(
        tester,
        repository: repository,
        mediaPicker: FakeMediaPicker(
          imageResult: PickedMedia(
            bytes: Uint8List.fromList(const [1, 2, 3]),
            fileName: 'front.jpg',
            mimeType: 'image/jpeg',
          ),
        ),
        uploadsRepository: FakeUploadsRepository(
          error: const NetworkException('offline'),
        ),
      );

      await tester.ensureVisible(
        find.byKey(const ValueKey('createListing-addPhotos')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('createListing-addPhotos')));
      await tester.pumpAndSettle();
      await tester.tap(find.bySemanticsLabel(RegExp('Choose from library')));
      await tester.pumpAndSettle();

      await scrollToBottom(tester);
      await tester.tap(find.byKey(const ValueKey('editListing-save')));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(tester.element(find.byType(Scaffold).first));
      expect(find.text(l10n.listingEditorFailedUploadsMessage), findsOneWidget);
      // The regression this pins: the update used to go through with the
      // failed photo missing from `photos[]`, behind "Successfully updated".
      expect(repository.updateCalls, 0);
      expect(find.text('Successfully updated'), findsNothing);
    });
  });

  group('typed failures are told apart (not all "Something went wrong.")', () {
    testWidgets('an offline Save names the connection', (tester) async {
      final repository = FakeListingEditorRepository(ad: testAd())
        ..updateError = const NetworkException('offline');
      await pumpScreen(tester, repository: repository);

      await scrollToBottom(tester);
      await tester.tap(find.byKey(const ValueKey('editListing-save')));
      await tester.pumpAndSettle();

      expect(
        find.text('No connection. Check your network and try again.'),
        findsOneWidget,
      );
      expect(find.text('Something went wrong.'), findsNothing);
    });

    testWidgets("a rejected Save shows the server's own sentence", (tester) async {
      final repository = FakeListingEditorRepository(ad: testAd())
        ..updateError = ApiErrorException(
          body: const ApiErrorBody(
            code: ApiErrorCode.validation,
            message: 'Reference is already in use.',
          ),
          statusCode: 422,
        );
      await pumpScreen(tester, repository: repository);

      await scrollToBottom(tester);
      await tester.tap(find.byKey(const ValueKey('editListing-save')));
      await tester.pumpAndSettle();

      expect(find.text('Reference is already in use.'), findsOneWidget);
    });

    testWidgets('a forbidden Delete says so, rather than "Something went wrong."', (
      tester,
    ) async {
      final repository = FakeListingEditorRepository(ad: testAd())
        ..deleteError = ApiErrorException(
          body: const ApiErrorBody(
            code: ApiErrorCode.forbidden,
            message: 'Only the owning agent can delete this listing.',
          ),
          statusCode: 403,
        );
      await pumpScreen(tester, repository: repository);

      await scrollToBottom(tester);
      await tester.tap(find.byKey(const ValueKey('editListing-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(
        find.text('Only the owning agent can delete this listing.'),
        findsOneWidget,
      );
      expect(find.text('Something went wrong.'), findsNothing);
    });
  });

  group('delete', () {
    testWidgets('confirmDelete then repository.delete, landing on my-listings', (tester) async {
      final repository = FakeListingEditorRepository(ad: testAd(id: 'ad-3003'));
      final result = await pumpScreen(tester, repository: repository, adId: 'ad-3003');

      await scrollToBottom(tester);
      await tester.tap(find.byKey(const ValueKey('editListing-delete')));
      await tester.pumpAndSettle();

      expect(find.text('Delete listing?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Delete'));
      await tester.pumpAndSettle();

      expect(result.repository.deleteCalls, 1);
      expect(result.repository.lastDeleteId, 'ad-3003');
      expect(find.text('my-listings-root'), findsOneWidget);
    });

    testWidgets('cancelling the confirm alert does not delete', (tester) async {
      final repository = FakeListingEditorRepository(ad: testAd());
      final result = await pumpScreen(tester, repository: repository);

      await scrollToBottom(tester);
      await tester.tap(find.byKey(const ValueKey('editListing-delete')));
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(TextButton, 'Cancel'));
      await tester.pumpAndSettle();

      expect(result.repository.deleteCalls, 0);
    });

    testWidgets('Delete is hidden for a coworker session (AGENT-only endpoint)', (tester) async {
      await pumpScreen(
        tester,
        repository: FakeListingEditorRepository(ad: testAd()),
        role: UserRole.coworker,
      );

      expect(find.byKey(const ValueKey('editListing-delete')), findsNothing);
    });
  });

  group('leaving the editor', () {
    testWidgets('a successful save pops back to my-listings', (tester) async {
      // The regression this pins: `edit-listing` used to be a direct child
      // of `/work` opened with `context.go`, so `_leave()`'s `canPop()` was
      // false on every entry and each saved edit fell through to the `go`
      // fallback — landing the agent on the Work branch's role default
      // (Statistics), with My Ads' filters and paged scroll position gone.
      final repository = FakeListingEditorRepository(ad: testAd(id: 'ad-2002'));
      await pumpScreen(tester, repository: repository, adId: 'ad-2002');

      await scrollToBottom(tester);
      await tester.tap(find.byKey(const ValueKey('editListing-save')));
      await tester.pumpAndSettle();

      expect(repository.updateCalls, 1);
      expect(find.byType(EditListingScreen), findsNothing);
      expect(find.text('my-listings-root'), findsOneWidget);
    });

    testWidgets(
      'the Publish Status link pushes, so Back returns to the still-dirty '
      'form',
      (tester) async {
        await pumpScreen(
          tester,
          repository: FakeListingEditorRepository(ad: testAd(id: 'ad-1001')),
        );

        await tester.enterText(
          find.byKey(const ValueKey('listingField-title')),
          'Unsaved title',
        );
        await tester.pumpAndSettle();
        await scrollToBottom(tester);

        await tester.tap(find.byKey(const ValueKey('publish-status-link')));
        await tester.pumpAndSettle();

        expect(find.text('publish-status-stub-ad-1001'), findsOneWidget);
        // The link used to `go`, which replaced the stack and disposed this
        // form outright — and silently: the discard guard is a `PopScope`,
        // a pop-only hook that a replace never reaches. So the absence of
        // the prompt here is only correct *because* nothing is being
        // discarded.
        expect(find.text('Discard changes?'), findsNothing);

        await tester.binding.handlePopRoute();
        await tester.pumpAndSettle();

        expect(find.text('publish-status-stub-ad-1001'), findsNothing);
        expect(find.byType(EditListingScreen), findsOneWidget);
        expect(find.text('Unsaved title'), findsOneWidget);
      },
    );
  });

  group('discard confirmation (SCREENS.md §5)', () {
    testWidgets('back with no changes leaves immediately, no dialog', (tester) async {
      await pumpScreen(tester, repository: FakeListingEditorRepository(ad: testAd()));

      await tester.tap(find.byKey(const ValueKey('editListing-back')));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('my-listings-root'), findsOneWidget);
    });

    testWidgets('back with changes shows "Discard changes?"', (tester) async {
      await pumpScreen(tester, repository: FakeListingEditorRepository(ad: testAd()));

      await tester.enterText(find.byKey(const ValueKey('listingField-title')), 'Something');
      await tester.tap(find.byKey(const ValueKey('editListing-back')));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);
    });
  });

  group('layout holds at real phone widths', () {
    const phones = <String, Size>{
      'small android 360x800': Size(360, 800),
      'iphone 14 390x844': Size(390, 844),
      'pro max 430x932': Size(430, 932),
    };

    phones.forEach((label, size) {
      testWidgets('no overflow at $label', (tester) async {
        final overflows = <String>[];
        final previous = FlutterError.onError;
        FlutterError.onError = (details) {
          final text = details.exceptionAsString();
          if (text.contains('overflowed')) overflows.add(text.split('\n').first);
        };

        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1.0;
        addTearDown(() {
          tester.view.resetPhysicalSize();
          tester.view.resetDevicePixelRatio();
          FlutterError.onError = previous;
        });

        await pumpScreen(
          tester,
          repository: FakeListingEditorRepository(
            ad: testAd(
              title: 'Exceptionally bright five-room apartment with a garden terrace',
              nearPlacesList: const [
                'Amir Temur Square metro station (7 minutes on foot)',
                'School #158',
              ],
              optionList: const [
                {'key': 'Parking', 'value': 'Underground, two spaces'},
              ],
              photos: const ['https://example.test/a.jpg', 'https://example.test/b.jpg'],
            ),
          ),
        );

        await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -3000));
        await tester.pumpAndSettle();

        FlutterError.onError = previous;
        expect(overflows, isEmpty, reason: 'overflow at $label:\n${overflows.join('\n')}');
      });
    });
  });
}
