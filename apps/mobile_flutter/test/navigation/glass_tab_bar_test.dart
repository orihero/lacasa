// Guards the tab bar's unselected state (lib/navigation/shell/glass_tab_bar.dart).
//
// An unselected tab is icon-only — `.tab span{display:none}` hides the label
// until the tab is `.on` — so the glyph carries the whole affordance with no
// pill and no shadow behind it. The mockup compensates twice: `.tab` keeps the
// *secondary* ink tier (`color:var(--ink-2)`, not the tertiary `--muted` that
// quiet body copy uses), and `.tab .i{font-size:21px}` makes the unselected
// glyph the larger of the two against `.tab.on .i{font-size:17px}`. Dropping
// either one is what made unselected tabs read as invisible on glass.
//
// Pumped through the real router (as test/navigation/tab_shell_test.dart does)
// because GlassTabBar takes a live [StatefulNavigationShell].

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/app_router.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/ambient_repository_overrides.dart';

void main() {
  Future<void> pumpApp(WidgetTester tester, ThemeData theme) async {
    final container = ProviderContainer(
      overrides: ambientRepositoryOverrides(),
    );
    addTearDown(container.dispose);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: theme,
          routerConfig: container.read(goRouterProvider),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Icon tabIcon(WidgetTester tester, int branchIndex) => tester.widget<Icon>(
    find.descendant(
      of: find.byKey(ValueKey('navTab-$branchIndex')),
      matching: find.byType(Icon),
    ),
  );

  // Built inside the test body, not at collection time: AppTheme reaches
  // for google_fonts, which needs an initialized binding.
  for (final (name, build) in <(String, ThemeData Function())>[
    ('light', AppTheme.light),
    ('dark', AppTheme.dark),
  ]) {
    testWidgets('an unselected tab icon uses ink2, not muted ($name)', (
      tester,
    ) async {
      final theme = build();
      await pumpApp(tester, theme);
      final colors = theme.extension<LaCasaColors>()!;

      // Tab 0 (Home) is the buyer shell's landing branch, so 1..3 are the
      // unselected ones.
      for (final index in [1, 2, 3]) {
        expect(tabIcon(tester, index).color, colors.ink2);
        expect(tabIcon(tester, index).color, isNot(colors.muted));
      }
    });
  }

  testWidgets('the selected tab keeps its pill inversion', (tester) async {
    await pumpApp(tester, AppTheme.light());
    final colors = AppTheme.light().extension<LaCasaColors>()!;

    expect(tabIcon(tester, 0).color, colors.pillInk);
    // The label only exists on the selected tab (`.tab span{display:none}` /
    // `.tab.on span{display:block}`), which is the other half of why an
    // unselected glyph has to carry more weight on its own.
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('navTab-0')),
        matching: find.byType(Text),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byKey(const ValueKey('navTab-1')),
        matching: find.byType(Text),
      ),
      findsNothing,
    );
  });

  testWidgets('an unselected glyph is drawn larger than a selected one', (
    tester,
  ) async {
    await pumpApp(tester, AppTheme.light());

    // `.tab .i{font-size:21px}` vs `.tab.on .i{font-size:17px}`.
    expect(tabIcon(tester, 0).size, 17);
    expect(tabIcon(tester, 1).size, 21);
  });
}
