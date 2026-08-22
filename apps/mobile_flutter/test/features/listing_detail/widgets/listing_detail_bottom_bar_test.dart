// Regression test for the M1 residual bug: the sticky bottom bar's price
// used to be a `Flexible(child: Text(..., overflow: TextOverflow.ellipsis))`
// — fine for a USD price, but a UZS sale price routinely runs 10+ digits
// ("3,650,000,000 so'm" vs "$ 1,250,000") and the bar's `_minPriceWidth`
// budget (96, sized for a USD figure) was never widened for it. Confirmed
// on device on the Chilonzor commercial UZS listing at a 320pt width: the
// bar rendered "3,650,00…", silently dropping the last four digits and the
// currency suffix of a real asking price.
//
// This is deliberately its own file rather than an addition to
// `listing_detail_screen_test.dart`'s "layout holds at real phone widths"
// group: that group only asserts the *absence of a RenderFlex overflow
// error*, and `TextOverflow.ellipsis` never throws one — it fails silently,
// which is exactly how a prior pass's fix attempt could pass a widget test
// while still truncating on a real device. Catching truncation itself needs
// a different signal: `RenderParagraph.didExceedMaxLines`, which is `true`
// whenever a `maxLines`-capped paragraph was laid out narrower than the text
// needed. The fix wraps the price in a `FittedBox` instead, which lays its
// child out with no width constraint at all (then scales the *rendered*
// size to fit) — so `didExceedMaxLines` is structurally always `false`
// post-fix, and was `true` pre-fix for exactly the UZS fixture below.

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/features/listing_detail/widgets/listing_detail_bottom_bar.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/theme/theme.dart';

import '../support/listing_detail_test_ads.dart';

void main() {
  // `ListingDetailBottomBar` only needs a `Theme` (for `LaCasaColors`/
  // `LaCasaTypography`) and `AppLocalizations` — no router, no Riverpod —
  // so it is pumped directly rather than through the full screen harness
  // `listing_detail_screen_test.dart` uses. `Positioned` (the bar's own
  // root) needs a `Stack` ancestor, which the `Scaffold` body supplies.
  Future<void> pumpBar(WidgetTester tester, {required Size size}) async {
    tester.view.physicalSize = size;
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          body: Stack(
            children: [
              ListingDetailBottomBar(
                ad: testAd(
                  price: 3650000000,
                  area: 600,
                  category: 'sale',
                  priceType: 'uzs',
                ),
                onSubmitApplication: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets(
    'a ten-figure UZS price renders complete, never ellipsized, at the '
    'exact width this reproduced on device (320pt)',
    (tester) async {
      await pumpBar(tester, size: const Size(320, 640));

      const priceText = "3,650,000,000 so'm";
      final finder = find.text(priceText);
      // If this fails, the bar dropped back to truncating: `find.text`
      // matches a `Text` widget's `data` verbatim, so a shorter/ellipsized
      // render would make this finder come up empty even though *some*
      // price is on screen — the failure itself is the signal.
      expect(
        finder,
        findsOneWidget,
        reason:
            'the bar is not showing the full price string as a single Text '
            'widget — it may be truncating again',
      );

      final paragraph = tester.renderObject<RenderParagraph>(finder);
      expect(
        paragraph.didExceedMaxLines,
        isFalse,
        reason:
            'RenderParagraph laid the price out narrower than it needed — '
            'that is what an ellipsis-truncated price looks like at the '
            'render-object level, even though the widget still carries the '
            'full string in `data`',
      );
    },
  );

  testWidgets('a short USD price is unaffected by the FittedBox change', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    await tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(
          body: Stack(
            children: [
              ListingDetailBottomBar(
                ad: testAd(price: 420, category: 'rent'),
                onSubmitApplication: () {},
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text(r'$420/month'), findsOneWidget);
  });
}
