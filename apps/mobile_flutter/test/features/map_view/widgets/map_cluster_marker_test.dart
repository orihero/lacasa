// Unit/widget tests for the cluster badge itself, isolated from the map —
// `map_view_screen_test.dart` covers it in place but only ever produces
// small counts, so the digit-growth and 99+ cap need their own coverage.

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/features/map_view/widgets/map_cluster_marker.dart';
import 'package:lacasa_mobile/l10n/generated/app_localizations.dart';
import 'package:lacasa_mobile/theme/theme.dart';

void main() {
  group('MapClusterMetrics.sizeFor', () {
    test('grows with digit count rather than staying one fixed size', () {
      expect(
        MapClusterMetrics.sizeFor(1),
        lessThan(MapClusterMetrics.sizeFor(10)),
      );
      expect(
        MapClusterMetrics.sizeFor(10),
        lessThan(MapClusterMetrics.sizeFor(100)),
      );
    });

    test('single- and double-digit counts share a size band', () {
      expect(MapClusterMetrics.sizeFor(2), MapClusterMetrics.sizeFor(9));
      expect(MapClusterMetrics.sizeFor(10), MapClusterMetrics.sizeFor(42));
    });
  });

  group('MapClusterMarker', () {
    Future<void> pumpMarker(WidgetTester tester, int count) async {
      await tester.pumpWidget(
        MaterialApp(
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          theme: AppTheme.light(),
          home: Scaffold(
            body: Center(child: MapClusterMarker(count: count)),
          ),
        ),
      );
    }

    testWidgets('shows the literal count for realistic cluster sizes', (
      tester,
    ) async {
      await pumpMarker(tester, 7);
      expect(find.text('7'), findsOneWidget);
    });

    testWidgets('caps the label at 99+ rather than overflowing the badge', (
      tester,
    ) async {
      await pumpMarker(tester, 250);
      expect(find.text('99+'), findsOneWidget);
      expect(find.text('250'), findsNothing);
    });

    testWidgets('carries a semantic label naming the count and the action', (
      tester,
    ) async {
      await pumpMarker(tester, 4);
      expect(
        find.bySemanticsLabel(RegExp('4 listings here, tap to zoom in')),
        findsOneWidget,
      );
    });
  });
}
