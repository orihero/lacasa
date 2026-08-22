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
    required this.glyphTrack,
  });

  /// Primary text / icon color.
  final Color ink;

  /// Secondary text color.
  final Color ink2;

  /// Tertiary text color — labels, captions.
  ///
  /// In light mode this is a **contrast-floor value, not a free choice** —
  /// see [light]. It carries real content (listing-card locations and spec
  /// lines, "View all" links, uppercase field labels, chart axis labels)
  /// at 10–10.5px, so WCAG 2.1 AA's 4.5:1 body-text threshold applies, not
  /// the 3:1 large-text one. `test/theme/contrast_test.dart` locks it.
  final Color muted;

  /// Quaternary color — placeholders, disabled state.
  ///
  /// A **contrast-floor value in both brightnesses** (see [light] and
  /// [dark]): despite the "placeholder" framing it renders informational
  /// text too — input hints, `LaCasaTypography.micro` timestamps on
  /// lead/agent rows, empty-state and limits copy, inactive step labels —
  /// none of which WCAG's inactive-component exemption covers.
  ///
  /// Its one sub-4.5:1 sanctioned pairing is *light* `faint` on light
  /// [sunk], which is decorative-glyph only; `test/theme/contrast_test.dart`
  /// documents and bounds it. Dark `faint` clears 4.5:1 on all three dark
  /// grounds, [sunk] included, so it carries no exception at all.
  ///
  /// **Not for non-text glyphs whose whole point is to read as weaker than
  /// something beside them** — an unfilled star next to a filled one, an
  /// inactive page dot next to the active one. Those use [glyphTrack]; see
  /// its doc for why borrowing this token actively broke them.
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

  /// The **"off" half of a two-state glyph pair** — the unfilled star in a
  /// rating row (`shared/widgets/rating_stars.dart`,
  /// `features/agents/widgets/rating_input.dart`) and the inactive page dot
  /// on onboarding (`features/onboarding/widgets/onboarding_screen.dart`).
  ///
  /// Invented here; the design-token spec has no such role, and that
  /// omission is exactly why these call sites used to borrow [faint]. That
  /// borrow was fine while [faint] was a pale `#A2A2AE`, and broke the
  /// moment [faint] became a text token with a 4.5:1 floor: an unfilled
  /// star measured 4.94:1 on light [card] while a *filled*
  /// [AppStatusColors.ratingStar] `#E8A92C` measures 2.07:1, so the empty
  /// stars shouted louder than the full ones and the control read
  /// backwards. A glyph whose job is to recede cannot share a token with
  /// text whose job is to be legible; the two have opposite requirements,
  /// so they get two tokens.
  ///
  /// The constraint this value has to satisfy is therefore **relational,
  /// not absolute**: on every ground of its own brightness it must measure
  /// *lower* contrast than the "on" glyph it sits beside
  /// ([AppStatusColors.ratingStar] for stars, [AppAccent.color] for dots).
  /// `test/theme/contrast_test.dart` asserts that ordering rather than a
  /// fixed ratio. WCAG 1.4.11's 3:1 is deliberately **not** applied: the
  /// state of a rating row is carried by the filled stars and the adjacent
  /// "Review: n/5" text, not by the empty ones, and the filled star itself
  /// only reaches 2.07:1 on white — a real, separate defect in
  /// [AppStatusColors] (see `test/theme/contrast_test.dart`'s scope note),
  /// which cannot be fixed by making the *empty* star darker.
  final Color glyphTrack;

  /// The light palette.
  ///
  /// **[muted] and [faint] deviate from the design-token spec on purpose,
  /// and are contrast floors rather than free choices.** The spec's
  /// `#82828F` / `#A2A2AE` measure 3.79:1 and 2.53:1 on [card] and worse on
  /// [screen] — both well under WCAG 2.1 AA's 4.5:1 for text below the
  /// large-text threshold, which every one of their call sites is (10–11px,
  /// weights 400–600). Dark `muted` was fine at 5.41:1, so nothing in a dark
  /// build or a dark screenshot review would have shown it. (Dark [faint]
  /// turned out to carry the mirror-image defect — see [dark]. Neither
  /// brightness can be signed off by looking at the other.)
  ///
  /// The replacements clear 4.5:1 against **both** light grounds text
  /// actually lands on — [card] and [screen] — [muted] with margin, [faint]
  /// essentially at the floor (`#7C7C8C`, the first value tried for it,
  /// reaches only 4.10:1 / 3.80:1 and was rejected):
  ///
  /// | token   | on [card] `#FFFFFF` | on [screen] `#F6F6F8` | on [sunk] `#F1F1F5` |
  /// |---------|--------------------:|----------------------:|--------------------:|
  /// | [ink2]  |             10.88:1 |               10.08:1 |              9.66:1 |
  /// | [muted] |              5.24:1 |                4.85:1 |              4.65:1 |
  /// | [faint] |              4.94:1 |                4.58:1 |              4.39:1 |
  ///
  /// So: **do not lighten either of these back toward the spec values, and
  /// do not "tidy" them to rounder hex.** Any change here has to be
  /// re-measured; `test/theme/contrast_test.dart` fails if it is not.
  ///
  /// Two consequences worth knowing before editing:
  /// - [faint] on [sunk] lands at 4.39:1, under AA. All four call sites
  ///   that put the pair together are decorative glyphs, where WCAG
  ///   1.4.11's 3:1 non-text bar applies instead:
  ///   `shared/widgets/listing_photo.dart`'s broken-image placeholder,
  ///   `shared/widgets/agent_avatar.dart`'s silhouette,
  ///   `features/listing_detail/widgets/listing_location_section.dart`'s
  ///   `location_off` icon on the no-coordinates panel, and
  ///   `features/listing_detail/widgets/listing_agent_row.dart`'s
  ///   `person_off` icon in the unavailable-agent avatar slot. (The last
  ///   two were missed by the pass that first wrote this list — grep
  ///   `colors.sunk` *and* `colors.faint` in a file, not just the two
  ///   shared widgets.) No *text* is painted [faint]-on-[sunk] anywhere in
  ///   `lib/`. Keep it that way.
  /// - AA's floor on [screen] sits at roughly `#71717F`, which leaves
  ///   [muted] and [faint] only four steps per channel apart — in light
  ///   mode they now read as effectively one tier, not two. The
  ///   [ink] → [ink2] → ([muted]/[faint]) hierarchy survives; the
  ///   [muted]/[faint] *distinction* does not, and restoring it needs a
  ///   design decision (darkening [muted] to ~`#5C5C6B`, 5.9:1/5.5:1), not
  ///   a contrast one. Deliberately not made here.
  static const light = LaCasaColors(
    ink: Color(0xFF15151B),
    ink2: Color(0xFF3C3C47),
    muted: Color(0xFF6B6B7A),
    faint: Color(0xFF6F6F7E),
    screen: Color(0xFFF6F6F8),
    card: Color(0xFFFFFFFF),
    sunk: Color(0xFFF1F1F5),
    line: Color(0x14181626), // rgba(24,22,38,.08)
    pill: Color(0xFF15151B),
    pillInk: Color(0xFFFFFFFF),
    // 1.64:1 on card, 1.52:1 on screen, 1.46:1 on sunk — under the filled
    // star's 2.07 / 1.92 / 1.84 and well under the active dot's (accent)
    // 3.41 / 3.16, which is the point. See [glyphTrack].
    glyphTrack: Color(0xFFC9C9D4),
  );

  /// The dark palette.
  ///
  /// The spec's values, with the one exception [faint] notes below. [muted]
  /// `#8D8D9E` clears AA on every dark ground (5.41:1 on [card], 5.94:1 on
  /// [screen], 5.67:1 on [sunk]).
  ///
  /// **[faint] deviates from the spec's `#6D6D7E`, and like its light
  /// counterpart it is a contrast floor rather than a free choice.** The
  /// spec value measures 3.48:1 / 3.82:1 / 3.64:1 on [card] / [screen] /
  /// [sunk] — the identical class of defect [light] carried, on the same
  /// token, at the same call sites. Those call sites are text, not
  /// decoration: input hints in every `TextField` in the app, `micro`
  /// timestamps on lead / notification / agent rows, `bodySmall`
  /// empty-state and photo-limits copy, inactive step labels in the listing
  /// editor, and the placeholder value of every unset picker field. WCAG's
  /// inactive-component exemption covers none of that, so exempting the
  /// token was never defensible — it had to be lightened.
  ///
  /// `#818192` is the value that clears AA on **all three** dark grounds:
  ///
  /// | token   | on [card] `#181820` | on [screen] `#0D0D13` | on [sunk] `#13131A` |
  /// |---------|--------------------:|----------------------:|--------------------:|
  /// | [muted] |              5.41:1 |                5.94:1 |              5.67:1 |
  /// | [faint] |              4.61:1 |                5.06:1 |              4.83:1 |
  ///
  /// Note [sunk] too: unlike light mode, dark [faint]-on-[sunk] needs no
  /// documented exception, so the four decorative-glyph sites listed under
  /// [light] are safe in dark without being special-cased.
  ///
  /// `#7F7F90` — the value an earlier comment here proposed — is **not**
  /// enough: it reaches only 4.487:1 on [card], which rounds to "4.49" and
  /// reads like a pass while failing the assertion. Do not restore it, and
  /// do not darken this back toward the spec; `test/theme/contrast_test
  /// .dart` re-measures on every run.
  ///
  /// Same caveat as [light]: [muted] and [faint] are now close enough
  /// (5.41 vs 4.61 on [card]) that the two tiers read as one. Restoring a
  /// visible step means *lightening* [muted], which is a design decision,
  /// not a contrast one, and is deliberately not made here.
  static const dark = LaCasaColors(
    ink: Color(0xFFF1F1F6),
    ink2: Color(0xFFC5C5D2),
    muted: Color(0xFF8D8D9E),
    faint: Color(0xFF818192),
    screen: Color(0xFF0D0D13),
    card: Color(0xFF181820),
    sunk: Color(0xFF13131A),
    line: Color(0x14FFFFFF), // rgba(255,255,255,.08)
    pill: Color(0xFFF1F1F6),
    pillInk: Color(0xFF14141A),
    // 2.03:1 on card, 2.23:1 on screen, 2.13:1 on sunk — under the filled
    // star's 8.52 / 9.36 / 8.93 and the active dot's (accent) 5.68 on
    // screen. See [glyphTrack].
    glyphTrack: Color(0xFF4A4A5A),
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
    Color? glyphTrack,
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
      glyphTrack: glyphTrack ?? this.glyphTrack,
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
      glyphTrack: Color.lerp(glyphTrack, other.glyphTrack, t)!,
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

/// The ink painted **on top of `GlassVariant.onPhoto`** — the one glass
/// variant with no themed counterpart.
///
/// `GlassTheme._onPhoto` (`theme/glass_theme_extension.dart`) is a single
/// constant shared by [LaCasaColors.light] and [LaCasaColors.dark], because
/// what sits under it is a photograph rather than app chrome and a
/// photograph does not change when the app theme does. Anything painted on
/// it therefore has to be fixed too, and every over-photo overlay in the app
/// had independently arrived at a hardcoded `Colors.white`: the Sale/Rent
/// badge (`shared/widgets/full_listing_card.dart`,
/// `shared/widgets/row_listing_card.dart`), `listing-detail`'s hero counter
/// and district line, `shared/widgets/favourite_button.dart`'s heart, and
/// `map-view`'s chrome.
///
/// [PricePill] was the sole exception — it read `colors.ink`, which in light
/// mode is `#15151B` and, over a photo the cards darken by 35–42% under a
/// 15%-*white* veil, falls toward ~1.2:1 while sitting 10dp from a white
/// badge on the identical glass. Naming the value here rather than leaving a
/// seventh literal `Colors.white` in a widget file is what makes "over-photo
/// ink is fixed, not themed" a rule a reviewer can find, instead of a
/// coincidence six files happen to share.
///
/// **Do not make this a [LaCasaColors] field.** A field would be themed by
/// construction — two palettes, two values — which is precisely the mistake
/// it exists to prevent.
abstract final class AppOnPhoto {
  /// The fixed foreground for text and glyphs over `GlassVariant.onPhoto`.
  static const Color ink = Color(0xFFFFFFFF);

  /// Insurance for an **undarkened** bright photo. Both listing cards paint
  /// a gradient scrim under their overlays, so on those two callers this is
  /// invisible; a shared over-photo widget cannot assume every future caller
  /// does the same, and a 1dp/4dp black shadow at 40% costs nothing on a
  /// dark ground while keeping white glyphs separated from a white one.
  static const Shadow inkShadow = Shadow(
    color: Color(0x66000000),
    blurRadius: 4,
    offset: Offset(0, 1),
  );
}

/// The one disabled treatment, so the app stops having three.
///
/// ## Why this is a rule and not a per-widget choice
///
/// Every disabled state in this app was a bare [Opacity] over whichever
/// live state applied — 0.4 on the shared choice chips, 0.55 on
/// `publish-status`'s OLX row, 0.6 on the listing wizard's footer button.
/// [Opacity] is the wrong instrument for all three, for one reason: it
/// scales the *whole* control uniformly toward the background, so the part
/// that suffers most is the text — and the text is what says why the
/// control is disabled. `publish-status` dims the words "Not available on
/// mobile" to roughly 1.9:1 in the same wash that dims the row they
/// explain; the wizard footer keeps the full accent gradient and glow at
/// 0.6, so "can't continue" and "continue" look nearly identical on the
/// control that gates listing creation.
///
/// The rule the UX audit (§10.5) states, and this class exists to make
/// mechanical: **dim the affordance, never the reason.** A disabled control
/// drops the signals that promise a response — the glass lens, the fill,
/// the gradient, the shadow — and keeps its label at a legible contrast.
/// Pair every use with `Semantics(enabled: false, button: true)`: none of
/// the three sites exposed disabled-ness to a screen reader at all, so
/// assistive tech announced an ordinary control and then did nothing when
/// it was activated.
///
/// ## Why the label is [LaCasaColors.muted], not [LaCasaColors.faint]
///
/// Light [LaCasaColors.faint] on light [LaCasaColors.sunk] is 4.39:1 — the
/// single sub-AA pairing in this palette, sanctioned in
/// `test/theme/contrast_test.dart` for **decorative glyphs only**, with
/// [LaCasaColors.light]'s own doc comment recording the rule that no *text*
/// is painted that way anywhere in `lib/`. A disabled control's label is
/// text, and specifically the text this treatment exists to protect.
/// [LaCasaColors.muted] clears 4.65:1 on [LaCasaColors.sunk] and sits a
/// visible tier below [LaCasaColors.ink] in both brightnesses.
///
/// These are functions over the active palette rather than flat constants
/// (unlike [AppOnPhoto], whose whole point is that it is *not* themed):
/// a disabled control still sits on app chrome, so it still follows the
/// theme.
abstract final class AppDisabled {
  /// The recessed fill + hairline a disabled control takes in place of its
  /// live decoration. Use with [AppRadii] to match whatever shape the live
  /// control has; pass the same `padding` deflated by 1dp per side so the
  /// hairline does not change the control's measured size.
  static BoxDecoration decoration(
    LaCasaColors colors, {
    required BorderRadius borderRadius,
  }) {
    return BoxDecoration(
      color: colors.sunk,
      borderRadius: borderRadius,
      border: Border.all(color: colors.line),
    );
  }

  /// The foreground for a disabled control's own label.
  static Color label(LaCasaColors colors) => colors.muted;

  /// The foreground for the *explanation* beside or beneath a disabled
  /// control — "Not available on mobile", "Fill in the required fields to
  /// continue". Deliberately a tier **brighter** than [label]: the reason is
  /// the one thing on a disabled control that has to be read, and dimming it
  /// with the affordance is the exact defect §10.5 names. Render it at full
  /// opacity, outside whatever treatment the control itself takes.
  static Color reason(LaCasaColors colors) => colors.ink2;
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

  /// Rating star — icon-only, no background chip. This is the **filled**
  /// star; its unfilled partner is themed and lives at
  /// [LaCasaColors.glyphTrack], which must stay lower-contrast than this on
  /// every ground or the control reads inverted.
  static const Color ratingStar = Color(0xFFE8A92C);
}
