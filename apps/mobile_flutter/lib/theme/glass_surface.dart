import 'dart:ui';

import 'package:flutter/material.dart';

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

  /// `.glf` — "flat glass": the same visual material as [onSurface]
  /// rebuilt without the rim/sheen pseudo-element layers, for use as the
  /// background of an actual form field (`TextField` etc.) where this
  /// widget wraps a void-element-like child that can't carry decorative
  /// overlays the way a card can. No rim, no sheen; the CSS inset top
  /// highlight is approximated with a 1px highlight line instead (see
  /// [GlassTheme.glfTopHighlight]).
  flatForm,
}

/// The glass material primitive for Direction E "Liquid Glass" — reproduces
/// the prototype's `.g`/`.gl`/`.glf` surfaces (design-token spec §6).
///
/// Reads its parameters from `Theme.of(context).extension&lt;GlassTheme&gt;()`
/// (see `glass_theme_extension.dart`) and `Theme.of(context)
/// .extension&lt;LaCasaColors&gt;()` (for the hairline ring color used by
/// [GlassVariant.flatForm]), so it automatically follows light/dark theme
/// switches — no separate light/dark API.
///
/// Composed of four layers, from back to front, reproducing the CSS
/// stacking order (`.g::before`/`.gl::before` paint *above* the element's
/// own children per their `z-index:3` vs. `z-index:2`):
///
/// 1. **Blur + tint** — [ClipRRect] + [BackdropFilter] with
///    [ImageFilter.blur], with a solid tint [Color] as the backdrop
///    filter's child (doubling as both the blur target and the fill).
/// 2. **Sheen** — a soft radial highlight, [GlassVariant.flatForm] only
///    skips this (see [GlassVariant.flatForm] doc).
/// 3. **Content** — [child], padded by [padding].
/// 4. **Rim** — a 1px gradient-stroke border, painted with a
///    [CustomPainter] (see [_RimPainter]) rather than CSS's mask-composite
///    trick, which Flutter has no equivalent of. Skipped for
///    [GlassVariant.flatForm], which instead gets a 1px highlight line at
///    its top edge plus a solid 1px hairline border in the theme's `line`
///    color (approximating the CSS `inset` highlight and `0 0 0 1px
///    var(--line)` ring, neither of which [BoxShadow] can express).
///
/// The outer [Container]'s [BoxShadow] list is applied **outside** the
/// [ClipRRect] deliberately — shadows must not be blurred along with the
/// backdrop, and must not be clipped by the rounded corners either.
///
/// ## What has no exact Flutter equivalent (be aware before you tune this)
/// - **`saturate()`/`brightness()`** — `dart:ui`'s [ImageFilter] has no
///   built-in saturation or brightness filter, so `backdrop-filter:
///   blur(22px) saturate(185%)` becomes plain blur here. The tint alpha
///   and sheen highlight are relied on instead to sell the "glass" read —
///   the cheaper of the two honest approximations the token spec lays out
///   (the more faithful one composes a [ColorFilter] saturation matrix via
///   `ImageFiltered`/`ColorFiltered` in the same backdrop chain, at the
///   cost of an extra compositing pass; not done here to keep this a
///   primitive that's cheap to use everywhere).
/// - **CSS blur-radius → Flutter sigma** — no 1:1 formula exists. Each
///   variant's `*BlurSigma` in [GlassTheme] starts from
///   `cssBlurPx / 2` and is meant to be eyeballed against a screenshot,
///   not trusted as exact.
/// - **The radial sheen's independent x/y radii** (`135% 95%`) — Flutter's
///   [RadialGradient] has one scalar radius; approximated as a circle.
/// - **CSS `inset` box-shadow** — [BoxShadow] has no inset flag at all.
///   [GlassVariant.flatForm]'s top highlight line is a real [Container],
///   not a shadow.
/// - **CSS mask-composite rim trick** — reproduced with a [CustomPainter]
///   stroke instead (see [_RimPainter]), the alternative the token spec
///   itself names as acceptable over a nested-container inset, which can
///   show antialiasing seams at small radii.
///
/// ## Performance
/// [BackdropFilter] is expensive: it forces Flutter to composite and
/// re-rasterize everything painted beneath it, every frame it's visible.
/// Two rules to keep this cheap:
/// - **Don't nest [GlassSurface]s.** A glass card containing a glass chip
///   containing a glass icon button means three overlapping backdrop
///   filters each re-blurring what's already blurred beneath them —
///   visually wrong (double-blur) *and* the most common way this primitive
///   gets slow. Compose glass surfaces side-by-side, not inside one
///   another; put non-glass content (plain [Container]s, [Text], [Icon])
///   inside a [GlassSurface], never another [GlassSurface].
/// - **The blur is confined by [ClipRRect]** already — never wrap a
///   [GlassSurface] in a widget that removes or enlarges that clip, and
///   avoid placing many large [GlassSurface]s over a single complex,
///   frequently-repainting background (e.g. a scrolling photo list) if it
///   shows up in profiling.
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
  });

  /// Content painted on top of the glass material (layer 3).
  final Widget child;

  /// Which of `.g` / `.gl` / `.glf` to render. Defaults to [GlassVariant.onSurface]
  /// (`.gl`), the most common case — cards, chips, bars sitting on the app
  /// background rather than on a photo.
  final GlassVariant variant;

  /// Corner radius, shared by the clip, the tint, the rim stroke, and the
  /// outer shadow. Pass any [AppRadii] value wrapped in a
  /// `BorderRadius.circular(...)`, or [AppRadii.hero]/[AppRadii.pill] for
  /// the pre-built asymmetric/circular shapes.
  final BorderRadius borderRadius;

  final EdgeInsetsGeometry? padding;
  final double? width;
  final double? height;
  final AlignmentGeometry? alignment;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final glass = theme.extension<GlassTheme>() ?? GlassTheme.light;
    final lineColor =
        theme.extension<LaCasaColors>()?.line ?? LaCasaColors.light.line;

    final Color background;
    final Gradient? rim;
    final Gradient? sheen;
    final List<BoxShadow> shadow;
    final double blurSigma;

    switch (variant) {
      case GlassVariant.onSurface:
        background = glass.glBackground;
        rim = glass.glRim;
        sheen = glass.glSheen;
        shadow = glass.glShadow;
        blurSigma = glass.glBlurSigma;
      case GlassVariant.onPhoto:
        background = glass.gBackground;
        rim = glass.gRim;
        sheen = glass.gSheen;
        shadow = glass.gShadow;
        blurSigma = glass.gBlurSigma;
      case GlassVariant.flatForm:
        background = glass.glfBackground;
        rim = null;
        sheen = null;
        shadow = glass.glfShadow;
        blurSigma = glass.glfBlurSigma;
    }

    final glassBody = ClipRRect(
      borderRadius: borderRadius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
        child: Stack(
          fit: StackFit.passthrough,
          children: [
            // 1. tint (also the BackdropFilter's required child)
            Positioned.fill(child: ColoredBox(color: background)),

            // 2. sheen (skipped for .glf)
            if (sheen != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(gradient: sheen),
                  ),
                ),
              ),

            // .glf-only: approximated inset top highlight.
            if (variant == GlassVariant.flatForm)
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                child: IgnorePointer(
                  child: Container(height: 1, color: glass.glfTopHighlight),
                ),
              ),

            // .glf-only: approximated `0 0 0 1px var(--line)` ring.
            if (variant == GlassVariant.flatForm)
              Positioned.fill(
                child: IgnorePointer(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: borderRadius,
                      border: Border.all(color: lineColor, width: 1),
                    ),
                  ),
                ),
              ),

            // 3. content
            Padding(padding: padding ?? EdgeInsets.zero, child: child),

            // 4. rim — painted last so it sits above content, matching the
            // source's `::before{z-index:3}` vs. children's `z-index:2`.
            if (rim != null)
              Positioned.fill(
                child: IgnorePointer(
                  child: CustomPaint(
                    painter: _RimPainter(gradient: rim, radius: borderRadius),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    return Container(
      width: width,
      height: height,
      alignment: alignment,
      decoration: BoxDecoration(borderRadius: borderRadius, boxShadow: shadow),
      child: glassBody,
    );
  }
}

/// Paints the glass rim: a 1px ring stroked with a [Gradient] shader.
///
/// CSS builds this with the "double-background + `mask-composite:exclude`"
/// trick — a `content-box` mask and a full-box mask XOR'd together so only
/// the outer 1px ring paints, letting a gradient run around the border
/// instead of a flat color. Flutter has no mask-composite primitive, so
/// this fills the even-odd difference between the full rounded rect and a
/// 1px-deflated copy of itself with a shader from [gradient] — the
/// alternative the token spec names explicitly over a nested-container
/// inset (which can show antialiasing seams at small radii).
class _RimPainter extends CustomPainter {
  const _RimPainter({required this.gradient, required this.radius});

  final Gradient gradient;
  final BorderRadius radius;

  static const double _strokeWidth = 1;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Offset.zero & size;
    final outer = radius.toRRect(rect);
    final inner = outer.deflate(_strokeWidth);
    final ringPath = Path()
      ..fillType = PathFillType.evenOdd
      ..addRRect(outer)
      ..addRRect(inner);
    final paint = Paint()..shader = gradient.createShader(rect);
    canvas.drawPath(ringPath, paint);
  }

  @override
  bool shouldRepaint(covariant _RimPainter oldDelegate) {
    return oldDelegate.gradient != gradient || oldDelegate.radius != radius;
  }
}
