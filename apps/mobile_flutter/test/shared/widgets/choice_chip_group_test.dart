// Covers the disabled state of the shared `ChoiceChipGroup` — UX audit
// §10.5, "disabled states dim the explanation hardest".
//
// A disabled chip used to be the enabled chip under `Opacity(0.4)`, which
// fades the *label* — the only part that says which option this is — along
// with everything else. These tests pin the three things that replaced it:
// a recessed fill instead of the glass lens (so the chip stops advertising
// depth it can't act on), a `muted` label that is still readable, and a
// semantics node that actually reports `enabled: false` so a screen reader
// stops offering a control that does nothing.
//
// The label colour is asserted against `muted` rather than the `faint` the
// audit named, and that is load-bearing: light `faint` on light `sunk` is
// 4.39:1, the single sub-AA pairing `test/theme/contrast_test.dart` carries
// as a *non-text* exception. A disabled chip's label is text — the reason
// the chip is disabled is precisely what has to stay readable — so this
// asserts the AA-clearing token instead of the one that would quietly
// re-open §10.1 on a different surface.
//
// Pumped against `ChoiceChipGroup` directly rather than through a feature
// screen: `isEnabled` has no caller in `lib/features/` today (the filter
// sheet's price ladder, its original consumer, has since moved to a picker
// field), so this widget's own test is the only place the contract is
// stated at all.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

void main() {
  const enabledKey = ValueKey('probe-b');
  const disabledKey = ValueKey('probe-c');

  /// Three options with **equal-length labels** on purpose: the test font
  /// renders every glyph at one fixed width, so equal-length labels make
  /// the geometry assertion below ("a disabled chip measures exactly what
  /// the enabled one did") a statement about the box rather than about the
  /// copy.
  Future<List<String?>> pumpGroup(
    WidgetTester tester, {
    String? selected,
    Set<String> disabled = const {'c'},
  }) async {
    final changes = <String?>[];
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Center(
            child: ChoiceChipGroup<String>(
              keyPrefix: 'probe',
              options: const [
                ChoiceOption('a', 'Alpha'),
                ChoiceOption('b', 'Bravo'),
                ChoiceOption('c', 'Delta'),
              ],
              selected: selected,
              isEnabled: (value) => !disabled.contains(value),
              onChanged: changes.add,
            ),
          ),
        ),
      ),
    );
    return changes;
  }

  group('disabled chip painting', () {
    testWidgets('drops the glass lens for a sunk fill and a hairline', (
      tester,
    ) async {
      await pumpGroup(tester);

      // The enabled chip is glass; the disabled one must not be, or it goes
      // on advertising the same depth as a chip that responds to a tap.
      expect(
        find.descendant(
          of: find.byKey(enabledKey),
          matching: find.byType(GlassSurface),
        ),
        findsOneWidget,
      );
      expect(
        find.descendant(
          of: find.byKey(disabledKey),
          matching: find.byType(GlassSurface),
        ),
        findsNothing,
      );

      final box = tester.widget<Container>(
        find
            .descendant(
              of: find.byKey(disabledKey),
              matching: find.byType(Container),
            )
            .first,
      );
      final decoration = box.decoration! as BoxDecoration;
      expect(decoration.color, LaCasaColors.light.sunk);
      expect(decoration.border, Border.all(color: LaCasaColors.light.line));
      // No `.opt.on` drop shadow: a disabled chip is never the selected one
      // visually, whatever `selected` says.
      expect(decoration.boxShadow, isNull);
    });

    testWidgets('keeps the label legible in muted rather than fading it', (
      tester,
    ) async {
      await pumpGroup(tester);

      final label = tester.widget<Text>(
        find.descendant(
          of: find.byKey(disabledKey),
          matching: find.text('Delta'),
        ),
      );
      // `muted`, not `faint`: 4.65:1 on `sunk` versus 4.39:1. See this
      // file's header.
      expect(label.style!.color, LaCasaColors.light.muted);

      // The regression this replaces: the whole chip, label included, used
      // to sit under `Opacity(0.4)`.
      expect(
        find.descendant(
          of: find.byKey(disabledKey),
          matching: find.byType(Opacity),
        ),
        findsNothing,
      );
    });

    testWidgets('measures exactly what the enabled chip beside it does', (
      tester,
    ) async {
      await pumpGroup(tester);

      // The hairline is 1dp of the chip's own box, so the disabled padding
      // is deflated to match — otherwise a `Wrap` of options reflows by 2dp
      // per chip every time the constraint that disables them moves.
      expect(
        tester.getSize(find.byKey(disabledKey)),
        tester.getSize(find.byKey(enabledKey)),
      );
    });
  });

  group('disabled chip behaviour', () {
    testWidgets('ignores a tap while an enabled sibling still reports one', (
      tester,
    ) async {
      final changes = await pumpGroup(tester);

      await tester.tap(find.byKey(disabledKey));
      await tester.pump();
      expect(changes, isEmpty);

      await tester.tap(find.byKey(enabledKey));
      await tester.pump();
      expect(changes, ['b']);
    });
  });

  group('semantics', () {
    testWidgets('a disabled chip announces as a disabled button', (
      tester,
    ) async {
      // Disposed inline, not via addTearDown: WidgetTester's end-of-test
      // verification asserts every SemanticsHandle is already released and
      // runs before any registered tearDown.
      final handle = tester.ensureSemantics();
      await pumpGroup(tester);

      expect(
        tester.getSemantics(find.byKey(disabledKey)),
        isSemantics(
          label: 'Delta',
          isButton: true,
          hasEnabledState: true,
          isEnabled: false,
        ),
      );

      handle.dispose();
    });

    testWidgets('an enabled chip announces as an activatable button', (
      tester,
    ) async {
      final handle = tester.ensureSemantics();
      await pumpGroup(tester);

      // `button: true` matters on the live chips too: a bare
      // `GestureDetector` carries no role at all, so every chip in this app
      // used to read to a screen reader as plain text.
      expect(
        tester.getSemantics(find.byKey(enabledKey)),
        isSemantics(
          label: 'Bravo',
          isButton: true,
          hasEnabledState: true,
          isEnabled: true,
          hasTapAction: true,
        ),
      );

      handle.dispose();
    });

    testWidgets('the selected chip reports its selection', (tester) async {
      final handle = tester.ensureSemantics();
      await pumpGroup(tester, selected: 'b');

      expect(
        tester.getSemantics(find.byKey(enabledKey)),
        isSemantics(label: 'Bravo', isButton: true, isSelected: true),
      );

      handle.dispose();
    });
  });
}
