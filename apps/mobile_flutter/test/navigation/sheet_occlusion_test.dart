// Regression test for the sheet-occlusion bug (findings B2/B3/M3, and the
// functional half of M2): every `showModalBottomSheet` call opened from
// inside a shell branch must pass `useRootNavigator: true`, or the sheet
// mounts underneath `TabShellScaffold`'s floating `GlassTabBar` in both
// paint order AND hit-test order — see tab_shell_scaffold.dart's doc
// comment for the full mechanism.
//
// This can only be reproduced inside the *real* shell: a bare `MaterialApp`
// harness (as `language_sheet_test.dart` and friends use) has exactly one
// Navigator, so `useRootNavigator` is a no-op there and the bug simply
// cannot occur — this file is the one place that pumps the real
// `goRouterProvider` tree (TabShellScaffold + GlassTabBar included) so the
// occluding sibling actually exists to be occluded by.
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import 'package:lacasa_mobile/features/home/home.dart';
import 'package:lacasa_mobile/features/profile/widgets/profile_signed_out_screen.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/navigation/app_router.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/ambient_repository_overrides.dart';

void main() {
  Future<GoRouter> pumpApp(WidgetTester tester) async {
    // Pumping the real router mounts the whole app shell, which touches
    // nearly every repository in the app; without these the un-overridden
    // providers fire real HTTP and `pumpAndSettle` times out. This file
    // overrides none of them itself, so every ambient flag stays on.
    final container = ProviderContainer(
      overrides: ambientRepositoryOverrides(),
    );
    addTearDown(container.dispose);
    final router = container.read(goRouterProvider);

    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp.router(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          routerConfig: router,
        ),
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  testWidgets(
    'language-sheet, opened inside the Profile branch, absorbs a tap aimed '
    "at the tab bar's Home button instead of switching tabs to it",
    (tester) async {
      await pumpApp(tester);

      // Signed out -> the buyer shell, whose four branches are
      // 0=Home, 1=Search, 2=Agents, 3=Profile (glass_tab_bar.dart's
      // `buyerTabItems`). The agent shell is a separate route entirely and
      // is not mounted for this session at all.
      await tester.tap(find.byKey(const ValueKey('navTab-3')));
      await tester.pumpAndSettle();
      expect(find.byType(ProfileSignedOutScreen), findsOneWidget);

      // Capture the Home tab button's on-screen position *before* the sheet
      // opens — this is the exact coordinate the bug report's "lands on the
      // tab bar and navigates Home" describes.
      final homeTabCenter = tester.getCenter(
        find.byKey(const ValueKey('navTab-0')),
      );

      await tester.tap(find.text('Language'));
      await tester.pumpAndSettle();
      // Sanity check the sheet is actually open before asserting anything
      // about where its taps go.
      expect(find.text('Ru'), findsOneWidget);

      // A `showModalBottomSheet`'s route always installs a full-screen
      // `ModalBarrier` ahead of anything below it in the *same* Overlay —
      // that barrier can only out-rank GlassTabBar for every point on
      // screen (this one included) if the sheet's route lives in the root
      // Navigator's Overlay, stacked above the shell page GlassTabBar is
      // part of. Tapping the old tab button's exact coordinate must
      // therefore be swallowed by the sheet, never reach the button
      // underneath.
      await tester.tapAt(homeTabCenter);
      await tester.pumpAndSettle();

      expect(
        find.byType(HomeFeedScreen),
        findsNothing,
        reason:
            'the tap reached GlassTabBar\'s Home button through the open '
            'sheet — useRootNavigator: true is missing (or ineffective) on '
            'showLanguageSheet\'s showModalBottomSheet call',
      );
      // Still on the Profile branch — confirms the tap never reached the
      // tab bar at all, one way or another (either the sheet's own barrier
      // or its panel absorbed it).
      expect(find.byType(ProfileSignedOutScreen), findsOneWidget);
    },
  );
}
