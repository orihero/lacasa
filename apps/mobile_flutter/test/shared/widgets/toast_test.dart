// Covers the two halves of "the toast look is defined in exactly one place":
// `LaCasaToast` for anything raised through it, and
// `AppTheme`'s `SnackBarThemeData` for anything that still builds a bare
// [SnackBar] somewhere in `features/`.
//
// Both were asserted only by reading the code before this. `toast.dart`'s doc
// comment promised an "accent-coloured" action, but nothing in the toast
// system produced one — the single action toast in the app
// (`favourite_button.dart`'s "Sign in") passed its own `textColor`, so the
// second one anyone wrote would have shipped in Material's `inversePrimary`
// and no test would have noticed. And the theme carried no `snackBarTheme` at
// all, so a bare `SnackBar` rendered as Material's docked dark-grey bar,
// visibly a different component from the toast beside it.
//
// The theme assertions live here, next to the widget whose contract they
// complete, rather than in `test/theme/`: `SnackBarThemeData` is not a
// palette entry, it is the fallback half of this file's subject, and the
// two drift apart if they are asserted apart.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

void main() {
  /// Pumps a screen whose only button raises [raise] on its own context.
  Future<void> pumpRaiser(
    WidgetTester tester,
    void Function(BuildContext context) raise,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => raise(context),
              child: const Text('raise'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('raise'));
    await tester.pumpAndSettle();
  }

  Material snackBarMaterial(WidgetTester tester) {
    // The outermost Material inside a SnackBar is the bar itself — the one
    // built with the resolved background colour; the action's TextButton
    // brings its own further down.
    return tester.widget<Material>(
      find
          .descendant(
            of: find.byType(SnackBar),
            matching: find.byType(Material),
          )
          .first,
    );
  }

  group('the action colour belongs to the toast system', () {
    testWidgets('an action with no textColor still renders in the accent', (
      tester,
    ) async {
      await pumpRaiser(
        tester,
        (context) => LaCasaToast.showInfo(
          context,
          'Sign in to save listings',
          action: SnackBarAction(label: 'Sign in', onPressed: () {}),
        ),
      );

      // Read back what the framework resolved rather than what was passed:
      // [SnackBarAction] falls back `textColor ?? snackBarTheme
      // .actionTextColor ?? defaults.actionTextColor`, and this asserts the
      // middle one won — i.e. a call site that says nothing gets the accent.
      final button = tester.widget<TextButton>(
        find.ancestor(
          of: find.text('Sign in'),
          matching: find.byType(TextButton),
        ),
      );
      expect(
        button.style?.foregroundColor?.resolve(<WidgetState>{}),
        AppAccent.color,
      );
    });
  });

  group('a bare SnackBar inherits the toast look', () {
    testWidgets('it lands on the floating card bar, not Material\'s docked '
        'dark-grey one', (tester) async {
      await pumpRaiser(
        tester,
        (context) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('bare'))),
      );

      expect(snackBarMaterial(tester).color, LaCasaColors.light.card);
      // Floating leaves the theme's inset padding down each side; a fixed
      // bar spans the scaffold edge to edge. Measuring that is how the
      // behaviour is observable at all — the widget's own `behavior` is null
      // here, since the value comes from the theme.
      expect(
        tester
            .getRect(
              find
                  .descendant(
                    of: find.byType(SnackBar),
                    matching: find.byType(Material),
                  )
                  .first,
            )
            .width,
        lessThan(tester.getSize(find.byType(Scaffold)).width),
      );
    });

    testWidgets('its copy is ink, which is the reason the theme sets a '
        'contentTextStyle at all', (tester) async {
      await pumpRaiser(
        tester,
        (context) => ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('bare'))),
      );

      // Material derives snack bar copy from `colorScheme.onInverseSurface`
      // — near-white, and therefore invisible once the bar is `colors.card`.
      // Overriding the background without the text colour would have been a
      // worse bug than the one being fixed.
      expect(
        DefaultTextStyle.of(tester.element(find.text('bare'))).style.color,
        LaCasaColors.light.ink,
      );
    });
  });

  group('both theme factories carry it', () {
    void expectToastLook(ThemeData theme, LaCasaColors colors) {
      final snack = theme.snackBarTheme;
      expect(snack.behavior, SnackBarBehavior.floating);
      expect(snack.backgroundColor, colors.card);
      expect(snack.actionTextColor, AppAccent.color);
      expect(snack.contentTextStyle?.color, colors.ink);
    }

    test('light', () => expectToastLook(AppTheme.light(), LaCasaColors.light));

    // Asserted separately rather than in a loop over the two factories: a
    // token that is right in one brightness and wrong in the other is the
    // exact failure `test/theme/contrast_test.dart` exists to catch, and a
    // named case says which build broke.
    test('dark', () => expectToastLook(AppTheme.dark(), LaCasaColors.dark));
  });
}
