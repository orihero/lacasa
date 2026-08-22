import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:liquid_glass_easy/liquid_glass_easy.dart';

import 'app_colors.dart';
import 'glass_theme_extension.dart';

/// Which glass material to render, mirroring the prototype's `.g` / `.gl` /
/// `.glf` split (design-token spec §6).
enum GlassVariant {
  /// `.gl` — glass over the **app surface** (`--screen`/`--card`). Themed.
  /// Use for the location pill, top-bar icon buttons, filter chips, tags/
  /// segments/options, the bottom-sheet bar, the flagged "smart pitch"
  /// card, hero-icon badges.
  onSurface,

  /// `.g` — glass over **photography**. Fixed, non-themed — same values
  /// in light and dark, because whatever sits under it is a photo, not the
  /// app chrome. Use for badges, favorite buttons, price pills, hero back/
  /// share buttons, district-name labels over photos.
  onPhoto,

  /// `.glf` — "flat glass": the same tint as [onSurface] with the
  /// refraction pulled almost to nothing and a crisp hairline border
  /// instead of an optical rim, for use as the background of an actual form
  /// field (`TextField` etc.). A text input is a place to read text; a lens
  /// that bends its own label is the wrong material for one.
  flatForm,
}

/// The glass material primitive for Direction E "Liquid Glass" — a real
/// refracting lens, rendered by `liquid_glass_easy`'s [LiquidGlassLens].
///
/// Reads its parameters from `Theme.of(context).extension&lt;GlassTheme&gt;()`
/// (see `glass_theme_extension.dart`) and `Theme.of(context)
/// .extension&lt;LaCasaColors&gt;()` (for the hairline color used by
/// [GlassVariant.flatForm]), so it automatically follows light/dark theme
/// switches — no separate light/dark API.
///
/// ## What changed, and why
/// This used to be a hand-built frosted panel: [BackdropFilter] blur, a
/// near-opaque tint, a radial "sheen" gradient and a 1px gradient-stroked
/// rim painted by a [CustomPainter]. That is *glassmorphism* — it looks
/// like glass because it was drawn to. It does not refract: nothing behind
/// it bends, the rim does not pick up what it sits on, and it cannot
/// respond to what moves underneath.
///
/// [LiquidGlassLens] is a shader. It samples the live backdrop and actually
/// bends it through a perimeter band, with magnification, chromatic
/// aberration and an SDF-derived rim light that takes its color from
/// whatever is behind the glass. The sheen and rim layers are gone because
/// the shader derives both; the tint dropped in strength because the
/// refraction now carries the read (see [GlassMaterial.tint]).
///
/// It also closes a gap the old implementation documented and could not
/// fix: CSS `saturate()` had no `ImageFilter` equivalent, so
/// `backdrop-filter: blur(22px) saturate(185%)` degraded to plain blur.
/// The lens has a saturation term, so `1.85` is now applied for real.
///
/// ## Engine dependence — read before judging a screenshot
/// - **Impeller** (Flutter's default on modern iOS/Android, and what this
///   app ships on): the lens refracts the live backdrop anywhere in the
///   tree. No setup, no background widget.
/// - **Skia / web**: refraction needs an ancestor `LiquidGlassView` with a
///   `backgroundWidget`. Without one the lens *degrades to the frosted
///   look* — blur + tint + border. So a Chrome or `flutter test` render is
///   not evidence about how this looks; check it on the Android/iOS build.
///
/// ## Lenses inside scrollables
/// Android's stretch overscroll isolates a scrollable into its own layer,
/// which can make a backdrop lens inside it render **black** at the scroll
/// edges. Any scroll view containing a [GlassSurface] must disable the
/// overscroll indicator — see `home_feed_screen.dart`, which wraps its
/// [CustomScrollView] in a [ScrollConfiguration] for exactly this reason.
///
/// ## Performance
/// The lens is a backdrop-sampling shader and costs what one costs. Two
/// rules keep it cheap:
/// - **Don't nest [GlassSurface]s.** Overlapping lenses each re-refract
///   what the one beneath already bent — visually wrong *and* the most
///   common way this gets slow. Compose glass side-by-side; put plain
///   [Container]s, [Text] and [Icon]s inside a [GlassSurface], never
///   another [GlassSurface].
/// - Prefer glass that **floats above** content over glass that scrolls
///   with it, and avoid many large lenses over one complex,
///   frequently-repainting background if it shows up in profiling.
class GlassSurface extends StatelessWidget {
  const GlassSurface({
    super.key,
    required this.child,
    this.variant = GlassVariant.onSurface,
    this.borderRadius = const BorderRadius.all(Radius.circular(20)),
    this.padding,
    this.width,
    this.height,
    this.alignment,
    this.distortionWidth,
  });

  /// Content painted on top of the glass, clipped to the lens shape.
  final Widget child;

  /// Which of `.g` / `.gl` / `.glf` to render. Defaults to
  /// [GlassVariant.onSurface] (`.gl`), the most common case — cards, chips
  /// and bars sitting on the app background rather than on a photo.
  final GlassVariant variant;

  /// Corner radius. The lens takes a **scalar** corner radius, so an
  /// asymmetric [BorderRadius] (e.g. [AppRadii.hero], 40/40/26/26) is
  /// resolved to its largest corner — the shape's dominant read — rather
  /// than silently dropping to the smallest. Pass any [AppRadii] value
  /// wrapped in `BorderRadius.circular(...)`, or [AppRadii.pill] for a
  /// capsule (the radius clamps to half the short side, so a full radius
  /// gives a clean capsule).
  final BorderRadius borderRadius;

  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  /// Overrides the variant's [GlassMaterial.distortionWidth] — the
  /// thickness, in logical pixels, of the band around the perimeter where
  /// the backdrop bends.
  ///
  /// This is the one glass parameter that does not scale with the box it
  /// is applied to, so a band tuned for a card swallows a short chip whole.
  /// The variant defaults suit each variant's typical box; set this when
  /// a call site's box is much smaller or much larger than that.
  final double? distortionWidth;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassTheme>() ?? GlassTheme.light;
    final lineColor =
        theme.extension<LaCasaColors>()?.line ?? LaCasaColors.light.line;

    final GlassMaterial material = switch (variant) {
      GlassVariant.onSurface => glass.onSurface,
      GlassVariant.onPhoto => glass.onPhoto,
      GlassVariant.flatForm => glass.flatForm,
    };

    // `.glf` is the only variant that wants a stated hairline rather than
    // a rim the shader derives — the source's `0 0 0 1px var(--line)`.
    final Color? borderColor = variant == GlassVariant.flatForm
        ? (material.borderColor ?? lineColor)
        : material.borderColor;

    // **The lens takes its size from its child**, so a stated [width]/
    // [height] alone does not make the *glass* that size — it only sizes
    // the box around it. Left as-is, `GlassSurface(width: 40, height: 40,
    // alignment: center, child: Icon(size: 19))` painted a 19dp disc
    // floating in a 40dp box: every round glass button in the app
    // (favourite hearts, header actions, nav back/close chips) rendered at
    // its glyph's size rather than the size the source CSS states. This
    // [Align] hands the lens the sized axes so it fills them, and keeps
    // shrink-wrapping the axes the caller left unsized (factor `1.0`).
    //
    // Deliberately *inside* the lens, with the outer [Container]'s own
    // [alignment] left untouched: that outer alignment also decides
    // whether the box expands to its parent, which many call sites depend
    // on, so the box's geometry is unchanged in every case — only the
    // glass grows into the size that was already being reserved for it.
    final Widget inner =
        (alignment != null && (width != null || height != null))
        ? Align(
            alignment: alignment!,
            widthFactor: width == null ? 1.0 : null,
            heightFactor: height == null ? 1.0 : null,
            child: child,
          )
        : child;

    final lens = LiquidGlassLens(
      style: LiquidGlassStyle(
        shape: LiquidGlassShape(
          cornerStyle: material.cornerStyle,
          cornerRadius: _cornerRadius,
          borderWidth: material.borderWidth,
          borderColor: borderColor,
          lightColor: material.lightColor,
          lightIntensity: material.lightIntensity,
          borderType: material.borderType,
        ),
        appearance: LiquidGlassAppearance(
          color: material.tint,
          blur: LiquidGlassBlur(
            sigmaX: material.blurSigma,
            sigmaY: material.blurSigma,
          ),
          saturation: material.saturation,
        ),
        refraction: LiquidGlassRefraction(
          distortion: material.distortion,
          distortionWidth: distortionWidth ?? material.distortionWidth,
          magnification: material.magnification,
          chromaticAberration: material.chromaticAberration,
        ),
      ),
      child: Padding(padding: padding ?? EdgeInsets.zero, child: inner),
    );

    // The drop shadow is painted here, outside the lens: it must not be
    // sampled as part of the backdrop the lens refracts, and must not be
    // clipped away by the lens's own rounded silhouette.
    return Container(
      width: width,
      height: height,
      alignment: alignment,
      decoration: BoxDecoration(
        borderRadius: borderRadius,
        boxShadow: material.shadow,
      ),
      child: lens,
    );
  }

  /// The scalar radius handed to [LiquidGlassShape] — see [borderRadius].
  double get _cornerRadius => math.max(
    math.max(borderRadius.topLeft.x, borderRadius.topRight.x),
    math.max(borderRadius.bottomLeft.x, borderRadius.bottomRight.x),
  );
}
