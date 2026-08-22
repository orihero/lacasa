import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Semantic type scale for Direction E "Liquid Glass" (design-token spec
/// §2). Poppins is the *only* typeface in the system — weights 400/500/
/// 600/700, roman only (no italic, no 300/800/900 anywhere in the source).
///
/// Registered as a [ThemeExtension] so any widget can reach the exact
/// semantic role via `Theme.of(context).extension<LaCasaTypography>()!`,
/// rather than only the ~13 generic slots [TextTheme] offers (a subset of
/// these roles is also wired into [ThemeData.textTheme] in `app_theme.dart`
/// for plain [Text] widgets that don't care about the distinction — but
/// that mapping is necessarily lossy against the ~20 roles the prototype
/// actually uses, so prefer this extension when fidelity matters).
///
/// Font source: **`google_fonts`**, not bundled `.ttf` assets. The
/// prototype self-hosts Poppins as base64 `woff2` `@font-face` blocks — the
/// token spec's own "for Flutter" recommendation is to bundle local font
/// assets instead of `google_fonts` for the same reason (avoid a network
/// fetch / flash-of-fallback-font). That would require declaring a `fonts:`
/// block in `pubspec.yaml`, which is out of scope for this change: this
/// theme package owns `lib/theme/` only and must not touch `pubspec.yaml`.
/// `google_fonts` was already added as a project dependency during
/// scaffolding specifically to cover this gap, so it is used here as
/// specified by that decision; swapping to bundled assets later is a
/// pubspec-and-this-file-only change (see [poppins] and every builder
/// below, all funneled through [GoogleFonts.poppins]).
///
/// **Tabular numerals**: any price, count, date/countdown, or stat number
/// gets [FontFeature.tabularFigures] regardless of which size/weight role
/// it otherwise uses — call [tabular] to add it to any style from this
/// class. [numericDisplay] and [price] already have it baked in since the
/// source applies `font-variant-numeric:tabular-nums` to their selectors
/// unconditionally (`.tile__v`, `.bar__p`, `.pricefoot dd`, …).
///
/// **Uppercase labels**: [label] and [caption] correspond to CSS rules
/// with `text-transform:uppercase`. Flutter's [TextStyle] has no text-
/// transform property — apply `.toUpperCase()` to the string at the call
/// site instead.
@immutable
class LaCasaTypography extends ThemeExtension<LaCasaTypography> {
  const LaCasaTypography({
    required this.display,
    required this.displayLead,
    required this.numericDisplay,
    required this.price,
    required this.heroTitle,
    required this.navTitle,
    required this.sheetTitle,
    required this.sectionHeading,
    required this.alertTitle,
    required this.panelHeading,
    required this.identityName,
    required this.cardPrice,
    required this.cardTitle,
    required this.rowTitle,
    required this.pickSubtitle,
    required this.body,
    required this.bodySmall,
    required this.specMeta,
    required this.label,
    required this.caption,
    required this.micro,
  });

  /// `.onb__h` — onboarding headline. 25.5/700, on-photo (white +
  /// text-shadow at the call site, not baked in here since color is
  /// context-dependent).
  final TextStyle display;

  /// `.lead` — confirmation / lead-in screen headline. 23/700.
  final TextStyle displayLead;

  /// `.tile__v` — stat tile / KPI numbers. 25/700, tabular.
  final TextStyle numericDisplay;

  /// `.bar__p`, `.pricefoot dd` — bottom-bar price. 19.25/700 (source
  /// range 19–19.5px), tabular.
  final TextStyle price;

  /// `.hero__t` — listing detail hero title, on-photo. 19/700.
  final TextStyle heroTitle;

  /// `.nav__t` — screen title / nav header. 17.5/700.
  final TextStyle navTitle;

  /// `.sh__h h2` — bottom sheet title. 16.5/700.
  final TextStyle sheetTitle;

  /// `.sec h2` — feed section heading. 16/700.
  final TextStyle sectionHeading;

  /// `.alert__t`, `.idx__h h2` — alert / index title. 16/700.
  final TextStyle alertTitle;

  /// `.panel__h h3` — panel heading. 15.5/700.
  final TextStyle panelHeading;

  /// `.me__n` — identity / profile name. 15/700.
  final TextStyle identityName;

  /// `.lcard__p` — listing card price. 14/700.
  final TextStyle cardPrice;

  /// `.acard__n` — agent card name / card title. 13.5/700.
  final TextStyle cardTitle;

  /// `.lrow__t`, `.kcard__n`, `.agentrow__n`, `.trow__t` — the standard
  /// list-row title weight. 12.75/600 (source range 12.5–13px).
  final TextStyle rowTitle;

  /// `.pick__t`, `.prompt h2` — pick / prompt subtitle. 13.25/600.
  final TextStyle pickSubtitle;

  /// `.pane p`, `.lead__p` — primary paragraph copy. 12/400.
  final TextStyle body;

  /// `.lrow__s`, `.acard__l`, `.onb__p`, `.hint` — hint / list subtext.
  /// 11/400 (source range 10.5–11.5px).
  final TextStyle bodySmall;

  /// `.spec` — spec/meta line, e.g. "3 rooms · 65 m²" under a card title.
  /// 10.5/500.
  final TextStyle specMeta;

  /// `.field__l`, `.tile__l`, `.grouplab`, `.idx__g`, `.cw__h dt/dd` —
  /// uppercase eyebrow label. 10/600, ALWAYS uppercase (apply
  /// `.toUpperCase()` to the string) and conventionally colored
  /// `LaCasaColors.muted`.
  final TextStyle label;

  /// `.st`, `.badge` — status pill / caption text. 9.5/600, uppercase.
  final TextStyle caption;

  /// `.nrow__t`, `.trow__id`, `.gv__th` — timestamps, IDs. 9.25/500
  /// (source range 9–9.5px, weight 400–600).
  final TextStyle micro;

  static TextStyle _s({
    required double size,
    required FontWeight weight,
    double? height,
    required double letterSpacing,
  }) {
    return GoogleFonts.poppins(
      fontSize: size,
      fontWeight: weight,
      height: height,
      letterSpacing: letterSpacing,
    );
  }

  /// Adds `font-variant-numeric: tabular-nums` to any style from this
  /// class, for prices, counts, dates/countdowns, and stat numbers that
  /// aren't already one of [numericDisplay]/[price].
  static TextStyle tabular(TextStyle style) {
    return style.copyWith(
      fontFeatures: [
        ...?style.fontFeatures,
        const FontFeature.tabularFigures(),
      ],
    );
  }

  static final standard = LaCasaTypography(
    display: _s(
      size: 25.5,
      weight: FontWeight.w700,
      height: 1.3,
      letterSpacing: -0.5,
    ),
    displayLead: _s(
      size: 23,
      weight: FontWeight.w700,
      height: 1.24,
      letterSpacing: -0.7,
    ),
    numericDisplay: tabular(
      _s(size: 25, weight: FontWeight.w700, letterSpacing: -0.8),
    ),
    price: tabular(
      _s(size: 19.25, weight: FontWeight.w700, letterSpacing: -0.5),
    ),
    heroTitle: _s(
      size: 19,
      weight: FontWeight.w700,
      height: 1.28,
      letterSpacing: -0.5,
    ),
    navTitle: _s(
      size: 17.5,
      weight: FontWeight.w700,
      height: 1.2,
      letterSpacing: -0.45,
    ),
    sheetTitle: _s(size: 16.5, weight: FontWeight.w700, letterSpacing: -0.4),
    sectionHeading: _s(size: 16, weight: FontWeight.w700, letterSpacing: -0.35),
    alertTitle: _s(size: 16, weight: FontWeight.w700, letterSpacing: -0.35),
    panelHeading: _s(size: 15.5, weight: FontWeight.w700, letterSpacing: -0.3),
    identityName: _s(size: 15, weight: FontWeight.w700, letterSpacing: -0.35),
    cardPrice: _s(size: 14, weight: FontWeight.w700, letterSpacing: -0.4),
    cardTitle: _s(size: 13.5, weight: FontWeight.w700, letterSpacing: -0.2),
    rowTitle: _s(size: 12.75, weight: FontWeight.w600, letterSpacing: -0.05),
    pickSubtitle: _s(
      size: 13.25,
      weight: FontWeight.w600,
      height: 1.55,
      letterSpacing: -0.2,
    ),
    body: _s(
      size: 12,
      weight: FontWeight.w400,
      height: 1.655,
      letterSpacing: 0,
    ),
    bodySmall: _s(
      size: 11,
      weight: FontWeight.w400,
      height: 1.55,
      letterSpacing: 0,
    ),
    specMeta: _s(size: 10.5, weight: FontWeight.w500, letterSpacing: 0),
    label: _s(size: 10, weight: FontWeight.w600, letterSpacing: 0.35),
    caption: _s(size: 9.5, weight: FontWeight.w600, letterSpacing: 0.2),
    micro: _s(size: 9.25, weight: FontWeight.w500, letterSpacing: 0.15),
  );

  @override
  LaCasaTypography copyWith({
    TextStyle? display,
    TextStyle? displayLead,
    TextStyle? numericDisplay,
    TextStyle? price,
    TextStyle? heroTitle,
    TextStyle? navTitle,
    TextStyle? sheetTitle,
    TextStyle? sectionHeading,
    TextStyle? alertTitle,
    TextStyle? panelHeading,
    TextStyle? identityName,
    TextStyle? cardPrice,
    TextStyle? cardTitle,
    TextStyle? rowTitle,
    TextStyle? pickSubtitle,
    TextStyle? body,
    TextStyle? bodySmall,
    TextStyle? specMeta,
    TextStyle? label,
    TextStyle? caption,
    TextStyle? micro,
  }) {
    return LaCasaTypography(
      display: display ?? this.display,
      displayLead: displayLead ?? this.displayLead,
      numericDisplay: numericDisplay ?? this.numericDisplay,
      price: price ?? this.price,
      heroTitle: heroTitle ?? this.heroTitle,
      navTitle: navTitle ?? this.navTitle,
      sheetTitle: sheetTitle ?? this.sheetTitle,
      sectionHeading: sectionHeading ?? this.sectionHeading,
      alertTitle: alertTitle ?? this.alertTitle,
      panelHeading: panelHeading ?? this.panelHeading,
      identityName: identityName ?? this.identityName,
      cardPrice: cardPrice ?? this.cardPrice,
      cardTitle: cardTitle ?? this.cardTitle,
      rowTitle: rowTitle ?? this.rowTitle,
      pickSubtitle: pickSubtitle ?? this.pickSubtitle,
      body: body ?? this.body,
      bodySmall: bodySmall ?? this.bodySmall,
      specMeta: specMeta ?? this.specMeta,
      label: label ?? this.label,
      caption: caption ?? this.caption,
      micro: micro ?? this.micro,
    );
  }

  @override
  LaCasaTypography lerp(ThemeExtension<LaCasaTypography>? other, double t) {
    if (other is! LaCasaTypography) return this;
    TextStyle l(TextStyle a, TextStyle b) => TextStyle.lerp(a, b, t)!;
    return LaCasaTypography(
      display: l(display, other.display),
      displayLead: l(displayLead, other.displayLead),
      numericDisplay: l(numericDisplay, other.numericDisplay),
      price: l(price, other.price),
      heroTitle: l(heroTitle, other.heroTitle),
      navTitle: l(navTitle, other.navTitle),
      sheetTitle: l(sheetTitle, other.sheetTitle),
      sectionHeading: l(sectionHeading, other.sectionHeading),
      alertTitle: l(alertTitle, other.alertTitle),
      panelHeading: l(panelHeading, other.panelHeading),
      identityName: l(identityName, other.identityName),
      cardPrice: l(cardPrice, other.cardPrice),
      cardTitle: l(cardTitle, other.cardTitle),
      rowTitle: l(rowTitle, other.rowTitle),
      pickSubtitle: l(pickSubtitle, other.pickSubtitle),
      body: l(body, other.body),
      bodySmall: l(bodySmall, other.bodySmall),
      specMeta: l(specMeta, other.specMeta),
      label: l(label, other.label),
      caption: l(caption, other.caption),
      micro: l(micro, other.micro),
    );
  }
}
