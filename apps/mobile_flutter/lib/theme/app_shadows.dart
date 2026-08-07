import 'package:flutter/widgets.dart';

/// Elevation / shadow tiers for Direction E "Liquid Glass" (design-token
/// spec §5).
///
/// The source CSS has no formal numbered elevation system — shadows are
/// bespoke per component but fall into clear tiers, all using a warm
/// near-black tint (never pure black), and — a deliberate simplification
/// the prototype itself makes — **none of these are re-themed for dark
/// mode** (unlike the glass shadows in [GlassTheme], which do differ by
/// theme). Carry the same [BoxShadow] lists in light and dark until a
/// future design pass says otherwise.
///
/// ## Negative CSS spread → Flutter
/// CSS `box-shadow: 0 12px 26px -22px rgba(...)` has no exact Flutter
/// equivalent: `BoxShadow.spreadRadius` grows/shrinks the shadow shape
/// symmetrically *before* blur, where CSS's 4th value shrinks the shadow's
/// spread as a signed offset with different math. Every constant below
/// approximates the CSS negative-spread value as `spreadRadius ≈
/// cssSpread / 2`, per the token spec's own guidance — treat it as a
/// starting point to eyeball-correct against a screenshot, not an exact
/// conversion.
abstract final class AppShadows {
  /// E1 — resting card. `.card`, `.panel`, `.agentrow`, list rows on a
  /// `.card` background.
  /// CSS: `0 12px 26px -22px rgba(30,24,44,.6)`
  static const List<BoxShadow> card = [
    BoxShadow(
      color: Color.fromRGBO(30, 24, 44, 0.6),
      offset: Offset(0, 12),
      blurRadius: 26,
      spreadRadius: -11,
    ),
  ];

  /// E2 — selected pill / active chip, small size. `.chip.on`, `.tab.on`,
  /// `.seg.on`, `.opt.on`, `.pick.on`, `.map__pin.on`.
  /// CSS: `0 8px 18px -8px rgba(21,21,27,.55)`
  static const List<BoxShadow> selectedChip = [
    BoxShadow(
      color: Color.fromRGBO(21, 21, 27, 0.55),
      offset: Offset(0, 8),
      blurRadius: 18,
      spreadRadius: -4,
    ),
  ];

  /// E2 — selected pill / active chip, large size. `.btn--ink`.
  /// CSS: `0 10px 22px -10px rgba(21,21,27,.7)`
  static const List<BoxShadow> selectedPillLarge = [
    BoxShadow(
      color: Color.fromRGBO(21, 21, 27, 0.7),
      offset: Offset(0, 10),
      blurRadius: 22,
      spreadRadius: -5,
    ),
  ];

  /// E3 — floating photo card, promo tile. `.promo`.
  /// CSS: `0 16px 30px -20px rgba(30,24,44,.6)`
  static const List<BoxShadow> floatingPromo = [
    BoxShadow(
      color: Color.fromRGBO(30, 24, 44, 0.6),
      offset: Offset(0, 16),
      blurRadius: 30,
      spreadRadius: -10,
    ),
  ];

  /// E3 — floating photo card, listing hero. `.hero`.
  /// CSS: `0 18px 34px -22px rgba(30,24,44,.5)`
  static const List<BoxShadow> floatingHero = [
    BoxShadow(
      color: Color.fromRGBO(30, 24, 44, 0.5),
      offset: Offset(0, 18),
      blurRadius: 34,
      spreadRadius: -11,
    ),
  ];

  /// E4 — modal / full-screen panel. Sourced from `.idx__in` (the
  /// prototype's own all-screens index sheet — demo-harness only), but the
  /// same tier applies to any full-screen modal panel in the app.
  /// CSS: `0 30px 70px -30px rgba(10,8,20,.7)`
  static const List<BoxShadow> modal = [
    BoxShadow(
      color: Color.fromRGBO(10, 8, 20, 0.7),
      offset: Offset(0, 30),
      blurRadius: 70,
      spreadRadius: -15,
    ),
  ];

  /// Accent glow — primary CTA buttons (`.btn--acc`, `.book`).
  /// CSS: `0 10px 22px -8px rgba(229,34,127,.6)`, always paired in the
  /// source with `inset 0 1px 0 rgba(255,255,255,.5), inset 0 -1px 0
  /// rgba(140,10,70,.28)`. Flutter's [BoxShadow] cannot express an inset
  /// shadow at all — there is no `inset:true` flag the way CSS has one.
  /// Reproduce the two inset highlights, if needed, as a thin gradient
  /// overlay [Container] painted just inside the button's top and bottom
  /// edges, not as part of this list.
  static const List<BoxShadow> accentGlow = [
    BoxShadow(
      color: Color.fromRGBO(229, 34, 127, 0.6),
      offset: Offset(0, 10),
      blurRadius: 22,
      spreadRadius: -4,
    ),
  ];
}
