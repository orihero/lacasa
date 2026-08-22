// Widget tests for `filter-sheet`'s CRM variant seam (build contract rule
// 3/§3.1 — `my_listings` is the sole caller, wiring it inside
// `lib/features/filter/` per that rule's one sanctioned exception). Covers
// two things: the buyer-facing `showFilterSheet` path is unaffected (no
// Sort/Status UI, still returns a bare `AdFilters`), and `showCrmFilterSheet`
// renders + returns the appended fields correctly.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/filter/filter.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../../support/ambient_repository_overrides.dart';

void main() {
  Widget openButton(Future<void> Function(BuildContext context) onOpen) {
    return ProviderScope(
      // The repository providers now build live implementations around
      // `LaCasaApi.create()` unconditionally, so anything the sheet touches
      // incidentally (the live count row's `filterRepository`, the
      // City/District cascade's `regionsRepository`) would fire real HTTP
      // and hang `pumpAndSettle`. Nothing here asserts on filtered content,
      // so the inert ambient set is exactly right.
      overrides: [...ambientRepositoryOverrides()],
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

  group('buyer variant (showFilterSheet) — unaffected by the CRM seam', () {
    testWidgets('never renders Sort/Status and returns a bare AdFilters', (
      tester,
    ) async {
      AdFilters? result;
      await tester.pumpWidget(
        openButton((context) async {
          result = await showFilterSheet(context);
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('Sort'), findsNothing);
      expect(find.text('Status'), findsNothing);

      await tester.tap(find.byKey(const ValueKey('filterSheet-apply')));
      await tester.pumpAndSettle();

      expect(result, isA<AdFilters>());
    });
  });

  group('CRM variant (showCrmFilterSheet)', () {
    testWidgets('renders Sort + Status appended below the shared fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        openButton((context) async {
          await showCrmFilterSheet(context);
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.text('SORT'), findsOneWidget);
      expect(find.text('STATUS'), findsOneWidget);
      expect(find.text('Newest'), findsOneWidget);
      expect(find.text('Highest price'), findsOneWidget);
      expect(find.text('Lowest price'), findsOneWidget);
      expect(find.text('Active'), findsOneWidget);
      expect(find.text('Sold'), findsOneWidget);
      expect(find.text('Draft'), findsOneWidget);
    });

    testWidgets(
      'never shows a live result-count badge — the buyer-feed count would '
      'be dishonest here (build contract: no fabricated counts)',
      (tester) async {
        await tester.pumpWidget(
          openButton((context) async {
            await showCrmFilterSheet(context);
          }),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        expect(find.text('Apply Filters'), findsOneWidget);
        expect(find.textContaining('Apply Filters ('), findsNothing);
      },
    );

    testWidgets('Apply returns the selected Sort + Status', (tester) async {
      FilterSheetResult? result;
      await tester.pumpWidget(
        openButton((context) async {
          result = await showCrmFilterSheet(context);
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      // The sheet's own `SingleChildScrollView` builds every field eagerly
      // (a plain `Column`, not a lazy list), but Sort + Status — appended
      // last — sit below the default 800×600 test surface until scrolled
      // into view; `ensureVisible` finds the ancestor `Scrollable` and
      // brings each target on-screen before the tap (mirrors
      // `my_listings_screen_test.dart`'s own fix for the same seam).
      final sortChip = find.byKey(
        ValueKey('filterCrmSort-${AdSort.lowestPrice}'),
      );
      await tester.ensureVisible(sortChip);
      await tester.pumpAndSettle();
      await tester.tap(sortChip);

      final statusChip = find.byKey(
        ValueKey('filterCrmStatus-${AdStage.draft}'),
      );
      await tester.ensureVisible(statusChip);
      await tester.pumpAndSettle();
      await tester.tap(statusChip);

      await tester.tap(find.byKey(const ValueKey('filterSheet-apply')));
      await tester.pumpAndSettle();

      expect(result, isNotNull);
      expect(result!.sort, AdSort.lowestPrice);
      expect(result!.status, AdStage.draft);
    });

    testWidgets(
      'a re-tap of the selected Status chip deselects back to "All"',
      (tester) async {
        FilterSheetResult? result;
        await tester.pumpWidget(
          openButton((context) async {
            result = await showCrmFilterSheet(
              context,
              initialStatus: AdStage.sold,
            );
          }),
        );

        await tester.tap(find.text('open'));
        await tester.pumpAndSettle();

        // See the "Apply returns the selected Sort + Status" test above
        // for why this needs `ensureVisible` first.
        final statusChip = find.byKey(
          ValueKey('filterCrmStatus-${AdStage.sold}'),
        );
        await tester.ensureVisible(statusChip);
        await tester.pumpAndSettle();
        await tester.tap(statusChip);

        await tester.tap(find.byKey(const ValueKey('filterSheet-apply')));
        await tester.pumpAndSettle();

        expect(result!.status, isNull);
      },
    );

    testWidgets('Reset clears Sort back to Newest and Status to "All"', (
      tester,
    ) async {
      FilterSheetResult? result;
      await tester.pumpWidget(
        openButton((context) async {
          result = await showCrmFilterSheet(
            context,
            initialSort: AdSort.highestPrice,
            initialStatus: AdStage.active,
          );
        }),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const ValueKey('filterSheet-reset')));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('filterSheet-apply')));
      await tester.pumpAndSettle();

      expect(result!.sort, AdSort.newest);
      expect(result!.status, isNull);
    });
  });
}
