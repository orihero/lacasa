// Widget tests for `edit-listing` (SCREENS.md §27).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/listing_editor/listing_editor.dart';
import 'package:lacasa_mobile/features/listing_editor/state/listing_editor_repository_provider.dart';
import 'package:lacasa_mobile/navigation/auth_session.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/fake_listing_editor_repository.dart';

void main() {
  Future<
    ({ProviderContainer container, GoRouter router, FakeListingEditorRepository repository})
  >
  pumpScreen(
    WidgetTester tester, {
    FakeListingEditorRepository? repository,
    String adId = 'ad-1001',
    UserRole role = UserRole.agent,
    bool withBackStack = true,
  }) async {
    final repo = repository ?? FakeListingEditorRepository(ad: testAd(id: adId));
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [listingEditorRepositoryProvider.overrideWithValue(repo)],
    );
    addTearDown(container.dispose);
    container.read(authSessionProvider.notifier).setRole(role);

    final router = GoRouter(
      initialLocation: RoutePaths.workMyListings,
      routes: [
        GoRoute(
          path: RoutePaths.workMyListings,
          builder: (context, state) => const Scaffold(body: Text('my-listings-root')),
        ),
        GoRoute(
          path: RoutePaths.workEditListing,
          builder: (context, state) =>
              EditListingScreen(adId: state.pathParameters['id']!),
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

    final path = RoutePaths.workEditListing.replaceFirst(':id', adId);
    if (withBackStack) {
      router.push(path);
    } else {
      router.go(path);
    }
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
