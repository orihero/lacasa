import 'package:flutter/material.dart';

/// Themed semantic colors for Direction E "Liquid Glass" (design-token
/// spec §1).
///
/// Registered as a [ThemeExtension] (not folded into [ColorScheme]) because
/// the prototype's roles — `ink`/`ink-2`/`muted`/`faint`/`sunk`/`pill` — do
/// not map cleanly onto Material's primary/secondary/surface vocabulary.
/// Reach it with `Theme.of(context).extension<LaCasaColors>()!`.
@immutable
class LaCasaColors extends ThemeExtension<LaCasaColors> {
  const LaCasaColors({
    required this.ink,
    required this.ink2,
    required this.muted,
    required this.faint,
    required this.screen,
    required this.card,
    required this.sunk,
    required this.line,
    required this.pill,
    required this.pillInk,
  });

  /// Primary text / icon color.
  final Color ink;

  /// Secondary text color.
  final Color ink2;

  /// Tertiary text color — labels, captions.
  final Color muted;

  /// Quaternary color — placeholders, disabled state.
  final Color faint;

  /// App background.
  final Color screen;

  /// Card / raised-surface background.
  final Color card;

  /// Inset-fill background — thumbnail placeholders, stat tiles, map bg.
  final Color sunk;

  /// Hairline border color, already carries its own alpha.
  final Color line;

  /// Fill color of a selected/"on" pill (chip.on, tab.on, seg.on…).
  final Color pill;

  /// Text/icon color painted on top of [pill].
  final Color pillInk;

  static const light = LaCasaColors(
    ink: Color(0xFF15151B),
    ink2: Color(0xFF3C3C47),
    muted: Color(0xFF82828F),
    faint: Color(0xFFA2A2AE),
    screen: Color(0xFFF6F6F8),
    card: Color(0xFFFFFFFF),
    sunk: Color(0xFFF1F1F5),
    line: Color(0x14181626), // rgba(24,22,38,.08)
    pill: Color(0xFF15151B),
    pillInk: Color(0xFFFFFFFF),
  );

  static const dark = LaCasaColors(
    ink: Color(0xFFF1F1F6),
    ink2: Color(0xFFC5C5D2),
    muted: Color(0xFF8D8D9E),
    faint: Color(0xFF6D6D7E),
    screen: Color(0xFF0D0D13),
    card: Color(0xFF181820),
    sunk: Color(0xFF13131A),
    line: Color(0x14FFFFFF), // rgba(255,255,255,.08)
    pill: Color(0xFFF1F1F6),
    pillInk: Color(0xFF14141A),
  );

  @override
  LaCasaColors copyWith({
    Color? ink,
    Color? ink2,
    Color? muted,
    Color? faint,
    Color? screen,
    Color? card,
    Color? sunk,
    Color? line,
    Color? pill,
    Color? pillInk,
  }) {
    return LaCasaColors(
      ink: ink ?? this.ink,
      ink2: ink2 ?? this.ink2,
      muted: muted ?? this.muted,
      faint: faint ?? this.faint,
      screen: screen ?? this.screen,
      card: card ?? this.card,
      sunk: sunk ?? this.sunk,
      line: line ?? this.line,
      pill: pill ?? this.pill,
      pillInk: pillInk ?? this.pillInk,
    );
  }

  @override
  LaCasaColors lerp(ThemeExtension<LaCasaColors>? other, double t) {
    if (other is! LaCasaColors) return this;
    return LaCasaColors(
      ink: Color.lerp(ink, other.ink, t)!,
      ink2: Color.lerp(ink2, other.ink2, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      faint: Color.lerp(faint, other.faint, t)!,
      screen: Color.lerp(screen, other.screen, t)!,
      card: Color.lerp(card, other.card, t)!,
      sunk: Color.lerp(sunk, other.sunk, t)!,
      line: Color.lerp(line, other.line, t)!,
      pill: Color.lerp(pill, other.pill, t)!,
      pillInk: Color.lerp(pillInk, other.pillInk, t)!,
    );
  }
}

/// The magenta accent, deliberately **not** themed: the source CSS does
/// not redefine `--accent`, `--accent-grad`, or `--accent-shadow` under
/// `:root[data-theme=dark]`, so it is identical in light and dark. Carried
/// here as flat top-level constants rather than a [ThemeExtension] pair,
/// per the token spec's explicit instruction.
abstract final class AppAccent {
  /// `--accent: #F5439B`
  static const Color color = Color(0xFFF5439B);

  /// `--accent-grad: linear-gradient(158deg, #FF77B8 0%, #F5439B 46%,
  /// #E5227F 100%)`.
  ///
  /// CSS gradient angle → Flutter [Alignment] conversion used throughout
  /// this theme: for CSS angle θ (0deg = up, increasing clockwise),
  /// `dx = sin(θ), dy = -cos(θ)`, `begin = Alignment(-dx, -dy)`,
  /// `end = Alignment(dx, dy)`. For 158°: dx≈0.3746, dy≈0.9272.
  static const Gradient gradient = LinearGradient(
    begin: Alignment(-0.3746, -0.9272),
    end: Alignment(0.3746, 0.9272),
    colors: [Color(0xFFFF77B8), Color(0xFFF5439B), Color(0xFFE5227F)],
    stops: [0.0, 0.46, 1.0],
  );

  /// `--accent-shadow: 0 10px 22px -8px rgba(229,34,127,.6)` — see
  /// [AppShadows.accentGlow] for the [BoxShadow] form and a note on the
  /// inset highlights CSS pairs it with.
  static const Color shadowColor = Color.fromRGBO(229, 34, 127, 0.6);
}

/// Status colors (design-token spec §1, "Status colors" table).
///
/// These are hardcoded in the source CSS, not CSS custom properties, and
/// are **not themed** — identical text/background pairs in light and dark.
/// Kept as flat constants here rather than derived from
/// `Theme.of(context).brightness`, matching the prototype's own choice.
abstract final class AppStatusColors {
  static const Color successText = Color(0xFF0F9E6E);
  static const Color successBg = Color.fromRGBO(15, 158, 110, 0.13);

  static const Color warningText = Color(0xFFC8811A);
  static const Color warningBg = Color.fromRGBO(200, 129, 26, 0.14);

  static const Color errorText = Color(0xFFE0355F);
  static const Color errorBg = Color.fromRGBO(224, 53, 95, 0.13);

  /// Danger button border variant.
  static const Color dangerBorder = Color.fromRGBO(224, 53, 95, 0.4);

  /// Danger icon-chip background.
  static const Color dangerIconBg = Color.fromRGBO(224, 53, 95, 0.12);

  static const Color infoText = Color(0xFF3B73D8);
  static const Color infoBg = Color.fromRGBO(59, 115, 216, 0.14);

  /// Accent-flavored status chip background; pair with [AppAccent.color]
  /// as the text/icon color.
  static const Color accentStatusBg = Color.fromRGBO(245, 67, 155, 0.13);

  /// Muted status chip. Unlike every other row in this table, the source
  /// defines its background as `var(--sunk)`, which DOES vary by theme —
  /// so, unlike its siblings, this is not a flat constant. Pair
  /// `LaCasaColors.muted` (text) with `LaCasaColors.sunk` (background)
  /// from the active theme instead of reading a color from here.
  static const String mutedStatusNote =
      'text: LaCasaColors.muted, background: LaCasaColors.sunk (themed, not flat)';

  /// Rating star — icon-only, no background chip.
  static const Color ratingStar = Color(0xFFE8A92C);
}
