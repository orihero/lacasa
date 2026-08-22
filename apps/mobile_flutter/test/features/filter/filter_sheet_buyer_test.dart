// Widget tests for the buyer-facing `filter-sheet` (lib/features/filter/,
// SCREENS.md §3.5) — the sheet body and live result-count preview that
// `filter_sheet_crm_test.dart` doesn't reach (that file covers only the
// CRM Sort/Status seam `my-listings` appends; the shared buyer sections and
// `filter_count_provider.dart`'s debounce/error/retry mechanics were still
// untested, per the README's "Known gaps"). Each test overrides
// `filterRepositoryProvider` with `FakeFilterRepository` — no network, no
// coupling to `filter_ads_fixtures.dart`.
//
// Everything else the sheet touches goes through
// `ambientRepositoryOverrides(filter: false)`: the repository providers now
// build live implementations around `LaCasaApi.create()` unconditionally
// (the bundled fixtures and `app_mode.dart`'s `FLUTTER_TEST` switch are
// gone), so an un-overridden provider fires real HTTP and hangs
// `pumpAndSettle`. `filter` is switched off because each container supplies
// its own `FakeFilterRepository` and Riverpod rejects a duplicate override
// outright.
//
// The City/District cascade is a second casualty of the same removal: it
// reads `regionsDataProvider`, whose vocabulary used to arrive for free from
// `FixtureRegionsRepository`. The ambient set's inert regions repository
// answers with *no* regions, which would leave the City picker with nothing
// to tap — so each container overrides `regionsDataProvider` itself with
// `testRegionsData` (`support/fake_regions_data.dart`). That override is on
// the derived `FutureProvider`, not on `regionsRepositoryProvider`, so it
// does not collide with the ambient entry for the latter.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/filter/filter.dart';
import 'package:lacasa_mobile/features/filter/state/filter_repository_provider.dart';
import 'package:lacasa_mobile/features/filter/state/regions_repository_provider.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../support/ambient_repository_overrides.dart';
import 'support/fake_filter_repository.dart';
import 'support/fake_regions_data.dart';

void main() {
  /// Same `openButton` shape as `filter_sheet_crm_test.dart`, but backed by
  /// a caller-supplied [ProviderContainer] so a test can hand in its own
  /// `FakeFilterRepository` and inspect its call log afterwards.
  Widget openButton(
    Future<void> Function(BuildContext context) onOpen, {
    required ProviderContainer container,
  }) {
    return UncontrolledProviderScope(
      container: container,
      child: MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => onOpen(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  /// Still used for Storey, the one remaining free-text numeric field on
  /// this sheet — City/District moved to tap-to-pick and no longer need a
  /// `TextField` finder (see [pickerFieldEnabled]/[selectPickerOption]
  /// below).
  Finder textFieldIn(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );

  /// The sheet's own `SingleChildScrollView` builds every field eagerly (a
  /// plain `Column`, not a lazy list) but most fields sit below the default
  /// 800×600 test surface until scrolled into view — same fix
  /// `filter_sheet_crm_test.dart` uses for its own off-screen Sort/Status
  /// chips.
  Future<void> tapVisible(WidgetTester tester, Finder finder) async {
    await tester.ensureVisible(finder);
    await tester.pumpAndSettle();
    await tester.tap(finder);
    await tester.pumpAndSettle();
  }

  /// City and District moved off free-text `TextField`s onto a tap-to-pick
  /// `_PickerField` (`filter_city_district_section.dart`, part of the same
  /// in-flight feature pass that added the `GET /regions`-backed cascade)
  /// backed by `showFilterOptionPicker`'s nested bottom sheet — see that
  /// section's doc comment for why free text was dropped. [pickerFieldEnabled]
  /// reads the field's `Opacity` wrapper (0.5 when disabled, 1 when enabled)
  /// rather than a public `enabled` getter, since `_PickerField` is private
  /// to its own file; that's also the exact signal the field's own build
  /// method keys its dimming off of, so this can't drift from what the user
  /// actually sees.
  Future<bool> pickerFieldEnabled(WidgetTester tester, String key) async {
    final opacity = tester.widget<Opacity>(
      find.descendant(
        of: find.byKey(ValueKey(key)),
        matching: find.byType(Opacity),
      ),
    );
    return opacity.opacity == 1;
  }

  /// Drives one full pick end to end: taps the `_PickerField` itself (which
  /// opens `showFilterOptionPicker`'s modal sheet), then taps the matching
  /// `filterOption-<value>` row inside it — or `filterOption-any` when
  /// [value] is `null`, the sheet's own convention for its leading "Any …"
  /// row (see `filter_option_picker_sheet.dart`).
  Future<void> selectPickerOption(
    WidgetTester tester,
    String fieldKey,
    String? value,
  ) async {
    await tapVisible(tester, find.byKey(ValueKey(fieldKey)));
    final optionKey = value == null
        ? 'filterOption-any'
        : 'filterOption-$value';
    await tester.tap(find.byKey(ValueKey(optionKey)));
    await tester.pumpAndSettle();
  }

  group('sections render (SCREENS.md §3.5)', () {
    testWidgets('every field label is present', (tester) async {
      final container = ProviderContainer(
        overrides: [
          ...ambientRepositoryOverrides(filter: false),
          filterRepositoryProvider.overrideWithValue(FakeFilterRepository()),
          regionsDataProvider.overrideWith((ref) => testRegionsData),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        openButton((context) async {
          await showFilterSheet(context);
        }, container: container),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Filters'), findsOneWidget);
      // FieldLabel uppercases its text (field_label.dart) — same convention
      // filter_sheet_crm_test.dart's 'SORT'/'STATUS' assertions rely on.
      expect(find.text('CITY'), findsOneWidget);
      expect(find.text('DISTRICT'), findsOneWidget);
      expect(find.text('CATEGORY'), findsOneWidget);
      expect(find.text('TYPE'), findsOneWidget);
      expect(find.text('ROOMS'), findsOneWidget);
      expect(find.text('MIN. TOTAL AREA'), findsOneWidget);
      expect(find.text('MAX TOTAL AREA'), findsOneWidget);
      expect(find.text('MIN PRICE'), findsOneWidget);
      expect(find.text('MAX PRICE'), findsOneWidget);
      expect(find.text('FURNITURE'), findsOneWidget);
      expect(find.text('REPAIR'), findsOneWidget);
      expect(find.text('STOREY'), findsOneWidget);
      // The CRM-only fields never appear on the buyer path.
      expect(find.text('SORT'), findsNothing);
      expect(find.text('STATUS'), findsNothing);
    });
  });

  group('city/district cascade', () {
    testWidgets('District starts disabled with no City set', (tester) async {
      final container = ProviderContainer(
        overrides: [
          ...ambientRepositoryOverrides(filter: false),
          filterRepositoryProvider.overrideWithValue(FakeFilterRepository()),
          regionsDataProvider.overrideWith((ref) => testRegionsData),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        openButton((context) async {
          await showFilterSheet(context);
        }, container: container),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(await pickerFieldEnabled(tester, 'filterField-district'), isFalse);
    });

    testWidgets('picking a City enables District', (tester) async {
      final container = ProviderContainer(
        overrides: [
          ...ambientRepositoryOverrides(filter: false),
          filterRepositoryProvider.overrideWithValue(FakeFilterRepository()),
          regionsDataProvider.overrideWith((ref) => testRegionsData),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        openButton((context) async {
          await showFilterSheet(context);
        }, container: container),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await selectPickerOption(tester, 'filterField-city', 'Tashkent');

      expect(await pickerFieldEnabled(tester, 'filterField-district'), isTrue);
    });

    testWidgets(
      'clearing City (picking "Any") disables District again and drops its value',
      (tester) async {
        AdFilters? result;
        final container = ProviderContainer(
          overrides: [
            ...ambientRepositoryOverrides(filter: false),
            filterRepositoryProvider.overrideWithValue(FakeFilterRepository()),
            regionsDataProvider.overrideWith((ref) => testRegionsData),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          openButton((context) async {
            result = await showFilterSheet(context);
          }, container: container),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await selectPickerOption(tester, 'filterField-city', 'Tashkent');
        await selectPickerOption(tester, 'filterField-district', 'Chilonzor');

        // "Any city" is the picker's own spelling of "clear" — see
        // `selectPickerOption`'s doc comment.
        await selectPickerOption(tester, 'filterField-city', null);

        expect(
          await pickerFieldEnabled(tester, 'filterField-district'),
          isFalse,
        );

        await tapVisible(
          tester,
          find.byKey(const ValueKey('filterSheet-apply')),
        );

        expect(result!.city, isNull);
        expect(result!.district, isNull);
      },
    );
  });

  group('live result-count preview (SCREENS.md §5: debounce 300ms)', () {
    testWidgets('seeds the count immediately on open, no debounce', (
      tester,
    ) async {
      final repo = FakeFilterRepository(count: 4);
      final container = ProviderContainer(
        overrides: [
          ...ambientRepositoryOverrides(filter: false),
          filterRepositoryProvider.overrideWithValue(repo),
          regionsDataProvider.overrideWith((ref) => testRegionsData),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        openButton((context) async {
          await showFilterSheet(context);
        }, container: container),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(repo.countCallCount, 1);
      expect(find.text('Apply Filters (4)'), findsOneWidget);
    });

    testWidgets('a field edit recounts only after 300ms of no further edits', (
      tester,
    ) async {
      final repo = FakeFilterRepository(count: 4);
      final container = ProviderContainer(
        overrides: [
          ...ambientRepositoryOverrides(filter: false),
          filterRepositoryProvider.overrideWithValue(repo),
          regionsDataProvider.overrideWith((ref) => testRegionsData),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        openButton((context) async {
          await showFilterSheet(context);
        }, container: container),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();
      expect(repo.countCallCount, 1); // the initial seed

      final storeyField = textFieldIn('filterField-storey');
      await tester.ensureVisible(storeyField);
      await tester.pumpAndSettle();
      await tester.enterText(storeyField, '5');

      await tester.pump(const Duration(milliseconds: 200));
      expect(repo.countCallCount, 1); // not yet — still within the debounce

      await tester.pump(const Duration(milliseconds: 150));
      await tester.pumpAndSettle();
      expect(repo.countCallCount, 2);
      expect(repo.lastFilters?.storey, 5);
    });

    testWidgets(
      'a count failure shows a scoped retry row without blanking the sheet, and Retry recounts',
      (tester) async {
        final repo = FakeFilterRepository(
          error: const NetworkException('offline'),
        );
        final container = ProviderContainer(
          overrides: [
            ...ambientRepositoryOverrides(filter: false),
            filterRepositoryProvider.overrideWithValue(repo),
            regionsDataProvider.overrideWith((ref) => testRegionsData),
          ],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          openButton((context) async {
            await showFilterSheet(context);
          }, container: container),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(
          find.text("Couldn't calculate matching listings."),
          findsOneWidget,
        );
        expect(find.text('Apply Filters'), findsOneWidget); // no count shown
        expect(
          find.text('CITY'),
          findsOneWidget,
        ); // the rest of the sheet is intact
        expect(repo.countCallCount, 1);

        await tapVisible(
          tester,
          find.byKey(const ValueKey('filterSheet-countRetry')),
        );

        expect(repo.countCallCount, 2);
      },
    );

    testWidgets('the CRM variant never reads the buyer-scoped count at all', (
      tester,
    ) async {
      final repo = FakeFilterRepository(count: 4);
      final container = ProviderContainer(
        overrides: [
          ...ambientRepositoryOverrides(filter: false),
          filterRepositoryProvider.overrideWithValue(repo),
          regionsDataProvider.overrideWith((ref) => testRegionsData),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        openButton((context) async {
          await showCrmFilterSheet(context);
        }, container: container),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(repo.countCallCount, 0);
      expect(find.text('Apply Filters'), findsOneWidget);
      expect(find.textContaining('Apply Filters ('), findsNothing);
    });
  });

  group('reset', () {
    /// Whether `key`'s `ChoiceChipGroup` option renders in its *selected*
    /// state. `_Chip` (`choice_chip_group.dart`) is private, so there's no
    /// `isOn` getter to read directly — but its two states render two
    /// different widget types at the chip's own root: a filled `Container`
    /// when on, a `GlassSurface` when off (which happens to build a
    /// `Container` of its own further down, so this checks for the
    /// `GlassSurface` specifically — its presence/absence is unambiguous
    /// either way). That's the same signal the chip's own build method keys
    /// its look off of, so this can't drift from what the user actually
    /// sees on screen. Deliberately checking the *rendered* chip rather than
    /// only the draft handed to `recountNow`/`onApply` — finding B1 ("Reset
    /// does nothing") was a real-device-only symptom: every field read back
    /// correctly from `_reset()`'s own local state, yet the sheet on screen
    /// visibly still showed the old selections, because the tap on Reset
    /// was landing on `GlassTabBar` underneath the sheet instead (see
    /// `tab_shell_scaffold.dart`'s doc comment, and the
    /// `useRootNavigator: true` this file's `showFilterSheet`/
    /// `showCrmFilterSheet` now pass because of it) — a class of bug a
    /// state-only assertion against a fake repository's `lastFilters` can't
    /// catch, since that value is correct either way.
    bool chipIsOn(WidgetTester tester, String key) {
      return find
          .descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(GlassSurface),
          )
          .evaluate()
          .isEmpty;
    }

    testWidgets(
      'clears every touched field back to defaults and recounts immediately',
      (tester) async {
        final repo = FakeFilterRepository(count: 6);
        final container = ProviderContainer(
          overrides: [
            ...ambientRepositoryOverrides(filter: false),
            filterRepositoryProvider.overrideWithValue(repo),
            regionsDataProvider.overrideWith((ref) => testRegionsData),
          ],
        );
        addTearDown(container.dispose);

        AdFilters? result;
        await tester.pumpWidget(
          openButton((context) async {
            result = await showFilterSheet(context);
          }, container: container),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await selectPickerOption(tester, 'filterField-city', 'Tashkent');
        await tapVisible(
          tester,
          find.byKey(ValueKey('filterCategory-${AdCategory.sale}')),
        );
        await tapVisible(tester, find.byKey(const ValueKey('filterRooms-5')));
        await tapVisible(
          tester,
          find.byKey(ValueKey('filterFurniture-${Furniture.withoutFurniture}')),
        );
        await tapVisible(
          tester,
          find.byKey(ValueKey('filterRepair-${Repairment.excellent}')),
        );

        expect(
          find.descendant(
            of: find.byKey(const ValueKey('filterField-city')),
            matching: find.text('Tashkent'),
          ),
          findsOneWidget,
        );
        // Baseline: every touched chip actually rendered as selected before
        // Reset is tapped, so the post-reset checks below are a real
        // transition, not an assertion against a field that was already at
        // rest.
        expect(chipIsOn(tester, 'filterRooms-5'), isTrue);
        expect(
          chipIsOn(tester, 'filterFurniture-${Furniture.withoutFurniture}'),
          isTrue,
        );
        expect(
          chipIsOn(tester, 'filterRepair-${Repairment.excellent}'),
          isTrue,
        );

        await tapVisible(
          tester,
          find.byKey(const ValueKey('filterSheet-reset')),
        );

        // Reset drops back to the picker's own "Any city" placeholder — the
        // City field never held free text to begin with (see
        // `selectPickerOption`'s doc comment), so there's no empty string
        // to assert against anymore.
        expect(
          find.descendant(
            of: find.byKey(const ValueKey('filterField-city')),
            matching: find.text('Any city'),
          ),
          findsOneWidget,
        );
        // The rendered chips themselves drop back out of their selected
        // state — see `chipIsOn`'s doc comment for why this, not just the
        // draft below, is the assertion that actually matters for B1.
        expect(chipIsOn(tester, 'filterRooms-5'), isFalse);
        // Furniture/Repair clear all the way to "any" — *no* chip is left
        // lit, despite SCREENS.md §3.5 annotating one option in each group
        // as that field's `default`. Reset means "no constraints"; leaving
        // two chips selected would mean Reset→Apply still narrowed the
        // results (see `filter_sheet.dart`'s "No invented defaults").
        expect(
          chipIsOn(tester, 'filterFurniture-${Furniture.withFurniture}'),
          isFalse,
        );
        expect(
          chipIsOn(tester, 'filterFurniture-${Furniture.withoutFurniture}'),
          isFalse,
        );
        expect(
          chipIsOn(tester, 'filterRepair-${Repairment.notRepaired}'),
          isFalse,
        );
        expect(
          chipIsOn(tester, 'filterRepair-${Repairment.excellent}'),
          isFalse,
        );
        // Reset recounts immediately (no debounce wait needed to observe it).
        expect(repo.lastFilters?.city, isNull);
        expect(repo.lastFilters?.category, isNull);
        expect(repo.lastFilters?.rooms, isNull);
        expect(repo.lastFilters?.furniture, isNull);
        expect(repo.lastFilters?.repairment, isNull);

        await tapVisible(
          tester,
          find.byKey(const ValueKey('filterSheet-apply')),
        );

        expect(result!.city, isNull);
        expect(result!.category, isNull);
        expect(result!.rooms, isNull);
        expect(result!.furniture, isNull);
        expect(result!.repairment, isNull);
      },
    );
  });

  group('initial state (no invented defaults)', () {
    /// Same rendered-chip probe as the `reset` group's — see its doc
    /// comment. Duplicated rather than hoisted so each group stays
    /// readable on its own; the two are three lines each.
    bool chipIsOn(WidgetTester tester, String key) {
      return find
          .descendant(
            of: find.byKey(ValueKey(key)),
            matching: find.byType(GlassSurface),
          )
          .evaluate()
          .isEmpty;
    }

    testWidgets(
      'a fresh open pre-selects nothing and Apply returns an empty filter set',
      (tester) async {
        final repo = FakeFilterRepository(count: 9);
        final container = ProviderContainer(
          overrides: [
            ...ambientRepositoryOverrides(filter: false),
            filterRepositoryProvider.overrideWithValue(repo),
            regionsDataProvider.overrideWith((ref) => testRegionsData),
          ],
        );
        addTearDown(container.dispose);

        AdFilters? result;
        await tester.pumpWidget(
          openButton((context) async {
            result = await showFilterSheet(context);
          }, container: container),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // The regression this guards: `withFurniture`/`notRepaired` used to
        // arrive pre-selected on every fresh open, so a buyer who opened
        // Filters only to set a price walked out with two constraints they
        // never chose and a toolbar badge reading 3. Assert on the rendered
        // chips as well as the returned draft — the two together are what
        // "the user never chose this" actually means.
        for (final key in [
          'filterFurniture-${Furniture.withFurniture}',
          'filterFurniture-${Furniture.withoutFurniture}',
          'filterRepair-${Repairment.notRepaired}',
          'filterRepair-${Repairment.normal}',
          'filterRepair-${Repairment.good}',
          'filterRepair-${Repairment.excellent}',
        ]) {
          await tester.ensureVisible(find.byKey(ValueKey(key)));
          await tester.pumpAndSettle();
          expect(chipIsOn(tester, key), isFalse, reason: '$key must start off');
        }

        // The seeded live count is queried against an empty draft too, so
        // the number on the Apply button is the unfiltered total. The
        // `isNotNull` guard is load-bearing: without it, the two `isNull`
        // assertions below would also pass if the sheet had never issued a
        // count request at all (`lastFilters` still null), which is exactly
        // the failure mode that would hide a regression here.
        expect(repo.lastFilters, isNotNull);
        expect(repo.lastFilters?.furniture, isNull);
        expect(repo.lastFilters?.repairment, isNull);

        await tapVisible(
          tester,
          find.byKey(const ValueKey('filterSheet-apply')),
        );

        // `AdFilters` has no `==` of its own (`api/resources/
        // ads_resource.dart`), so "empty" is asserted field by field
        // rather than against a `const AdFilters()` literal.
        expect(result, isNotNull);
        expect(result!.city, isNull);
        expect(result!.district, isNull);
        expect(result!.category, isNull);
        expect(result!.type, isNull);
        expect(result!.rooms, isNull);
        expect(result!.areaMin, isNull);
        expect(result!.areaMax, isNull);
        expect(result!.priceMin, isNull);
        expect(result!.priceMax, isNull);
        expect(result!.furniture, isNull);
        expect(result!.repairment, isNull);
        expect(result!.storey, isNull);
      },
    );

    testWidgets('re-opening with applied filters seeds those and only those', (
      tester,
    ) async {
      final repo = FakeFilterRepository(count: 1);
      final container = ProviderContainer(
        overrides: [
          ...ambientRepositoryOverrides(filter: false),
          filterRepositoryProvider.overrideWithValue(repo),
          regionsDataProvider.overrideWith((ref) => testRegionsData),
        ],
      );
      addTearDown(container.dispose);

      AdFilters? result;
      await tester.pumpWidget(
        openButton((context) async {
          result = await showFilterSheet(
            context,
            initialFilters: const AdFilters(rooms: 3),
          );
        }, container: container),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.ensureVisible(find.byKey(const ValueKey('filterRooms-3')));
      await tester.pumpAndSettle();
      expect(chipIsOn(tester, 'filterRooms-3'), isTrue);

      await tapVisible(tester, find.byKey(const ValueKey('filterSheet-apply')));

      // Round-trips unchanged: the caller's one filter comes back as its
      // one filter, with nothing bolted on.
      expect(result!.rooms, 3);
      expect(result!.furniture, isNull);
      expect(result!.repairment, isNull);
      expect(result!.city, isNull);
      expect(result!.category, isNull);
    });
  });

  group('apply', () {
    testWidgets(
      'returns the full draft — free-text, chip, and price-ladder fields together',
      (tester) async {
        final repo = FakeFilterRepository(count: 2);
        final container = ProviderContainer(
          overrides: [
            ...ambientRepositoryOverrides(filter: false),
            filterRepositoryProvider.overrideWithValue(repo),
            regionsDataProvider.overrideWith((ref) => testRegionsData),
          ],
        );
        addTearDown(container.dispose);

        AdFilters? result;
        await tester.pumpWidget(
          openButton((context) async {
            result = await showFilterSheet(context);
          }, container: container),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        await selectPickerOption(tester, 'filterField-city', 'Tashkent');
        await selectPickerOption(tester, 'filterField-district', 'Chilonzor');

        await tapVisible(tester, find.byKey(const ValueKey('filterRooms-3')));
        await tapVisible(
          tester,
          find.byKey(ValueKey('filterCategory-${AdCategory.sale}')),
        );
        // Min/Max price are `.selbox` pickers now, not chip groups — same
        // ladder, picked through `showFilterOptionPicker` like City/District
        // (see `filter_price_section.dart`).
        await selectPickerOption(tester, 'filterField-priceMin', '100,000');
        await selectPickerOption(tester, 'filterField-priceMax', '1,000,000');
        // Furniture starts unselected (see the `initial state` group), so
        // one tap *selects* it — and the two taps below prove the chip
        // group's own deselect still works from there, leaving Furniture
        // back at "any" while the rest of the draft is untouched.
        await tapVisible(
          tester,
          find.byKey(ValueKey('filterFurniture-${Furniture.withFurniture}')),
        );
        await tapVisible(
          tester,
          find.byKey(ValueKey('filterFurniture-${Furniture.withFurniture}')),
        );

        await tapVisible(
          tester,
          find.byKey(const ValueKey('filterSheet-apply')),
        );

        expect(result!.city, 'Tashkent');
        expect(result!.district, 'Chilonzor');
        expect(result!.rooms, 3);
        expect(result!.category, AdCategory.sale);
        expect(result!.priceMin, 100000);
        expect(result!.priceMax, 1000000);
        expect(result!.furniture, isNull); // selected, then deselected
        expect(result!.repairment, isNull); // never touched, so never applied
      },
    );

    testWidgets('a Storey number entry round-trips through Apply', (
      tester,
    ) async {
      final container = ProviderContainer(
        overrides: [
          ...ambientRepositoryOverrides(filter: false),
          filterRepositoryProvider.overrideWithValue(FakeFilterRepository()),
          regionsDataProvider.overrideWith((ref) => testRegionsData),
        ],
      );
      addTearDown(container.dispose);

      AdFilters? result;
      await tester.pumpWidget(
        openButton((context) async {
          result = await showFilterSheet(context);
        }, container: container),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final storeyField = textFieldIn('filterField-storey');
      await tester.ensureVisible(storeyField);
      await tester.pumpAndSettle();
      await tester.enterText(storeyField, '9');
      await tester.pumpAndSettle();

      await tapVisible(tester, find.byKey(const ValueKey('filterSheet-apply')));

      expect(result!.storey, 9);
    });
  });
}
