// Widget tests for the `.rail.chips` category row
// (lib/features/home/widgets/category_chip_row.dart).
//
// Two groups, for the two things this row has to get right.
//
// **Behaviour.** The row used to be decorative: a tap moved
// [selectedCategoryChipProvider] and nothing anywhere read it, so a chip
// answered a tap with a full selected state and no change to the app. A
// later pass made a tap navigate to the Search tab carrying an
// `AdFilters(type:)`. It now does neither: a tap narrows the *Home* feed
// where it stands, by writing the type `homeFeedAdsProvider` re-fetches
// with. Because that is a *product* change (the build spec still calls the
// row decorative), these tests pin the exact request the chip causes rather
// than just "something happened", and they pin that the row no longer
// reaches across into Search's own filter state.
//
// **Geometry**, which is where it drifted before: a chip used to change size
// when it was selected (the mockup's `.chip.on` trades 7px of left padding
// for a 14px-wider icon box, so it grows), and the rail used to be exactly as
// tall as a chip, so `ListView`'s viewport clip sheared the selected chip's
// lift off flat at both edges.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/home/state/home_feed_providers.dart';
import 'package:lacasa_mobile/features/home/state/home_feed_repository_provider.dart';
import 'package:lacasa_mobile/features/home/widgets/category_chip_row.dart';
import 'package:lacasa_mobile/features/search/state/search_providers.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import 'support/fake_home_feed_repository.dart';

void main() {
  /// Pumps the row on its own, over a recording feed repository. No router:
  /// a chip no longer navigates, and the thing worth observing is the
  /// request it causes, which [FakeHomeFeedRepository.feedFilterLog]
  /// records.
  Future<(ProviderContainer, FakeHomeFeedRepository)> pumpChipRow(
    WidgetTester tester,
  ) async {
    final repository = FakeHomeFeedRepository();
    final container = ProviderContainer(
      overrides: [
        homeFeedRepositoryProvider.overrideWithValue(repository),
      ],
    );
    addTearDown(container.dispose);

    // The row itself does not read the feed — the rails below it do, and
    // they are not in this tree. Holding a subscription open stands in for
    // them, so the provider is alive to react to a chip the way it is on
    // the real screen.
    container.listen(homeFeedAdsProvider, (previous, next) {},
        fireImmediately: true);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: const Scaffold(
            body: Align(alignment: Alignment.topLeft, child: CategoryChipRow()),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    return (container, repository);
  }

  Finder chip(int index) => find.byKey(ValueKey('categoryChip-$index'));

  group('behaviour', () {
    testWidgets('a category chip re-fetches the Home feed for its type', (
      tester,
    ) async {
      final (container, repository) = await pumpChipRow(tester);

      // The feed's opening request carries no constraint: "All" is the
      // initial chip.
      expect(repository.feedFilterLog.single.type, isNull);

      // Index 3 is Office — `AdType.nonresidential`.
      await tester.tap(chip(3));
      await tester.pumpAndSettle();

      expect(repository.feedFilterLog.last.type, AdType.nonresidential);
      // The chip sets one axis and only one: a landing-screen chip that also
      // carried a city or a price would narrow the feed past what its single
      // word claims.
      final sent = repository.feedFilterLog.last;
      expect(sent.city, isNull);
      expect(sent.district, isNull);
      expect(sent.category, isNull);
      expect(sent.priceMin, isNull);
      expect(sent.priceMax, isNull);
      expect(sent.q, isNull);

      // ...and it stays on Home. Nothing was written to the Search tab's
      // filter state, so its Filters badge still counts only what the user
      // set over there.
      expect(container.read(appliedSearchFiltersProvider).type, isNull);
      expect(container.read(activeFilterCountProvider), 0);
    });

    testWidgets('"All" clears the category back to the whole feed', (
      tester,
    ) async {
      final (container, repository) = await pumpChipRow(tester);

      await tester.tap(chip(3));
      await tester.pumpAndSettle();
      expect(repository.feedFilterLog.last.type, AdType.nonresidential);

      await tester.tap(chip(0));
      await tester.pumpAndSettle();

      expect(repository.feedFilterLog.last.type, isNull);
      expect(container.read(selectedCategoryChipProvider).type, isNull);
      expect(_isSelected(0), isTrue);
    });

    testWidgets('moving between two chips of the same type does not '
        're-request', (tester) async {
      // Apartment (1) and House (2) both map to `AdType.residential` —
      // nothing in the API distinguishes them. The highlight must still
      // move, but the identical request must not be sent again, which is
      // what would throw every rail on the screen back to shimmer.
      final (container, repository) = await pumpChipRow(tester);

      await tester.tap(chip(1));
      await tester.pumpAndSettle();
      final afterApartment = repository.fetchFeedCallCount;
      expect(repository.feedFilterLog.last.type, AdType.residential);

      await tester.tap(chip(2));
      await tester.pumpAndSettle();

      expect(repository.fetchFeedCallCount, afterApartment);
      expect(container.read(selectedCategoryChipProvider).index, 2);
      expect(_isSelected(2), isTrue);
      expect(_isSelected(1), isFalse);
    });

    testWidgets('a chip announces itself as a control that does something', (
      tester,
    ) async {
      await pumpChipRow(tester);

      // The visible label is one word; the screen-reader label says what
      // tapping it does. Both exist, and the word is not announced twice
      // (the inner Text is excluded from the semantics tree).
      expect(find.text('Apartment'), findsOneWidget);
      expect(find.bySemanticsLabel('Show Apartment listings'), findsOneWidget);
    });

    testWidgets('a screen-reader user can actually activate a chip', (
      tester,
    ) async {
      // Regression: the chip's `Semantics(excludeSemantics: true)` wrapper
      // drops the whole descendant subtree, and the inner GestureDetector's
      // `tap` action went with it — leaving a node that announced itself as
      // a button but did nothing when TalkBack/VoiceOver double-tapped it.
      // The label test above passed throughout, because a label is not an
      // action; this one drives the row the way assistive tech does.
      //
      // Disposed inline rather than via addTearDown, matching
      // test/shared/widgets/tap_target_test.dart: WidgetTester's
      // end-of-test verification asserts every SemanticsHandle is already
      // released and runs before any registered tearDown.
      final handle = tester.ensureSemantics();
      final (_, repository) = await pumpChipRow(tester);

      expect(
        tester.getSemantics(chip(1)),
        isSemantics(
          label: 'Show Apartment listings',
          isButton: true,
          hasTapAction: true,
        ),
      );

      tester.semantics.tap(find.semantics.byLabel('Show Apartment listings'));
      await tester.pumpAndSettle();

      // The same outcome the pointer tap above produces: the feed is
      // re-requested for the chip's category.
      expect(repository.feedFilterLog.last.type, AdType.residential);
      expect(_isSelected(1), isTrue);

      handle.dispose();
    });
  });

  group('selection state', () {
    testWidgets('"All" is lit on a feed with no category chosen', (
      tester,
    ) async {
      await pumpChipRow(tester);

      expect(_isSelected(0), isTrue);
      expect(_isSelected(1), isFalse);
    });

    testWidgets('exactly one chip is lit, and it is the one last tapped', (
      tester,
    ) async {
      await pumpChipRow(tester);

      await tester.tap(chip(1));
      await tester.pumpAndSettle();

      expect(_isSelected(0), isFalse);
      expect(_isSelected(1), isTrue);
      expect(_isSelected(2), isFalse);
      expect(_isSelected(3), isFalse);
      expect(_isSelected(4), isFalse);
    });
  });

  group('geometry', () {
    testWidgets('a chip is the same size selected as it is unselected', (
      tester,
    ) async {
      await pumpChipRow(tester);

      // "All" (index 0) is selected by default.
      final selectedSize = tester.getSize(chip(0));

      // Move the selection to a different chip and re-measure the *same*
      // chip, so the label — and therefore every other width contribution —
      // is held constant across the two states.
      await tester.tap(chip(1));
      await tester.pumpAndSettle();
      final unselectedSize = tester.getSize(chip(0));

      expect(unselectedSize, selectedSize);
    });

    testWidgets('the glass pill paints at the same size as the ink pill, not '
        'just inside a box the same size', (tester) async {
      // Regression, and the reason the two tests either side of this one
      // did not catch it: `GlassSurface` was given an `alignment`, which
      // expands the *box* to the rail's 40dp while leaving the lens — the
      // thing actually painted — at its 30dp content height, centred. Every
      // box-level measurement read 40 in both states while the chips
      // visibly grew and shrank on tap. This measures the painted pill:
      // the lens for the glass state, the decorated box for the ink one.
      await pumpChipRow(tester);

      // "All" (index 0) is selected by default, so 0 is ink and 1 is glass.
      final inkHeight = tester
          .getSize(
            find
                .descendant(of: chip(0), matching: find.byType(DecoratedBox))
                .first,
          )
          .height;
      final glassHeight = tester
          .getSize(
            find.descendant(
              of: chip(1),
              matching: find.byType(LiquidGlassLens),
            ),
          )
          .height;

      expect(inkHeight, 40);
      expect(glassHeight, 40);
    });

    testWidgets('the rail does not clip the selected chip\'s shadow', (
      tester,
    ) async {
      // `AppShadows.selectedChip` is `0 8px 18px -4px` — ~22dp below the
      // pill, in a band that leaves 4. With the ListView's default
      // `Clip.hardEdge` the shadow was sheared into a hard line flush
      // against the pill's bottom edge, which reads as bulk rather than
      // elevation. The rail spans the full screen width, so it can simply
      // stop clipping.
      await pumpChipRow(tester);

      final listView = tester.widget<ListView>(
        find.descendant(
          of: find.byType(CategoryChipRow),
          matching: find.byType(ListView),
        ),
      );
      expect(listView.clipBehavior, Clip.none);
    });

    testWidgets('both chip states render at the mockup\'s 40px height', (
      tester,
    ) async {
      await pumpChipRow(tester);

      // `.chip{height:40px}` — the rail is 46 tall (`.rail{padding:2px 20px
      // 4px}`), and the chips themselves must be exactly 40.
      expect(tester.getSize(chip(0)).height, 40);
      expect(tester.getSize(chip(1)).height, 40);
      expect(tester.getSize(find.byType(CategoryChipRow)).height, 46);
    });

    testWidgets('the rail reserves a band above and below the chips for the '
        'selected chip\'s lift', (tester) async {
      await pumpChipRow(tester);

      final railTop = tester.getTopLeft(find.byType(CategoryChipRow)).dy;
      final railBottom = tester.getBottomLeft(find.byType(CategoryChipRow)).dy;
      final chipTop = tester.getTopLeft(chip(0)).dy;
      final chipBottom = tester.getBottomLeft(chip(0)).dy;

      expect(chipTop - railTop, 2);
      expect(railBottom - chipBottom, 4);
    });
  });
}

/// A selected chip paints an ink [Container]; an unselected one paints a
/// [GlassSurface]. The absence of the glass is therefore the selected state
/// as far as the rendered tree is concerned — asserted this way rather than
/// by digging a colour out of a `BoxDecoration`, which would break on any
/// palette change without the behaviour having moved at all.
bool _isSelected(int index) => find
    .descendant(
      of: find.byKey(ValueKey('categoryChip-$index')),
      matching: find.byType(GlassSurface),
    )
    .evaluate()
    .isEmpty;
