// Widget tests for `create-listing`'s step footer (SCREENS.md §26) —
// specifically the disabled state, which UX audit §10.5 found was a flat
// `Opacity(0.6)` over the full accent gradient and glow. "Can't continue"
// and "continue" have to be distinguishable at a glance on the control
// that gates creating a listing at all, and the reason has to be visible.
//
// `ListingWizardFooter` is a pure `StatelessWidget` with no `ref` and no
// repository behind it, so these pump it directly. There is no fixture
// fallback to fall into and no HTTP to fire.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/features/listing_editor/widgets/form/wizard_footer.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/theme/theme.dart';

void main() {
  Future<void> pumpFooter(
    WidgetTester tester, {
    required VoidCallback? onPrimary,
    VoidCallback? onBack,
    bool submitting = false,
    String? disabledReason,
  }) async {
    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          body: Align(
            alignment: Alignment.bottomCenter,
            child: ListingWizardFooter(
              onBack: onBack,
              primaryLabel: 'Next',
              onPrimary: onPrimary,
              submitting: submitting,
              disabledReason: disabledReason,
            ),
          ),
        ),
      ),
    );
    // `pumpAndSettle` when there is nothing left to animate; a single frame
    // when `submitting`, because the spinner it paints is an indeterminate
    // `CircularProgressIndicator` whose animation never ends — settling on
    // it times the test out rather than telling us anything.
    if (submitting) {
      await tester.pump();
    } else {
      await tester.pumpAndSettle();
    }
  }

  /// The primary control's own painted box — the `Container` the
  /// `listingWizard-primary` gesture detector wraps.
  BoxDecoration primaryDecoration(WidgetTester tester) {
    final container = tester.widget<Container>(
      find
          .descendant(
            of: find.byKey(const ValueKey('listingWizard-primary')),
            matching: find.byType(Container),
          )
          .first,
    );
    return container.decoration! as BoxDecoration;
  }

  group('the enabled primary is unmistakably the accent control', () {
    testWidgets('it keeps the gradient and the glow, and says nothing about '
        'being unavailable', (tester) async {
      await pumpFooter(tester, onPrimary: () {});

      final decoration = primaryDecoration(tester);
      expect(decoration.gradient, AppAccent.gradient);
      expect(decoration.boxShadow, isNotNull);
      expect(
        find.byKey(const ValueKey('listingWizard-disabledReason')),
        findsNothing,
      );
    });

    testWidgets('submitting is not the disabled state — the tap landed, so '
        'the accent stays and no reason is offered', (tester) async {
      // The distinction the footer's doc comment draws: mid-submit there is
      // no user-fixable reason to explain, so this must not be dressed up
      // as "you can't continue".
      await pumpFooter(tester, onPrimary: () {}, submitting: true);

      expect(primaryDecoration(tester).gradient, AppAccent.gradient);
      expect(find.byType(CircularProgressIndicator), findsOneWidget);
      expect(
        find.byKey(const ValueKey('listingWizard-disabledReason')),
        findsNothing,
      );
    });
  });

  group('the disabled primary is a different control, not a faded one', () {
    testWidgets('it drops the gradient and the accent glow entirely', (
      tester,
    ) async {
      await pumpFooter(tester, onPrimary: null);

      final decoration = primaryDecoration(tester);
      // The finding: a 60%-alpha accent gradient under a coloured shadow is
      // still unmistakably *the accent button*, so the disabled footer read
      // as tappable on the one screen where tapping is the whole point.
      expect(
        decoration.gradient,
        isNull,
        reason: 'a disabled primary must not keep the accent gradient',
      );
      expect(
        decoration.boxShadow,
        isNull,
        reason: 'a disabled primary must not keep the accent glow',
      );
      expect(
        decoration.color,
        AppTheme.light().extension<LaCasaColors>()!.sunk,
      );

      // And nothing anywhere above it is quietly fading the whole thing
      // instead — that is the treatment this replaced.
      final fades = tester.widgetList<Opacity>(
        find.ancestor(
          of: find.byKey(const ValueKey('listingWizard-primary')),
          matching: find.byType(Opacity),
        ),
      );
      expect(fades.every((o) => o.opacity == 1), isTrue);
    });

    testWidgets('it states why, at full opacity, above the row', (
      tester,
    ) async {
      await pumpFooter(tester, onPrimary: null);

      final reason = find.byKey(const ValueKey('listingWizard-disabledReason'));
      expect(reason, findsOneWidget);
      expect(
        tester.widget<Text>(reason).data,
        'Fill in the required fields to continue.',
      );
      // §10.5's actual complaint is that the explanation gets dimmed
      // hardest. `ink2`, undimmed, is the fix.
      expect(
        tester.widget<Text>(reason).style?.color,
        AppTheme.light().extension<LaCasaColors>()!.ink2,
      );
      final fades = tester.widgetList<Opacity>(
        find.ancestor(of: reason, matching: find.byType(Opacity)),
      );
      expect(fades.every((o) => o.opacity == 1), isTrue);

      // Above the row, not tucked under it — the reader hits it before the
      // control it explains.
      expect(
        tester.getRect(reason).bottom,
        lessThanOrEqualTo(
          tester
              .getRect(find.byKey(const ValueKey('listingWizard-primary')))
              .top,
        ),
      );
    });

    testWidgets('a caller with a more specific reason gets to print it', (
      tester,
    ) async {
      await pumpFooter(
        tester,
        onPrimary: null,
        disabledReason: 'Wait for the photo uploads to finish.',
      );

      expect(
        tester
            .widget<Text>(
              find.byKey(const ValueKey('listingWizard-disabledReason')),
            )
            .data,
        'Wait for the photo uploads to finish.',
      );
    });

    testWidgets('it is disabled to a screen reader too', (tester) async {
      await pumpFooter(tester, onPrimary: null);

      // `Opacity` is invisible to semantics, so the old treatment told a
      // screen-reader user nothing at all about being unavailable.
      final semantics = tester.widget<Semantics>(
        find
            .ancestor(
              of: find.byKey(const ValueKey('listingWizard-primary')),
              matching: find.byType(Semantics),
            )
            .first,
      );
      expect(semantics.properties.button, isTrue);
      expect(semantics.properties.enabled, isFalse);
    });
  });

  group('Back is unaffected', () {
    testWidgets('a disabled primary still leaves Back live', (tester) async {
      var backs = 0;
      await pumpFooter(tester, onPrimary: null, onBack: () => backs++);

      await tester.tap(find.byKey(const ValueKey('listingWizard-back')));
      await tester.pumpAndSettle();

      // Losing the way *out* of a step you cannot complete would be the
      // worst possible reading of "disabled".
      expect(backs, 1);
    });
  });
}
