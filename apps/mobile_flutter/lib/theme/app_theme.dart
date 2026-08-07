import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';
import 'app_typography.dart';
import 'glass_theme_extension.dart';

/// Builds the app's [ThemeData] for Direction E "Liquid Glass".
///
/// Contract: **system-driven default, user-overridable** — the prototype
/// picks its initial theme from `matchMedia('(prefers-color-scheme:
/// dark)')` and lets a button toggle it after (design-token spec §1).
/// That's exactly [ThemeMode.system] plus a manual override in Flutter:
/// wire `MaterialApp(theme: AppTheme.light(), darkTheme: AppTheme.dark(),
/// themeMode: ...)` (system by default, overridden by app state) — this file
/// only builds the two [ThemeData] instances, the mode itself belongs to
/// the app shell (`lib/app.dart`), not the theme package.
abstract final class AppTheme {
  static ThemeData light() => _build(Brightness.light);
  static ThemeData dark() => _build(Brightness.dark);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final colors = isDark ? LaCasaColors.dark : LaCasaColors.light;
    final glass = isDark ? GlassTheme.dark : GlassTheme.light;
    final typography = LaCasaTypography.standard;

    final colorScheme = ColorScheme(
      brightness: brightness,
      // `--pill`/`--pill-ink` are the closest Material analogue to
      // primary/onPrimary: the fill+text pair used for the app's
      // "selected/on" affordance (chip.on, tab.on, seg.on…).
      primary: colors.pill,
      onPrimary: colors.pillInk,
      secondary: AppAccent.color,
      onSecondary: Colors.white,
      error: AppStatusColors.errorText,
      onError: Colors.white,
      surface: colors.card,
      onSurface: colors.ink,
      surfaceContainerHighest: colors.sunk,
      outline: colors.line,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      scaffoldBackgroundColor: colors.screen,
      canvasColor: colors.screen,
      cardColor: colors.card,
      dividerColor: colors.line,
      colorScheme: colorScheme,
      fontFamily: GoogleFonts.poppins().fontFamily,
      textTheme: _textTheme(colors, typography),
      splashFactory: NoSplash.splashFactory,
      highlightColor: Colors.transparent,
      extensions: <ThemeExtension<dynamic>>[colors, glass, typography],
    );
  }

  /// A best-effort mapping of the prototype's ~20 semantic roles onto
  /// Flutter's 13-slot [TextTheme]. This is necessarily lossy — several
  /// distinct source roles collapse onto one Material slot — so treat it
  /// as the default for plain, undecorated [Text] widgets only. Anywhere
  /// fidelity to a *specific* named role matters (e.g. "this must be
  /// exactly `.lrow__t`, not just some `bodyMedium`"), read the exact
  /// style from `Theme.of(context).extension<LaCasaTypography>()!`
  /// instead.
  static TextTheme _textTheme(LaCasaColors colors, LaCasaTypography t) {
    TextStyle withInk(TextStyle s) => s.copyWith(color: colors.ink);
    TextStyle withMuted(TextStyle s) => s.copyWith(color: colors.muted);

    return TextTheme(
      displayLarge: withInk(t.display),
      displayMedium: withInk(t.displayLead),
      displaySmall: withInk(t.numericDisplay),
      headlineLarge: withInk(t.heroTitle),
      headlineMedium: withInk(t.navTitle),
      headlineSmall: withInk(t.sheetTitle),
      titleLarge: withInk(t.sectionHeading),
      titleMedium: withInk(t.panelHeading),
      titleSmall: withInk(t.identityName),
      bodyLarge: withInk(t.body),
      bodyMedium: withInk(t.bodySmall),
      bodySmall: withInk(t.micro),
      labelLarge: withInk(t.rowTitle),
      labelMedium: withMuted(t.label),
      labelSmall: withMuted(t.caption),
    );
  }
}
