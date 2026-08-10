// Widget tests for the buyer-facing `filter-sheet` (lib/features/filter/,
// SCREENS.md §3.5) — the sheet body and live result-count preview that
// `filter_sheet_crm_test.dart` doesn't reach (that file covers only the
// CRM Sort/Status seam `my-listings` appends; the shared buyer sections and
// `filter_count_provider.dart`'s debounce/error/retry mechanics were still
// untested, per the README's "Known gaps"). Each test overrides
// `filterRepositoryProvider` with `FakeFilterRepository` — no network, no
// coupling to `filter_ads_fixtures.dart`.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/filter/filter.dart';
import 'package:lacasa_mobile/features/filter/state/filter_repository_provider.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import 'support/fake_filter_repository.dart';

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

  Finder textFieldIn(String key) => find.descendant(
    of: find.byKey(ValueKey(key)),
    matching: find.byType(TextField),
  );

  Future<TextField> readTextField(WidgetTester tester, String key) async =>
      tester.widget<TextField>(textFieldIn(key));

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

  group('sections render (SCREENS.md §3.5)', () {
    testWidgets('every field label is present', (tester) async {
      final container = ProviderContainer(
        overrides: [
          filterRepositoryProvider.overrideWithValue(FakeFilterRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        openButton(
          (context) async {
            await showFilterSheet(context);
          },
          container: container,
        ),
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
          filterRepositoryProvider.overrideWithValue(FakeFilterRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        openButton(
          (context) async {
            await showFilterSheet(context);
          },
          container: container,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect((await readTextField(tester, 'filterField-district')).enabled, isFalse);
    });

    testWidgets('typing a City enables District', (tester) async {
      final container = ProviderContainer(
        overrides: [
          filterRepositoryProvider.overrideWithValue(FakeFilterRepository()),
        ],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        openButton(
          (context) async {
            await showFilterSheet(context);
          },
          container: container,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.enterText(textFieldIn('filterField-city'), 'Tashkent');
      await tester.pumpAndSettle();

      expect((await readTextField(tester, 'filterField-district')).enabled, isTrue);
    });

    testWidgets(
      'clearing City disables District again and drops its value',
      (tester) async {
        AdFilters? result;
        final container = ProviderContainer(
          overrides: [
            filterRepositoryProvider.overrideWithValue(FakeFilterRepository()),
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

        await tester.enterText(textFieldIn('filterField-city'), 'Tashkent');
        await tester.pumpAndSettle();
        await tester.enterText(
          textFieldIn('filterField-district'),
          'Chilonzor',
        );
        await tester.pumpAndSettle();

        await tester.enterText(textFieldIn('filterField-city'), '');
        await tester.pumpAndSettle();

        expect((await readTextField(tester, 'filterField-district')).enabled, isFalse);

        await tapVisible(tester, find.byKey(const ValueKey('filterSheet-apply')));

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
        overrides: [filterRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        openButton(
          (context) async {
            await showFilterSheet(context);
          },
          container: container,
        ),
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
        overrides: [filterRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        openButton(
          (context) async {
            await showFilterSheet(context);
          },
          container: container,
        ),
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
          overrides: [filterRepositoryProvider.overrideWithValue(repo)],
        );
        addTearDown(container.dispose);

        await tester.pumpWidget(
          openButton(
            (context) async {
              await showFilterSheet(context);
            },
            container: container,
          ),
        );
        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(
          find.text("Couldn't calculate matching listings."),
          findsOneWidget,
        );
        expect(find.text('Apply Filters'), findsOneWidget); // no count shown
        expect(find.text('CITY'), findsOneWidget); // the rest of the sheet is intact
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
        overrides: [filterRepositoryProvider.overrideWithValue(repo)],
      );
      addTearDown(container.dispose);

      await tester.pumpWidget(
        openButton(
          (context) async {
            await showCrmFilterSheet(context);
          },
          container: container,
        ),
      );
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(repo.countCallCount, 0);
      expect(find.text('Apply Filters'), findsOneWidget);
      expect(find.textContaining('Apply Filters ('), findsNothing);
    });
  });

  group('reset', () {
    testWidgets(
      'clears every touched field back to defaults and recounts immediately',
      (tester) async {
        final repo = FakeFilterRepository(count: 6);
        final container = ProviderContainer(
          overrides: [filterRepositoryProvider.overrideWithValue(repo)],
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

        await tester.enterText(textFieldIn('filterField-city'), 'Tashkent');
        await tester.pumpAndSettle();
        await tapVisible(
          tester,
          find.byKey(ValueKey('filterCategory-${AdCategory.sale}')),
        );

        expect((await readTextField(tester, 'filterField-city')).controller!.text, 'Tashkent');

        await tapVisible(tester, find.byKey(const ValueKey('filterSheet-reset')));

        expect((await readTextField(tester, 'filterField-city')).controller!.text, '');
        // Reset recounts immediately (no debounce wait needed to observe it).
        expect(repo.lastFilters?.city, isNull);
        expect(repo.lastFilters?.category, isNull);
        // Furniture/Repair fall back to their SCREENS.md §3.5 defaults, not
        // to "any".
        expect(repo.lastFilters?.furniture, Furniture.withFurniture);
        expect(repo.lastFilters?.repairment, Repairment.notRepaired);

        await tapVisible(tester, find.byKey(const ValueKey('filterSheet-apply')));

        expect(result!.city, isNull);
        expect(result!.category, isNull);
      },
    );
  });

  group('apply', () {
    testWidgets(
      'returns the full draft — free-text, chip, and price-ladder fields together',
      (tester) async {
        final repo = FakeFilterRepository(count: 2);
        final container = ProviderContainer(
          overrides: [filterRepositoryProvider.overrideWithValue(repo)],
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

        await tester.enterText(textFieldIn('filterField-city'), 'Tashkent');
        await tester.pumpAndSettle();
        await tester.enterText(
          textFieldIn('filterField-district'),
          'Chilonzor',
        );
        await tester.pumpAndSettle();

        await tapVisible(tester, find.byKey(const ValueKey('filterRooms-3')));
        await tapVisible(
          tester,
          find.byKey(ValueKey('filterCategory-${AdCategory.sale}')),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('filterPriceMin-100000')),
        );
        await tapVisible(
          tester,
          find.byKey(const ValueKey('filterPriceMax-1000000')),
        );
        // Re-tapping the already-selected Furniture chip deselects it back
        // to "any" — proves a caller-cleared field stays cleared, not
        // silently re-defaulted (see `filter_sheet.dart#_applyToLocalState`
        // vs `_seedDefaults`).
        await tapVisible(
          tester,
          find.byKey(ValueKey('filterFurniture-${Furniture.withFurniture}')),
        );

        await tapVisible(tester, find.byKey(const ValueKey('filterSheet-apply')));

        expect(result!.city, 'Tashkent');
        expect(result!.district, 'Chilonzor');
        expect(result!.rooms, 3);
        expect(result!.category, AdCategory.sale);
        expect(result!.priceMin, 100000);
        expect(result!.priceMax, 1000000);
        expect(result!.furniture, isNull);
        expect(result!.repairment, Repairment.notRepaired); // untouched default
      },
    );

    testWidgets(
      'a Storey number entry round-trips through Apply',
      (tester) async {
        final container = ProviderContainer(
          overrides: [
            filterRepositoryProvider.overrideWithValue(FakeFilterRepository()),
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
      },
    );
  });
}
