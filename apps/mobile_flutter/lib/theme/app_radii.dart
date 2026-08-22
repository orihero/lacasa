import 'package:flutter/widgets.dart';

/// Corner-radius scale for Direction E "Liquid Glass".
///
/// Radii map to component *role*, not to one arbitrary scale (design-token
/// spec §4). Two shapes are asymmetric/special-cased rather than scalar and
/// are exposed as ready-made [BorderRadius] values: [hero] and [pill].
abstract final class AppRadii {
  /// 8px — checkboxes (`.chk`).
  static const double xs = 8;

  /// 12px (source range 10–12px) — grid thumbnails, icon chips, badges.
  static const double sm = 12;

  /// 16px (source range 13–16px) — `.hpill`, `.gal`, `.kv`, `.callout`,
  /// map pin. NOTE: this is distinct from [control] (18px), which the
  /// source calls out as its own value even though it sits in this range.
  static const double md = 16;

  /// 18px — text inputs, textareas, select boxes (`.inp`, `.ta`,
  /// `.selbox`). Pair with [GlassVariant.flatForm] surfaces.
  static const double control = 18;

  /// 20px — `.chip`, `.lrow`, `.tile`, `.trow`, `.dist`, `.movebox`.
  static const double card = 20;

  /// 22px — `.card`, `.panel`, `.promo`, `.lcard`, `.picks .pick`.
  static const double cardLg = 22;

  /// 24px — `.hero-ic`, `.idcard`, `.chan`, `.empty`, `.me`.
  static const double cardXl = 24;

  /// 28px (source range 27–28px) — `.btn`, `.book`, `.tabbar`.
  static const double pillButton = 28;

  /// 32px (source range 30–34px) — bottom sheets (`.sh`).
  static const double sheet = 32;

  /// 30px — centered alert sheet (`.sh--mid`), the one sheet radius the
  /// source pins to a single value rather than a range.
  static const double sheetMid = 30;

  /// True pill / circle radius, for avatars, `.rnd` round buttons, `.fav`,
  /// `.iconbtn`, dots. Use with `BorderRadius.circular(pillValue)` on a
  /// square box, or [ShapeDecoration]/[CircleAvatar] directly.
  static const double pillValue = 9999;

  /// Asymmetric hero image radius — top corners rounder than the bottom,
  /// a deliberate detail from the source (`.hero{border-radius:40px 40px
  /// 26px 26px}`) preserved explicitly rather than flattened to a uniform
  /// token.
  static const BorderRadius hero = BorderRadius.only(
    topLeft: Radius.circular(40),
    topRight: Radius.circular(40),
    bottomLeft: Radius.circular(26),
    bottomRight: Radius.circular(26),
  );

  /// Ready-made fully-round [BorderRadius], convenience wrapper around
  /// [pillValue].
  static const BorderRadius pill = BorderRadius.all(Radius.circular(pillValue));
}
