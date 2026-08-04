import 'package:flutter/material.dart';

/// Themed parameters for the glass primitive (design-token spec §1 "glass
/// tint" group + §6 "the glass primitive"), registered as a
/// [ThemeExtension] because none of `backdrop-filter`, gradient rims, or
/// layered box-shadows have a slot in Flutter's [ColorScheme]/[ThemeData].
/// Reach it with `Theme.of(context).extension<GlassTheme>()!`; consumed
/// directly by [GlassSurface] (see `glass_surface.dart`) so app code should
/// rarely need to read this by hand.
///
/// Three material variants, matching the CSS `.g` / `.gl` / `.glf` split:
/// - `gl*` — glass over the **app surface** (`--gl-*` custom properties):
///   themed, differs between light and dark.
/// - `g*` — glass over **photography**: fixed, flat values, identical in
///   both themes (the source CSS never reads a custom property for `.g`).
/// - `glf*` — "flat glass", the same material as `.gl` rebuilt without
///   pseudo-elements for void elements (`<input>`, `<textarea>`) that
///   can't render `::before`/`::after`. No rim/sheen layer; approximated
///   instead with a top highlight line — see [glfTopHighlight].
@immutable
class GlassTheme extends ThemeExtension<GlassTheme> {
  const GlassTheme({
    required this.glBackground,
    required this.glRim,
    required this.glSheen,
    required this.glShadow,
    required this.glBlurSigma,
    required this.gBackground,
    required this.gRim,
    required this.gSheen,
    required this.gShadow,
    required this.gBlurSigma,
    required this.glfBackground,
    required this.glfShadow,
    required this.glfBlurSigma,
    required this.glfTopHighlight,
  });

  // ---- .gl — glass over the app surface (themed) --------------------------

  /// `--gl-bg`.
  final Color glBackground;

  /// `--gl-rim`, the 1px gradient-stroke rim. See [GlassSurface]'s doc
  /// comment for how this is painted without CSS's mask-composite trick.
  final Gradient glRim;

  /// `--gl-sheen`, the soft upper-left specular highlight.
  final Gradient glSheen;

  /// `--gl-shadow`.
  final List<BoxShadow> glShadow;

  /// Starting `ImageFilter.blur` sigma for `backdrop-filter: blur(22px)
  /// saturate(185%)`. Flutter has no `saturate()` equivalent on
  /// [BackdropFilter] — see [GlassSurface]'s doc comment.
  final double glBlurSigma;

  // ---- .g — glass over photography (fixed, non-themed) ---------------------

  final Color gBackground;
  final Gradient gRim;
  final Gradient gSheen;
  final List<BoxShadow> gShadow;

  /// For `backdrop-filter: blur(15px) saturate(200%) brightness(1.1)`.
  final double gBlurSigma;

  // ---- .glf — flat glass (form controls, themed) ---------------------------

  /// Same value as [glBackground] (`.glf` reads `var(--gl-bg)` too).
  final Color glfBackground;

  /// Only the outer drop-shadow component survives as a real [BoxShadow]
  /// list — empty in dark mode, where the source has no outer shadow at
  /// all (`inset 0 1px 0 rgba(255,255,255,.14), 0 0 0 1px var(--line)`
  /// only). The inset highlight and hairline ring are painted separately
  /// by [GlassSurface], not folded in here.
  final List<BoxShadow> glfShadow;

  /// For `backdrop-filter: blur(20px) saturate(180%)`.
  final double glfBlurSigma;

  /// Approximates CSS `inset 0 1px 0 rgba(255,255,255, .8|.14)` — Flutter
  /// [BoxShadow] has no inset flag, so [GlassSurface] paints this as a 1px
  /// solid line pinned to the control's top inner edge instead.
  final Color glfTopHighlight;

  static final light = GlassTheme(
    glBackground: const Color(0x9EFFFFFF), // rgba(255,255,255,.62)
    glRim: const LinearGradient(
      // 148deg — see AppAccent.gradient doc comment for the angle formula.
      begin: Alignment(-0.5299, -0.8480),
      end: Alignment(0.5299, 0.8480),
      colors: [
        Color(0xFAFFFFFF), // rgba(255,255,255,.98)
        Color(0x73FFFFFF), // rgba(255,255,255,.45)
        Color(0x6BC5C5D4), // rgba(197,197,212,.42)
        Color(0xEBFFFFFF), // rgba(255,255,255,.92)
      ],
      stops: [0.0, 0.34, 0.62, 1.0],
    ),
    glSheen: const RadialGradient(
      // CSS: radial-gradient(135% 95% at 26% -14%, ...). Flutter's
      // RadialGradient has one scalar radius, not independent x/y radii —
      // approximated here as a circle; see GlassSurface doc comment.
      center: Alignment(-0.48, -1.28),
      radius: 1.3,
      colors: [
        Color(0xD9FFFFFF), // rgba(255,255,255,.85)
        Color(0x00FFFFFF),
      ],
      stops: [0.0, 0.6],
    ),
    glShadow: const [
      BoxShadow(
        color: Color.fromRGBO(32, 28, 46, 0.3),
        offset: Offset(0, 8),
        blurRadius: 20,
        spreadRadius: -6,
      ),
      BoxShadow(
        color: Color.fromRGBO(32, 28, 46, 0.05),
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
    ],
    glBlurSigma: 11,
    gBackground: const Color(0x26FFFFFF), // rgba(255,255,255,.15)
    gRim: const LinearGradient(
      begin: Alignment(-0.5299, -0.8480),
      end: Alignment(0.5299, 0.8480),
      colors: [
        Color(0xE6FFFFFF), // rgba(255,255,255,.9)
        Color(0x38FFFFFF), // rgba(255,255,255,.22)
        Color(0x0FFFFFFF), // rgba(255,255,255,.06)
        Color(0x8CFFFFFF), // rgba(255,255,255,.55)
      ],
      stops: [0.0, 0.30, 0.56, 1.0],
    ),
    gSheen: const RadialGradient(
      center: Alignment(-0.52, -1.32),
      radius: 1.3,
      colors: [
        Color(0x73FFFFFF), // rgba(255,255,255,.45)
        Color(0x00FFFFFF),
      ],
      stops: [0.0, 0.58],
    ),
    gShadow: const [
      BoxShadow(
        color: Color.fromRGBO(10, 10, 20, 0.5),
        offset: Offset(0, 8),
        blurRadius: 22,
        spreadRadius: -5,
      ),
    ],
    gBlurSigma: 7.5,
    glfBackground: const Color(0x9EFFFFFF),
    glfShadow: const [
      BoxShadow(
        color: Color.fromRGBO(32, 28, 46, 0.55),
        offset: Offset(0, 6),
        blurRadius: 16,
        spreadRadius: -7,
      ),
    ],
    glfBlurSigma: 10,
    glfTopHighlight: const Color(0xCCFFFFFF), // rgba(255,255,255,.8)
  );

  static final dark = GlassTheme(
    glBackground: const Color(0x75404052), // rgba(64,64,82,.46)
    glRim: const LinearGradient(
      begin: Alignment(-0.5299, -0.8480),
      end: Alignment(0.5299, 0.8480),
      colors: [
        Color(0x66FFFFFF), // rgba(255,255,255,.4)
        Color(0x1AFFFFFF), // rgba(255,255,255,.1)
        Color(0x08FFFFFF), // rgba(255,255,255,.03)
        Color(0x42FFFFFF), // rgba(255,255,255,.26)
      ],
      stops: [0.0, 0.34, 0.62, 1.0],
    ),
    glSheen: const RadialGradient(
      center: Alignment(-0.48, -1.28),
      radius: 1.3,
      colors: [
        Color(0x2EFFFFFF), // rgba(255,255,255,.18)
        Color(0x00FFFFFF),
      ],
      stops: [0.0, 0.6],
    ),
    glShadow: const [
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.8),
        offset: Offset(0, 10),
        blurRadius: 24,
        spreadRadius: -7,
      ),
      BoxShadow(
        color: Color.fromRGBO(0, 0, 0, 0.3),
        offset: Offset(0, 1),
        blurRadius: 2,
      ),
    ],
    glBlurSigma: 11,
    // `.g` is fixed/non-themed — identical values to GlassTheme.light.
    gBackground: const Color(0x26FFFFFF),
    gRim: const LinearGradient(
      begin: Alignment(-0.5299, -0.8480),
      end: Alignment(0.5299, 0.8480),
      colors: [
        Color(0xE6FFFFFF),
        Color(0x38FFFFFF),
        Color(0x0FFFFFFF),
        Color(0x8CFFFFFF),
      ],
      stops: [0.0, 0.30, 0.56, 1.0],
    ),
    gSheen: const RadialGradient(
      center: Alignment(-0.52, -1.32),
      radius: 1.3,
      colors: [Color(0x73FFFFFF), Color(0x00FFFFFF)],
      stops: [0.0, 0.58],
    ),
    gShadow: const [
      BoxShadow(
        color: Color.fromRGBO(10, 10, 20, 0.5),
        offset: Offset(0, 8),
        blurRadius: 22,
        spreadRadius: -5,
      ),
    ],
    gBlurSigma: 7.5,
    glfBackground: const Color(0x75404052),
    glfShadow: const [], // no outer drop shadow in dark mode
    glfBlurSigma: 10,
    glfTopHighlight: const Color(0x24FFFFFF), // rgba(255,255,255,.14)
  );

  @override
  GlassTheme copyWith({
    Color? glBackground,
    Gradient? glRim,
    Gradient? glSheen,
    List<BoxShadow>? glShadow,
    double? glBlurSigma,
    Color? gBackground,
    Gradient? gRim,
    Gradient? gSheen,
    List<BoxShadow>? gShadow,
    double? gBlurSigma,
    Color? glfBackground,
    List<BoxShadow>? glfShadow,
    double? glfBlurSigma,
    Color? glfTopHighlight,
  }) {
    return GlassTheme(
      glBackground: glBackground ?? this.glBackground,
      glRim: glRim ?? this.glRim,
      glSheen: glSheen ?? this.glSheen,
      glShadow: glShadow ?? this.glShadow,
      glBlurSigma: glBlurSigma ?? this.glBlurSigma,
      gBackground: gBackground ?? this.gBackground,
      gRim: gRim ?? this.gRim,
      gSheen: gSheen ?? this.gSheen,
      gShadow: gShadow ?? this.gShadow,
      gBlurSigma: gBlurSigma ?? this.gBlurSigma,
      glfBackground: glfBackground ?? this.glfBackground,
      glfShadow: glfShadow ?? this.glfShadow,
      glfBlurSigma: glfBlurSigma ?? this.glfBlurSigma,
      glfTopHighlight: glfTopHighlight ?? this.glfTopHighlight,
    );
  }

  @override
  GlassTheme lerp(ThemeExtension<GlassTheme>? other, double t) {
    if (other is! GlassTheme) return this;
    return GlassTheme(
      glBackground: Color.lerp(glBackground, other.glBackground, t)!,
      glRim: Gradient.lerp(glRim, other.glRim, t)!,
      glSheen: Gradient.lerp(glSheen, other.glSheen, t)!,
      glShadow: BoxShadow.lerpList(glShadow, other.glShadow, t)!,
      glBlurSigma: lerpDouble(glBlurSigma, other.glBlurSigma, t),
      gBackground: Color.lerp(gBackground, other.gBackground, t)!,
      gRim: Gradient.lerp(gRim, other.gRim, t)!,
      gSheen: Gradient.lerp(gSheen, other.gSheen, t)!,
      gShadow: BoxShadow.lerpList(gShadow, other.gShadow, t)!,
      gBlurSigma: lerpDouble(gBlurSigma, other.gBlurSigma, t),
      glfBackground: Color.lerp(glfBackground, other.glfBackground, t)!,
      glfShadow: BoxShadow.lerpList(glfShadow, other.glfShadow, t)!,
      glfBlurSigma: lerpDouble(glfBlurSigma, other.glfBlurSigma, t),
      glfTopHighlight: Color.lerp(glfTopHighlight, other.glfTopHighlight, t)!,
    );
  }

  static double lerpDouble(double a, double b, double t) => a + (b - a) * t;
}
