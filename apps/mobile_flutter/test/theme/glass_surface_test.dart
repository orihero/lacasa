import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lacasa_mobile/theme/theme.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// Pumps [GlassSurface] under a given [ThemeData] so assertions can inspect
/// the [LiquidGlassLens] it builds.
Future<void> _pump(
  WidgetTester tester, {
  required ThemeData theme,
  required GlassVariant variant,
  required BorderRadius radius,
  double? distortionWidth,
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
            distortionWidth: distortionWidth,
            child: const Text('glass'),
          ),
        ),
      ),
    ),
  );
}

/// The single lens [GlassSurface] builds.
LiquidGlassLens _lens(WidgetTester tester) => tester.widget<LiquidGlassLens>(
  find.descendant(
    of: find.byType(GlassSurface),
    matching: find.byType(LiquidGlassLens),
  ),
);

void main() {
  group('GlassSurface', () {
    // Note: under `flutter test` the lens has no Impeller backdrop to
    // sample, so it falls back to the frosted path. These tests assert on
    // the *style* it is configured with, which is engine-independent —
    // how the refraction actually looks has to be checked on a device.
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

    testWidgets('maps the requested border radius onto the lens shape', (
      tester,
    ) async {
      await _pump(
        tester,
        theme: AppTheme.light(),
        variant: GlassVariant.onSurface,
        radius: BorderRadius.circular(AppRadii.cardLg),
      );
      expect(_lens(tester).style.shape!.cornerRadius, AppRadii.cardLg);
    });

    testWidgets('resolves an asymmetric radius to its largest corner', (
      tester,
    ) async {
      // AppRadii.hero is 40/40/26/26 and the lens takes one scalar; the
      // dominant read is the 40, not the 26.
      await _pump(
        tester,
        theme: AppTheme.light(),
        variant: GlassVariant.onSurface,
        radius: AppRadii.hero,
      );
      expect(_lens(tester).style.shape!.cornerRadius, 40);
    });

    testWidgets('uses the onSurface (.gl) material from GlassTheme', (
      tester,
    ) async {
      final theme = AppTheme.light();
      await _pump(
        tester,
        theme: theme,
        variant: GlassVariant.onSurface,
        radius: BorderRadius.circular(AppRadii.card),
      );

      final material = theme.extension<GlassTheme>()!.onSurface;
      final style = _lens(tester).style;

      expect(style.appearance.color, material.tint);
      expect(style.appearance.blur.sigmaX, material.blurSigma);
      expect(style.appearance.blur.sigmaY, material.blurSigma);
      // The CSS saturate() the old BackdropFilter implementation had to
      // drop — the lens applies it for real.
      expect(style.appearance.saturation, material.saturation);
      expect(style.refraction.distortion, material.distortion);
      expect(style.refraction.distortionWidth, material.distortionWidth);
      // .gl derives its rim optically rather than stating a border color.
      expect(style.shape!.borderType, isA<OpticalBorder>());
      expect(style.shape!.borderColor, isNull);
    });

    testWidgets('uses a different material for the onPhoto (.g) variant', (
      tester,
    ) async {
      final theme = AppTheme.light();
      await _pump(
        tester,
        theme: theme,
        variant: GlassVariant.onPhoto,
        radius: BorderRadius.circular(AppRadii.sm),
      );

      final glass = theme.extension<GlassTheme>()!;
      expect(glass.onPhoto.blurSigma, isNot(equals(glass.onSurface.blurSigma)));
      expect(
        glass.onPhoto.distortion,
        isNot(equals(glass.onSurface.distortion)),
      );

      final style = _lens(tester).style;
      expect(style.appearance.color, glass.onPhoto.tint);
      expect(style.appearance.blur.sigmaX, glass.onPhoto.blurSigma);
      expect(style.refraction.distortion, glass.onPhoto.distortion);
    });

    testWidgets('.g is non-themed — identical in light and dark', (
      tester,
    ) async {
      expect(GlassTheme.light.onPhoto.tint, GlassTheme.dark.onPhoto.tint);
      expect(
        GlassTheme.light.onPhoto.distortion,
        GlassTheme.dark.onPhoto.distortion,
      );
    });

    testWidgets(
      'flatForm (.glf) takes a stated hairline instead of an optical rim',
      (tester) async {
        final theme = AppTheme.light();
        await _pump(
          tester,
          theme: theme,
          variant: GlassVariant.flatForm,
          radius: BorderRadius.circular(AppRadii.control),
        );

        final style = _lens(tester).style;
        expect(style.shape!.borderType, isA<ClassicBorder>());
        // The source's `0 0 0 1px var(--line)` ring.
        expect(style.shape!.borderColor, theme.extension<LaCasaColors>()!.line);
        // An input is a place to read text, not a lens.
        expect(
          style.refraction.distortion,
          lessThan(GlassTheme.light.onSurface.distortion),
        );
      },
    );

    testWidgets('distortionWidth overrides the variant default', (
      tester,
    ) async {
      await _pump(
        tester,
        theme: AppTheme.light(),
        variant: GlassVariant.onSurface,
        radius: AppRadii.pill,
        distortionWidth: 7,
      );
      expect(_lens(tester).style.refraction.distortionWidth, 7);
    });

    testWidgets('onSurface tint switches between light and dark', (
      tester,
    ) async {
      await _pump(
        tester,
        theme: AppTheme.dark(),
        variant: GlassVariant.onSurface,
        radius: BorderRadius.circular(AppRadii.card),
      );

      expect(
        _lens(tester).style.appearance.color,
        GlassTheme.dark.onSurface.tint,
      );
      expect(
        GlassTheme.dark.onSurface.tint,
        isNot(equals(GlassTheme.light.onSurface.tint)),
      );
    });
  });
}
