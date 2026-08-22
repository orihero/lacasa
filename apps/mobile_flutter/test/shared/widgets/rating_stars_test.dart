// The load-bearing honesty rule: `average == null` must render "No reviews
// yet", never a zero-star row or a coerced 0.0 — see `rating_stars.dart`'s
// own doc comment and `AgentSummary.ratingAverage`'s.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';

import 'package:lacasa_mobile/shared/shared.dart';
import 'package:lacasa_mobile/theme/theme.dart';

void main() {
  Future<void> pump(WidgetTester tester, Widget child) {
    return tester.pumpWidget(
      MaterialApp(
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: AppTheme.light(),
        home: Scaffold(body: Center(child: child)),
      ),
    );
  }

  testWidgets('a null average renders "No reviews yet", not a zero-star row', (
    tester,
  ) async {
    await pump(tester, const RatingStars(average: null, count: 0));

    expect(find.text('No reviews yet'), findsOneWidget);
    expect(find.byIcon(Icons.star_rounded), findsNothing);
    expect(find.textContaining('Review:'), findsNothing);
  });

  testWidgets('a real average renders the exact "Review: n/5 (m)" string', (
    tester,
  ) async {
    await pump(tester, const RatingStars(average: 4.5, count: 2));

    expect(find.text('Review: 4.5/5'), findsOneWidget);
    expect(find.text('No reviews yet'), findsNothing);
  });

  testWidgets(
    'the icon row rounds to the nearest whole star, without rounding the printed number',
    (tester) async {
      await pump(tester, const RatingStars(average: 4.6, count: 3));

      // 4.6 rounds to 5 filled stars, but the text stays the exact 4.6 value.
      expect(find.text('Review: 4.6/5'), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNWidgets(5));
      expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    },
  );

  testWidgets('showLabel: false renders only the star icons, no text at all', (
    tester,
  ) async {
    await pump(
      tester,
      const RatingStars(average: 3, count: 0, showLabel: false),
    );

    expect(find.textContaining('Review:'), findsNothing);
    expect(find.text('No reviews yet'), findsNothing);
    expect(find.byIcon(Icons.star_rounded), findsNWidgets(3));
    expect(find.byIcon(Icons.star_outline_rounded), findsNWidgets(2));
  });
}
