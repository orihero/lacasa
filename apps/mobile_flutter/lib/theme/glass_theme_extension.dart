import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

/// The per-variant parameters of one glass material, expressed in the
/// vocabulary `liquid_glass_easy` actually renders with: a tint, a blur, a
/// saturation, a [LiquidGlassRefraction] and a rim [LiquidGlassBorderType],
/// plus the one thing the shader does *not* draw — the outer drop
/// [shadow], which stays a Flutter [BoxShadow] list painted behind the lens.
///
/// This replaces the earlier hand-built "rim gradient + radial sheen"
/// description of the material. Those two were a CSS transcription of what
/// glass *looks* like; the lens derives the rim and the specular highlight
/// from the shape and the live backdrop instead, so they have no equivalent
/// field here — see [GlassTheme] for what each variant maps to.
@immutable
class GlassMaterial {
  const GlassMaterial({
    required this.tint,
    required this.blurSigma,
    required this.saturation,
    required this.distortion,
    required this.distortionWidth,
    required this.magnification,
    required this.chromaticAberration,
    required this.cornerStyle,
    required this.borderWidth,
    required this.borderColor,
    required this.lightColor,
    required this.lightIntensity,
    required this.borderType,
    required this.shadow,
  });

  /// `LiquidGlassAppearance.color` — the lens's base tint.
  ///
  /// Deliberately **weaker** than the CSS `--gl-bg`/`--g-bg` these values
  /// descend from: the old surface was a frosted panel where the tint did
  /// all the work of reading as glass, so it could afford to be near
  /// opaque. Here the refraction band and the optical rim carry that read,
  /// and a tint that heavy would simply hide them.
  final Color tint;

  /// `LiquidGlassAppearance.blur` sigma (used for both axes).
  final double blurSigma;

  /// `LiquidGlassAppearance.saturation` — the CSS `saturate()` the previous
  /// [BackdropFilter] implementation had to drop, since `dart:ui`'s
  /// `ImageFilter` has no saturation filter. The lens shader does, so the
  /// source's `saturate(185%)` / `saturate(200%)` survive as `1.85` / `2.0`.
  final double saturation;

  /// `LiquidGlassRefraction.distortion` — how hard the perimeter band bends
  /// what is behind the glass (`0.0`–`1.0`).
  final double distortion;

  /// `LiquidGlassRefraction.distortionWidth` — thickness of that band, in
  /// logical pixels, and the one value here that is genuinely size-dependent:
  /// the band is an absolute width, so one tuned for a card swallows a chip
  /// whole and the glass goes from refracting to merely smeared.
  ///
  /// The defaults are therefore tuned **small-first**, for the chips, pills
  /// and icon buttons that make up most of this app's glass — the handful of
  /// large panels (the pitch banner, the tab bar) widen it back out via
  /// `GlassSurface.distortionWidth`, which is the cheaper direction to have
  /// to override.
  final double distortionWidth;

  /// `LiquidGlassRefraction.magnification` (`1.0` = none).
  final double magnification;

  /// `LiquidGlassRefraction.chromaticAberration` (`0.0` disables it).
  final double chromaticAberration;

  /// `LiquidGlassShape.cornerStyle`. [LiquidGlassCornerStyle.roundedRectangle]
  /// (plain circular corners) is the cheapest SDF the shader can draw;
  /// [LiquidGlassCornerStyle.continuousRoundedRectangle] is the prettier
  /// Apple-capsule profile, and the default here.
  ///
  /// Exposed because it looked like a performance knob. **It is not** — see
  /// [GlassTheme]'s note: turning it (and the blur, the magnification and
  /// the chromatic aberration) all the way down moved a 46.6ms frame to
  /// 46.5ms. Treat it as a taste setting.
  final LiquidGlassCornerStyle cornerStyle;

  /// `LiquidGlassShape.borderWidth`.
  final double borderWidth;

  /// `LiquidGlassShape.borderColor`. `null` lets the border mode derive its
  /// own color — which is the point of [OpticalBorder], so only the flat
  /// form variant sets it (and even there [GlassSurface] substitutes the
  /// theme's hairline `line` color when this is null).
  final Color? borderColor;

  /// `LiquidGlassShape.lightColor` / `lightIntensity` — the highlight the
  /// rim is lit with.
  final Color lightColor;
  final double lightIntensity;

  /// `LiquidGlassShape.borderType`: [OpticalBorder] for the two real glass
  /// variants (a background-tinted, SDF-derived rim), [ClassicBorder] for
  /// the flat form variant, which wants a crisp hairline rather than an
  /// optical one.
  final LiquidGlassBorderType borderType;

  /// The outer drop shadow, painted *behind* the lens by [GlassSurface] —
  /// not part of the shader, and deliberately outside the lens's clip so
  /// it is neither blurred with the backdrop nor cut off at the corners.
  final List<BoxShadow> shadow;

  GlassMaterial copyWith({
    Color? tint,
    double? blurSigma,
    double? saturation,
    double? distortion,
    double? distortionWidth,
    double? magnification,
    double? chromaticAberration,
    LiquidGlassCornerStyle? cornerStyle,
    double? borderWidth,
    Color? borderColor,
    Color? lightColor,
    double? lightIntensity,
    LiquidGlassBorderType? borderType,
    List<BoxShadow>? shadow,
  }) {
    return GlassMaterial(
      tint: tint ?? this.tint,
      blurSigma: blurSigma ?? this.blurSigma,
      saturation: saturation ?? this.saturation,
      distortion: distortion ?? this.distortion,
      distortionWidth: distortionWidth ?? this.distortionWidth,
      magnification: magnification ?? this.magnification,
      chromaticAberration: chromaticAberration ?? this.chromaticAberration,
      cornerStyle: cornerStyle ?? this.cornerStyle,
      borderWidth: borderWidth ?? this.borderWidth,
      borderColor: borderColor ?? this.borderColor,
      lightColor: lightColor ?? this.lightColor,
      lightIntensity: lightIntensity ?? this.lightIntensity,
      borderType: borderType ?? this.borderType,
      shadow: shadow ?? this.shadow,
    );
  }

  /// Interpolates every scalar and color; [borderType] snaps at the
  /// halfway point, because [ClassicBorder] and [OpticalBorder] are
  /// different shader paths rather than two ends of one scale.
  static GlassMaterial lerp(GlassMaterial a, GlassMaterial b, double t) {
    double d(double x, double y) => x + (y - x) * t;
    return GlassMaterial(
      tint: Color.lerp(a.tint, b.tint, t)!,
      blurSigma: d(a.blurSigma, b.blurSigma),
      saturation: d(a.saturation, b.saturation),
      distortion: d(a.distortion, b.distortion),
      distortionWidth: d(a.distortionWidth, b.distortionWidth),
      magnification: d(a.magnification, b.magnification),
      chromaticAberration: d(a.chromaticAberration, b.chromaticAberration),
      cornerStyle: t < 0.5 ? a.cornerStyle : b.cornerStyle,
      borderWidth: d(a.borderWidth, b.borderWidth),
      borderColor: Color.lerp(a.borderColor, b.borderColor, t),
      lightColor: Color.lerp(a.lightColor, b.lightColor, t)!,
      lightIntensity: d(a.lightIntensity, b.lightIntensity),
      borderType: t < 0.5 ? a.borderType : b.borderType,
      shadow: BoxShadow.lerpList(a.shadow, b.shadow, t)!,
    );
  }
}

/// Themed parameters for the glass primitive (design-token spec §1 "glass
/// tint" group + §6 "the glass primitive"), registered as a
/// [ThemeExtension] because none of refraction, rim lighting, or layered
/// drop shadows have a slot in Flutter's [ColorScheme]/[ThemeData].
/// Reach it with `Theme.of(context).extension<GlassTheme>()!`; consumed
/// directly by `GlassSurface` (see `glass_surface.dart`) so app code should
/// rarely need to read this by hand.
///
/// Three material variants, matching the CSS `.g` / `.gl` / `.glf` split:
/// - [onSurface] — `.gl`, glass over the **app surface** (`--gl-*` custom
///   properties): themed, differs between light and dark.
/// - [onPhoto] — `.g`, glass over **photography**: fixed, identical in both
///   themes (the source CSS never reads a custom property for `.g`).
/// - [flatForm] — `.glf`, "flat glass" for form controls: the same tint,
///   but with the refraction pulled almost to nothing and a crisp hairline
///   border, so a text field reads as an input rather than as a lens
///   distorting its own label.
///
/// ## None of these values are performance knobs
/// Measured on-device (Android, Impeller, profile build, 14s scroll of the
/// home feed), median frame time:
///
/// | glass | frame p50 | over the 16.7ms budget |
/// |---|---|---|
/// | no backdrop read at all | 5.7ms | 0.5% |
/// | the old `BackdropFilter` surface | 26.8ms | 87% |
/// | this lens | 46.6ms | 99.7% |
/// | this lens, every cost knob at minimum | 46.5ms | 100% |
///
/// That last row is the point. Dropping the blur to 6, the chromatic
/// aberration and magnification to zero and the corners to the cheapest SDF
/// recovered **0.1ms**, because the cost is not in what the shader computes
/// — it is the save layer and the backdrop read each lens forces, once per
/// lens per frame. So tune everything here for looks.
///
/// What *does* move the number is the **count** of glass surfaces on screen
/// at once (this feed shows ~17, most of them scrolling inside the list —
/// the pattern `liquid_glass_easy` explicitly advises against). If this
/// screen needs to be faster, that is the only lever: fewer lenses, not
/// cheaper ones.
@immutable
class GlassTheme extends ThemeExtension<GlassTheme> {
  const GlassTheme({
    required this.onSurface,
    required this.onPhoto,
    required this.flatForm,
  });

  /// `.gl` — glass over the app surface. Themed.
  final GlassMaterial onSurface;

  /// `.g` — glass over photography. Fixed; the same values in both themes.
  final GlassMaterial onPhoto;

  /// `.glf` — flat glass for form controls. Themed.
  final GlassMaterial flatForm;

  /// `.g` is non-themed, so both [light] and [dark] share this one value
  /// rather than restating it — whatever sits under it is a photo, not app
  /// chrome, and doesn't change when the app theme does.
  static const GlassMaterial _onPhoto = GlassMaterial(
    tint: Color(0x26FFFFFF), // rgba(255,255,255,.15)
    blurSigma: 7.5,
    saturation: 2.0, // CSS saturate(200%)
    // Pushed harder than `.gl`: a photo is high-frequency content, so the
    // bend is legible where it would be invisible over flat app chrome.
    distortion: 0.16,
    // Every `.g` box in the app is small — a price pill, a Sale badge, a
    // 34px favourite button. None of them can carry a wide band.
    distortionWidth: 7,
    magnification: 1.03,
    chromaticAberration: 0.005,
    cornerStyle: LiquidGlassCornerStyle.continuousRoundedRectangle,
    borderWidth: 1,
    borderColor: null,
    lightColor: Color(0xE6FFFFFF), // rgba(255,255,255,.9)
    lightIntensity: 1.15,
    borderType: OpticalBorder(borderSaturation: 1.6, ambientIntensity: 1.0),
    shadow: [
      BoxShadow(
        color: Color.fromRGBO(10, 10, 20, 0.5),
        offset: Offset(0, 8),
        blurRadius: 22,
        spreadRadius: -5,
      ),
    ],
  );

  static const light = GlassTheme(
    onSurface: GlassMaterial(
      // was rgba(255,255,255,.62) — see GlassMaterial.tint.
      tint: Color(0x70FFFFFF),
      blurSigma: 11,
      saturation: 1.85, // CSS saturate(185%)
      distortion: 0.12,
      distortionWidth: 10,
      magnification: 1.0,
      chromaticAberration: 0.004,
      cornerStyle: LiquidGlassCornerStyle.continuousRoundedRectangle,
      borderWidth: 1,
      borderColor: null,
      lightColor: Color(0xE6FFFFFF),
      lightIntensity: 1.0,
      borderType: OpticalBorder(
        // Ambient is what keeps the rim visible on its shadow side, and a
        // light backdrop already supplies plenty — pushing it here is what
        // turns the rim from an edge into a haze.
        borderSaturation: 1.25,
        ambientIntensity: 0.75,
        borderSolidity: 0.0,
      ),
      shadow: [
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
    ),
    onPhoto: _onPhoto,
    flatForm: GlassMaterial(
      tint: Color(0x70FFFFFF), // `.glf` reads `var(--gl-bg)` too
      blurSigma: 10,
      saturation: 1.8, // CSS saturate(180%)
      // Near-zero: an input is a place to read text, not a lens.
      distortion: 0.04,
      distortionWidth: 8,
      magnification: 1.0,
      chromaticAberration: 0,
      cornerStyle: LiquidGlassCornerStyle.continuousRoundedRectangle,
      borderWidth: 1,
      // Null here; GlassSurface substitutes LaCasaColors.line, which is
      // where the source's `0 0 0 1px var(--line)` ring lives.
      borderColor: null,
      lightColor: Color(0xCCFFFFFF), // was glfTopHighlight
      lightIntensity: 0.9,
      borderType: ClassicBorder(borderSoftness: 1.2),
      shadow: [
        BoxShadow(
          color: Color.fromRGBO(32, 28, 46, 0.55),
          offset: Offset(0, 6),
          blurRadius: 16,
          spreadRadius: -7,
        ),
      ],
    ),
  );

  static const dark = GlassTheme(
    onSurface: GlassMaterial(
      tint: Color(0x5C404052), // was rgba(64,64,82,.46)
      blurSigma: 11,
      saturation: 1.85,
      distortion: 0.12,
      distortionWidth: 10,
      magnification: 1.0,
      chromaticAberration: 0.004,
      cornerStyle: LiquidGlassCornerStyle.continuousRoundedRectangle,
      borderWidth: 1,
      borderColor: null,
      lightColor: Color(0x8CFFFFFF), // rgba(255,255,255,.55)
      lightIntensity: 0.9,
      borderType: OpticalBorder(
        // A dark backdrop gives the optical rim less to tint itself with,
        // so lean on ambient rather than saturation to keep it visible.
        borderSaturation: 1.2,
        ambientIntensity: 1.4,
        borderSolidity: 0.1,
      ),
      shadow: [
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
    ),
    onPhoto: _onPhoto,
    flatForm: GlassMaterial(
      tint: Color(0x5C404052),
      blurSigma: 10,
      saturation: 1.8,
      distortion: 0.04,
      distortionWidth: 8,
      magnification: 1.0,
      chromaticAberration: 0,
      cornerStyle: LiquidGlassCornerStyle.continuousRoundedRectangle,
      borderWidth: 1,
      borderColor: null,
      lightColor: Color(0x24FFFFFF), // rgba(255,255,255,.14)
      lightIntensity: 0.8,
      borderType: ClassicBorder(borderSoftness: 1.2),
      shadow: [], // no outer drop shadow in dark mode
    ),
  );

  @override
  GlassTheme copyWith({
    GlassMaterial? onSurface,
    GlassMaterial? onPhoto,
    GlassMaterial? flatForm,
  }) {
    return GlassTheme(
      onSurface: onSurface ?? this.onSurface,
      onPhoto: onPhoto ?? this.onPhoto,
      flatForm: flatForm ?? this.flatForm,
    );
  }

  @override
  GlassTheme lerp(ThemeExtension<GlassTheme>? other, double t) {
    if (other is! GlassTheme) return this;
    return GlassTheme(
      onSurface: GlassMaterial.lerp(onSurface, other.onSurface, t),
      onPhoto: GlassMaterial.lerp(onPhoto, other.onPhoto, t),
      flatForm: GlassMaterial.lerp(flatForm, other.flatForm, t),
    );
  }
}
