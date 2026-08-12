// Widget tests for `basics_step.dart` in isolation — findings M6 (City/
// District select, cascaded, sourced from the shared regions taxonomy) and
// P1 (a fixed field's error clears without needing Next/Submit pressed
// again). `create_listing_screen_test.dart` covers the wizard-level
// City/District flow against the real (single-region) app fixtures; this
// file overrides `regionsRepositoryProvider` with a 2-region
// [FakeRegionsRepository] so the City→District cascade and the "City
// doesn't match any known region" fallback (a seeded ad's legacy free-text
// value) both have something to actually cascade *between*.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/filter/state/regions_repository_provider.dart';
import 'package:lacasa_mobile/features/listing_editor/widgets/form/basics_step.dart';
import 'package:lacasa_mobile/features/listing_editor/widgets/form/listing_form_fields.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/shared/widgets/glass_option_picker.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/fake_regions_repository.dart';

void main() {
  const twoRegionData = RegionsData(
    regions: [Region(id: 1, name: 'Tashkent'), Region(id: 2, name: 'Samarkand')],
    districts: [
      District(id: 1, regionId: 1, name: 'Chilonzor'),
      District(id: 2, regionId: 1, name: 'Yunusobod'),
      District(id: 3, regionId: 2, name: 'Registon'),
    ],
  );

  late ListingFormFields fields;
  late ProviderContainer container;
  late StateSetter rebuild;

  Future<void> pumpBasics(
    WidgetTester tester, {
    RegionsData? data = twoRegionData,
    Object? error,
  }) async {
    fields = ListingFormFields();
    addTearDown(fields.dispose);
    container = ProviderContainer(
      // Riverpod retries a failed provider build automatically with
      // exponential backoff by default; pumpAndSettle's time-advancing pump
      // loop would otherwise leave the M6 "failed regions fetch" case stuck
      // mid-backoff (an AsyncLoading that carries the previous error)
      // instead of settling. Disabled here — same pattern as
      // `home_feed_screen_test.dart` and `listing_detail_providers.dart`'s
      // own doc comment on this.
      retry: (_, _) => null,
      overrides: [
        regionsRepositoryProvider.overrideWithValue(
          FakeRegionsRepository(data: data, error: error),
        ),
      ],
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: SingleChildScrollView(
              child: StatefulBuilder(
                builder: (context, setState) {
                  rebuild = setState;
                  // Mirrors `create_listing_screen.dart`'s own
                  // `_onFieldChanged`: the parent's `setState` is what
                  // actually turns a mutation on `fields` into a rebuild —
                  // `BasicsStep` itself is stateless.
                  return BasicsStep(fields: fields, onChanged: () => setState(() {}));
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> pickOption(WidgetTester tester, Key fieldKey, String optionLabel) async {
    await tester.tap(find.byKey(fieldKey));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(ValueKey('glassOption-$optionLabel')));
    await tester.pumpAndSettle();
  }

  group('M6 — City/District are selects, cascaded from the shared regions taxonomy', () {
    testWidgets('District starts disabled, then becomes enabled and scoped once City is picked', (
      tester,
    ) async {
      await pumpBasics(tester);

      expect(
        tester.widget<GlassPickerField>(find.byKey(const ValueKey('listingField-district'))).enabled,
        isFalse,
      );

      await pickOption(tester, const ValueKey('listingField-city'), 'Tashkent');

      expect(
        tester.widget<GlassPickerField>(find.byKey(const ValueKey('listingField-district'))).enabled,
        isTrue,
      );

      await tester.tap(find.byKey(const ValueKey('listingField-district')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('glassOption-Chilonzor')), findsOneWidget);
      expect(find.byKey(const ValueKey('glassOption-Yunusobod')), findsOneWidget);
      // Samarkand's own district must not leak into Tashkent's scoped list.
      expect(find.byKey(const ValueKey('glassOption-Registon')), findsNothing);
    });

    testWidgets('picking a different City clears a previously-picked District (a real cascade, not just a gate)', (
      tester,
    ) async {
      await pumpBasics(tester);

      await pickOption(tester, const ValueKey('listingField-city'), 'Tashkent');
      await pickOption(tester, const ValueKey('listingField-district'), 'Chilonzor');
      expect(find.text('Chilonzor'), findsOneWidget);

      await pickOption(tester, const ValueKey('listingField-city'), 'Samarkand');

      expect(find.text('Chilonzor'), findsNothing);
      await tester.tap(find.byKey(const ValueKey('listingField-district')));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('glassOption-Registon')), findsOneWidget);
      expect(find.byKey(const ValueKey('glassOption-Chilonzor')), findsNothing);
    });

    testWidgets(
      'an unmatched pre-existing City/District (legacy seed data) is shown, not silently dropped, '
      'and District stays editable via the full unscoped list',
      (tester) async {
        await pumpBasics(tester);
        // Simulates `edit-listing`'s `seedFrom(ad)` landing a free-text
        // value that predates this picker's taxonomy (the OLX-imported
        // seed ads carry values like these).
        fields.city.text = 'Toshkent';
        fields.district.text = "Mirzo-Ulug'bek tumani";
        rebuild(() {});
        await tester.pump();

        expect(find.text('Toshkent'), findsOneWidget);
        expect(find.text("Mirzo-Ulug'bek tumani"), findsOneWidget);

        final district = tester.widget<GlassPickerField>(
          find.byKey(const ValueKey('listingField-district')),
        );
        expect(
          district.enabled,
          isTrue,
          reason: 'a non-empty City keeps District editable even when City itself '
              "doesn't match any known region — a required field must stay "
              'satisfiable',
        );

        await tester.tap(find.byKey(const ValueKey('listingField-district')));
        await tester.pumpAndSettle();
        // No region matched "Toshkent", so District falls back to every
        // district across every region rather than an empty, unusable list.
        expect(find.byKey(const ValueKey('glassOption-Chilonzor')), findsOneWidget);
        expect(find.byKey(const ValueKey('glassOption-Registon')), findsOneWidget);
      },
    );

    testWidgets('a failed regions fetch disables City/District with a retry affordance', (
      tester,
    ) async {
      await pumpBasics(tester, data: null, error: Exception('offline'));

      final city = tester.widget<GlassPickerField>(find.byKey(const ValueKey('listingField-city')));
      expect(city.enabled, isFalse);
      expect(city.onRetry, isNotNull);
    });
  });

  group('P1 — a fixed field clears its own error without Next/Submit pressed again', () {
    testWidgets('fixing Title clears "Title is required" as soon as it has text', (tester) async {
      await pumpBasics(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(BasicsStep)));

      // Simulates having already failed once (what `create_listing_screen
      // .dart`'s `_next()` does before this step first shows an error).
      fields.validateBasics(l10n);
      rebuild(() {});
      await tester.pump();
      expect(find.text(l10n.listingEditorTitleRequiredError), findsOneWidget);

      await tester.enterText(find.byKey(const ValueKey('listingField-title')), 'A title');
      await tester.pump();

      expect(find.text(l10n.listingEditorTitleRequiredError), findsNothing);
      // The initial `validateBasics` call above is what a real Next/Submit
      // press does — it sets every required field's error, Address's
      // included, since Address is empty too (see that method's own doc
      // comment: "so a user fixing one mistake isn't surprised by a second
      // the next time they tap Next/Submit"). Fixing Title only must clear
      // Title's own error, not Address's already-shown one — this is not
      // the same claim the removed comment made ("must not have grown"):
      // Address's error was already visible before Title was touched, and
      // `revalidateTouchedBasics` leaves it alone because Address itself
      // was never edited.
      expect(find.text(l10n.listingEditorAddressRequiredError), findsOneWidget);
    });

    testWidgets('fixing City clears "City is required" as soon as it is picked', (tester) async {
      await pumpBasics(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(BasicsStep)));

      fields.validateBasics(l10n);
      rebuild(() {});
      await tester.pump();
      expect(find.text(l10n.listingEditorCityRequiredError), findsOneWidget);

      await pickOption(tester, const ValueKey('listingField-city'), 'Tashkent');

      expect(find.text(l10n.listingEditorCityRequiredError), findsNothing);
    });

    testWidgets('a pristine field stays silent while typing into a sibling field', (tester) async {
      await pumpBasics(tester);
      final l10n = AppLocalizations.of(tester.element(find.byType(BasicsStep)));

      // Nothing has been validated yet — every field starts silent.
      await tester.enterText(find.byKey(const ValueKey('listingField-title')), 'A title');
      await tester.pump();

      expect(find.text(l10n.listingEditorAddressRequiredError), findsNothing);
      expect(find.text(l10n.listingEditorCityRequiredError), findsNothing);
    });
  });
}
