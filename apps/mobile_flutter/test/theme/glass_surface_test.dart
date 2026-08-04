import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/theme/theme.dart';

/// Pumps [GlassSurface] under a given [ThemeData] and returns the widget
/// tree so assertions can inspect it.
Future<void> _pump(
  WidgetTester tester, {
  required ThemeData theme,
  required GlassVariant variant,
  required BorderRadius radius,
}) {
  return tester.pumpWidget(
    MaterialApp(
      theme: theme,
      home: Scaffold(
        body: Center(
          child: GlassSurface(
            variant: variant,
            borderRadius: radius,
            padding: const EdgeInsets.all(12),
            child: const Text('glass'),
          ),
        ),
      ),
    ),
  );
}

void main() {
  group('GlassSurface', () {
    testWidgets('builds in both light and dark theme without error', (
      tester,
    ) async {
      await _pump(
        tester,
        theme: AppTheme.light(),
        variant: GlassVariant.onSurface,
        radius: BorderRadius.circular(AppRadii.card),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('glass'), findsOneWidget);

      await _pump(
        tester,
        theme: AppTheme.dark(),
        variant: GlassVariant.onSurface,
        radius: BorderRadius.circular(AppRadii.card),
      );
      expect(tester.takeException(), isNull);
      expect(find.text('glass'), findsOneWidget);
    });

    testWidgets('applies the requested border radius to its ClipRRect', (
      tester,
    ) async {
      final radius = BorderRadius.circular(AppRadii.cardLg);
      await _pump(
        tester,
        theme: AppTheme.light(),
        variant: GlassVariant.onSurface,
        radius: radius,
      );

      final clip = tester.widget<ClipRRect>(
        find.descendant(
          of: find.byType(GlassSurface),
          matching: find.byType(ClipRRect),
        ),
      );
      expect(clip.borderRadius, radius);
    });

    testWidgets(
      'uses the onSurface (.gl) blur sigma and tint from GlassTheme',
      (tester) async {
        final theme = AppTheme.light();
        await _pump(
          tester,
          theme: theme,
          variant: GlassVariant.onSurface,
          radius: BorderRadius.circular(AppRadii.card),
        );

        final glass = theme.extension<GlassTheme>()!;

        final backdrop = tester.widget<BackdropFilter>(
          find.descendant(
            of: find.byType(GlassSurface),
            matching: find.byType(BackdropFilter),
          ),
        );
        // ImageFilter has no public sigma getter; its toString() is the
        // documented, stable way to assert on the blur amount it was built
        // with (e.g. "ImageFilter.blur(11.0, 11.0, ...)").
        expect(
          backdrop.filter.toString(),
          contains(glass.glBlurSigma.toString()),
        );

        final tint = tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(BackdropFilter),
            matching: find.byType(ColoredBox),
          ),
        );
        expect(tint.color, glass.glBackground);

        // The rim is painted for .gl — exactly one CustomPaint inside this
        // GlassSurface.
        expect(
          find.descendant(
            of: find.byType(GlassSurface),
            matching: find.byType(CustomPaint),
          ),
          findsOneWidget,
        );
      },
    );

    testWidgets(
      'uses a different blur sigma and tint for the onPhoto (.g) variant',
      (tester) async {
        final theme = AppTheme.light();
        await _pump(
          tester,
          theme: theme,
          variant: GlassVariant.onPhoto,
          radius: BorderRadius.circular(AppRadii.sm),
        );

        final glass = theme.extension<GlassTheme>()!;
        expect(glass.gBlurSigma, isNot(equals(glass.glBlurSigma)));

        final backdrop = tester.widget<BackdropFilter>(
          find.descendant(
            of: find.byType(GlassSurface),
            matching: find.byType(BackdropFilter),
          ),
        );
        expect(
          backdrop.filter.toString(),
          contains(glass.gBlurSigma.toString()),
        );

        final tint = tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(BackdropFilter),
            matching: find.byType(ColoredBox),
          ),
        );
        // .g is fixed/non-themed: same tint regardless of light vs dark.
        expect(tint.color, glass.gBackground);
      },
    );

    testWidgets('flatForm (.glf) variant skips the rim/sheen layers', (
      tester,
    ) async {
      await _pump(
        tester,
        theme: AppTheme.light(),
        variant: GlassVariant.flatForm,
        radius: BorderRadius.circular(AppRadii.control),
      );

      // No gradient-stroke rim painter for .glf.
      expect(
        find.descendant(
          of: find.byType(GlassSurface),
          matching: find.byType(CustomPaint),
        ),
        findsNothing,
      );
    });

    testWidgets(
      'onSurface tint switches between GlassTheme.light and GlassTheme.dark',
      (tester) async {
        await _pump(
          tester,
          theme: AppTheme.dark(),
          variant: GlassVariant.onSurface,
          radius: BorderRadius.circular(AppRadii.card),
        );

        final tint = tester.widget<ColoredBox>(
          find.descendant(
            of: find.byType(BackdropFilter),
            matching: find.byType(ColoredBox),
          ),
        );
        expect(tint.color, GlassTheme.dark.glBackground);
        expect(tint.color, isNot(equals(GlassTheme.light.glBackground)));
      },
    );
  });
}
