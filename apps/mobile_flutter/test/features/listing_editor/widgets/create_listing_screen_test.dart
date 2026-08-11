// Widget tests for `create-listing` (SCREENS.md §26).

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/features/listing_editor/listing_editor.dart';
import 'package:lacasa_mobile/features/listing_editor/state/listing_editor_repository_provider.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_providers.dart';
import 'package:lacasa_mobile/features/work_dashboard/state/dashboard_repository_provider.dart';
import 'package:lacasa_mobile/navigation/route_paths.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../work_dashboard/support/fake_dashboard_repository.dart';
import '../support/fake_listing_editor_repository.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

void main() {
  Future<
    ({ProviderContainer container, GoRouter router, FakeListingEditorRepository repository})
  >
  pumpScreen(
    WidgetTester tester, {
    FakeListingEditorRepository? repository,
    FakeDashboardRepository? dashboardRepository,
  }) async {
    final repo = repository ?? FakeListingEditorRepository();
    final container = ProviderContainer(
      retry: (retryCount, error) => null,
      overrides: [
        listingEditorRepositoryProvider.overrideWithValue(repo),
        if (dashboardRepository != null)
          dashboardRepositoryProvider.overrideWithValue(dashboardRepository),
      ],
    );
    addTearDown(container.dispose);

    final router = GoRouter(
      initialLocation: RoutePaths.workMyListings,
      routes: [
        GoRoute(
          path: RoutePaths.workMyListings,
          builder: (context, state) => const Scaffold(body: Text('my-listings-root')),
        ),
        GoRoute(
          path: RoutePaths.createListing,
          builder: (context, state) => const CreateListingScreen(),
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

    router.push(RoutePaths.createListing);
    await tester.pumpAndSettle();

    return (container: container, router: router, repository: repo);
  }

  Future<void> fillBasics(WidgetTester tester) async {
    await tester.enterText(find.byKey(const ValueKey('listingField-title')), 'New listing');
    await tester.enterText(find.byKey(const ValueKey('listingField-city')), 'Tashkent');
    // District only becomes enabled once City's text actually lands in the
    // widget tree (SCREENS.md §26's "disabled until City") — `enterText`
    // alone doesn't rebuild the form, so a pump is required here before
    // District's now-enabled `TextField` can be found/entered into.
    await tester.pump();
    await tester.enterText(find.byKey(const ValueKey('listingField-district')), 'Chilonzor');
    await tester.enterText(find.byKey(const ValueKey('listingField-address')), '12 Main St');
    await tester.enterText(find.byKey(const ValueKey('listingField-reference')), 'Near park');
  }

  group('step progression (SCREENS.md §5)', () {
    testWidgets('Next on step 1 blocks with inline errors when required fields are empty', (
      tester,
    ) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();

      expect(find.text('Title is required'), findsOneWidget);
      expect(find.text('City is required'), findsOneWidget);
      expect(find.text('District is required'), findsOneWidget);
      expect(find.text('Address is required'), findsOneWidget);
      expect(find.text('Reference is required'), findsOneWidget);
      // Still on step 1 — the step 2 field never mounted.
      expect(find.byKey(const ValueKey('listingField-description')), findsNothing);
    });

    testWidgets('Next advances once required fields are filled', (tester) async {
      await pumpScreen(tester);
      await fillBasics(tester);

      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('listingField-description')), findsOneWidget);
      expect(find.byKey(const ValueKey('listingField-title')), findsNothing);
    });

    testWidgets('step 2 blocks Next until Description is filled', (tester) async {
      await pumpScreen(tester);
      await fillBasics(tester);
      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();

      expect(find.text('Description is required'), findsOneWidget);
      expect(find.byKey(const ValueKey('createListing-addPhotos')), findsNothing);
    });

    testWidgets('Back never re-validates — leaving a required field empty is fine going backward', (
      tester,
    ) async {
      await pumpScreen(tester);
      await fillBasics(tester);
      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();

      // Step 2, still no description — Back must still work.
      await tester.tap(find.byKey(const ValueKey('listingWizard-back')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('listingField-title')), findsOneWidget);
      expect(find.text('Title is required'), findsNothing);
    });

    testWidgets('reaches step 3 (Photos) and step 4 (Publish) with no required fields of their own', (
      tester,
    ) async {
      await pumpScreen(tester);
      await fillBasics(tester);
      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('listingField-description')),
        'A description.',
      );
      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();

      expect(find.byKey(const ValueKey('createListing-addPhotos')), findsOneWidget);
      // WORK_TAB_CONTRACT.md §5.2 documents an earlier decision to ship a
      // `MediaUploadUnavailableNotice` ("Photo upload isn't available in
      // this build yet.") in place of a real picker — that's now stale:
      // `photos_step.dart`'s own doc comment describes a real
      // `MediaPicker`/`UploadsRepository` flow, and its build() renders
      // the "Add photos"/"Add video" tap targets plus the media-limits
      // hint, not the retired unavailable copy. Assert what actually
      // renders today rather than the superseded placeholder text.
      final l10n = AppLocalizations.of(
        tester.element(find.byKey(const ValueKey('createListing-addPhotos'))),
      );
      expect(find.byKey(const ValueKey('createListing-addVideo')), findsOneWidget);
      expect(find.text(l10n.listingEditorMediaLimitsHint), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();

      expect(find.text('Create'), findsOneWidget);
      expect(find.byKey(const ValueKey('listingWizard-back')), findsOneWidget);
    });
  });

  group('District field (SCREENS.md §26 — disabled until City)', () {
    TextField districtField(WidgetTester tester) => tester.widget<TextField>(
      find.descendant(
        of: find.byKey(const ValueKey('listingField-district')),
        matching: find.byType(TextField),
      ),
    );

    testWidgets('District starts disabled while City is empty', (tester) async {
      await pumpScreen(tester);

      expect(districtField(tester).enabled, isFalse);
    });

    testWidgets('District becomes enabled once City has a value', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const ValueKey('listingField-city')), 'Tashkent');
      await tester.pump();

      expect(districtField(tester).enabled, isTrue);
    });

    testWidgets('District disables again if City is cleared back to empty', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const ValueKey('listingField-city')), 'Tashkent');
      await tester.pump();
      expect(districtField(tester).enabled, isTrue);

      await tester.enterText(find.byKey(const ValueKey('listingField-city')), '');
      await tester.pump();

      expect(districtField(tester).enabled, isFalse);
    });
  });

  group('submit', () {
    Future<void> reachFinalStep(WidgetTester tester) async {
      await fillBasics(tester);
      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.byKey(const ValueKey('listingField-description')),
        'A description.',
      );
      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();
    }

    testWidgets('Create calls the repository, shows the success toast, and lands on my-listings', (
      tester,
    ) async {
      // A gate on the fake's `create()` — otherwise a bare `async` method
      // with no real `await` resolves within the same microtask flush that
      // `tap()` itself already triggers, and the pending "Creating" toast
      // gets replaced by the success toast before this test's own single
      // `pump()` ever gets to observe it (see the fake's own doc comment).
      final gate = Completer<void>();
      final result = await pumpScreen(tester, repository: FakeListingEditorRepository(hold: gate));
      await reachFinalStep(tester);

      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pump();
      expect(find.text('Creating'), findsOneWidget);
      gate.complete();
      await tester.pumpAndSettle();

      expect(result.repository.createCalls, 1);
      expect(result.repository.lastCreateInput!.title!.value, 'New listing');
      expect(find.text('Successfully created'), findsOneWidget);
      expect(find.text('my-listings-root'), findsOneWidget);
    });

    testWidgets('uzs is the default price type (ruling 7.12)', (tester) async {
      final result = await pumpScreen(tester);
      await reachFinalStep(tester);
      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();

      expect(result.repository.lastCreateInput!.priceType!.value.name, 'uzs');
    });

    testWidgets(
      'also invalidates dashboardAdsProvider (correctness — Dashboard stays '
      'mounted for the whole Work-tab session and owns its own copy of the '
      "caller's ad list)",
      (tester) async {
        final dashboardRepo = FakeDashboardRepository();
        final result = await pumpScreen(tester, dashboardRepository: dashboardRepo);
        await reachFinalStep(tester);

        await result.container.read(dashboardAdsProvider.future);
        expect(dashboardRepo.adsCallCount, 1);

        await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
        await tester.pumpAndSettle();

        await result.container.read(dashboardAdsProvider.future);
        expect(
          dashboardRepo.adsCallCount,
          2,
          reason: 'a stale dashboardAdsProvider must refetch once invalidated',
        );
      },
    );

    testWidgets('a server failure shows "Something went wrong." and stays on the form', (
      tester,
    ) async {
      final repository = FakeListingEditorRepository()..createError = Exception('boom');
      await pumpScreen(tester, repository: repository);
      await reachFinalStep(tester);

      await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
      await tester.pumpAndSettle();

      expect(find.text('Something went wrong.'), findsOneWidget);
      expect(find.text('Create'), findsOneWidget);
    });
  });

  group('discard confirmation (SCREENS.md §5)', () {
    testWidgets('closing with no changes leaves immediately, no dialog', (tester) async {
      await pumpScreen(tester);

      await tester.tap(find.byKey(const ValueKey('createListing-close')));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsNothing);
      expect(find.text('my-listings-root'), findsOneWidget);
    });

    testWidgets('closing with changes shows "Discard changes?"', (tester) async {
      await pumpScreen(tester);

      await tester.enterText(find.byKey(const ValueKey('listingField-title')), 'Something');
      await tester.tap(find.byKey(const ValueKey('createListing-close')));
      await tester.pumpAndSettle();

      expect(find.text('Discard changes?'), findsOneWidget);

      await tester.tap(find.widgetWithText(TextButton, 'Discard'));
      await tester.pumpAndSettle();

      expect(find.text('my-listings-root'), findsOneWidget);
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

        await pumpScreen(tester);
        // Step 1, with every required field's error visible at once — the
        // widest state this step renders.
        await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
        await tester.pumpAndSettle();

        await fillBasics(tester);
        await tester.tap(find.byKey(const ValueKey('listingWizard-primary')));
        await tester.pumpAndSettle();

        // Step 2 — the densest step (every chip group, both dynamic lists).
        await tester.drag(find.byType(SingleChildScrollView).first, const Offset(0, -3000));
        await tester.pumpAndSettle();

        FlutterError.onError = previous;
        expect(overflows, isEmpty, reason: 'overflow at $label:\n${overflows.join('\n')}');
      });
    });
  });
}
