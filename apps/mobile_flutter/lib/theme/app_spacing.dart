/// Spacing scale for Direction E "Liquid Glass".
///
/// The prototype is *not* on a strict 4/8pt grid — component gaps are tuned
/// per component and cluster around these values (see the design-token spec,
/// §3). This file collapses the observed range to the values that are
/// actually reused the most; where the source documented a range, the
/// comment records it and the constant picks the value nearer the high end
/// (the value more often seen at "the" load-bearing spot, e.g. the 20px
/// screen gutter).
///
/// [screenGutter] (`xl`) is the single most important constant here: every
/// full-bleed content column in the prototype (`.body`, `.pad`) pads left
/// and right by 20px. Use it for the canonical
/// `EdgeInsets.symmetric(horizontal: AppSpacing.screenGutter)`.
abstract final class AppSpacing {
  /// 4px — icon-to-label micro gaps, step-bar gap.
  static const double xs = 4;

  /// 6px (source range 6–7px) — chip icon gap, field label bottom margin.
  static const double sm = 6;

  /// 8px (source range 8–9px) — `.agents` gap, photo grid gap, `.kv` padding.
  static const double md = 8;

  /// 12px (source range 11–12px) — list-row internal gaps (`.lrow`,
  /// `.trow`, `.kcard`), `.rail` gap.
  static const double base = 12;

  /// 16px (source range 14–16px) — card internal padding (`.panel`,
  /// `.card`), `.chan` padding.
  static const double lg = 16;

  /// 20px — the screen horizontal gutter (`.pad`, `.body{padding:0 20px}`).
  /// Also doubles as the prototype's `.det__b` exception is 14px, not this.
  static const double xl = 20;
  static const double screenGutter = xl;

  /// 22px — prompt / lead modal padding.
  static const double xxl = 22;

  /// 20px — vertical rhythm between feed sections (`.sec{margin-top:20px}`).
  /// Kept as a distinct semantic name from [xl] even though the value is
  /// identical, since the two tokens mean different things (horizontal
  /// gutter vs. vertical section rhythm) and may diverge later.
  static const double section = 20;

  /// 15px — vertical rhythm between *form fields*
  /// (`.field{display:block;margin-top:15px}`). Deliberately not [section]:
  /// the prototype's forms run one flat 15px gap from field to field, where
  /// `.sec`'s 20px is the gap between whole feed sections. A form that
  /// alternates the two reads as arbitrary grouping the source never states.
  static const double field = 15;
}
