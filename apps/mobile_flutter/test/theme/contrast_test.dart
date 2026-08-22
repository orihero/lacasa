// Locks the neutral text ramp in `lib/theme/app_colors.dart` to WCAG 2.1 AA.
//
// Worth knowing why this exists rather than a design review: the light and
// dark palettes are independent constant lists, so a token can be perfectly
// legible in one brightness and fail badly in the other, and whichever build
// a reviewer happens to be looking at is the only one they see. That is
// exactly how `light.muted` (#82828F, 3.79:1 on white) and `light.faint`
// (#A2A2AE, 2.53:1) shipped: dark `muted` measures 5.41:1, so a dark-mode
// screenshot review passes them both. A contrast ratio is not something eyes
// can be trusted to judge, so it is computed here instead. The reverse case
// then showed up immediately: `dark.faint` (#6D6D7E, 3.48:1 on dark `card`)
// was the identical defect pointing the other way, and it survived the pass
// that fixed light mode. Both are now real assertions, not notes.
//
// **Every pairing is asserted exactly once.** A pair that appears both in the
// generated 4.5:1 groups and in [_documentedExceptions] at a lower floor does
// not "document" anything — it just fails in one place and passes in the
// other. If you add an exception, remove the pair from the generator (see
// `_pairsFor`'s `except`), and vice versa.
//
// This is a pure-math test — it neither pumps a widget nor reads a theme off
// a `BuildContext`, so it needs no repository-provider override and fires no
// HTTP. It reads the two palette constants directly.
//
// **Scope: the neutral text ramp only.** `AppStatusColors`' chip pairs
// (`successText` on `successBg`, and its four siblings) are *not* asserted
// here. They are translucent fills whose effective background depends on what
// is behind the chip, and once composited over the light grounds they measure
// 2.74:1–3.79:1 at `caption`'s 9.5px — a real, separate AA defect with a much
// wider blast radius than the neutral ramp. Left for its own change rather
// than smuggled in here as an exclusion.
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:lacasa_mobile/theme/app_colors.dart';

/// WCAG 2.1 §1.4.3: the minimum ratio for text below the large-text
/// threshold (18pt / 14pt bold). Every role in `LaCasaTypography` that takes
/// one of these colors is 9.25–12.75px, so this is the bar that applies —
/// there is no large secondary text in this app.
const double _aaBodyMinimum = 4.5;

/// WCAG 2.1 §1.4.11: the minimum ratio for non-text graphics that convey
/// meaning. Used only by [_documentedExceptions] below.
const double _nonTextMinimum = 3.0;

/// The sRGB → linear transfer function from the WCAG relative-luminance
/// definition. [channel] is already normalised to 0.0–1.0 by `dart:ui`'s
/// [Color] accessors, so there is no /255 step here.
double _linearise(double channel) {
  return channel <= 0.03928
      ? channel / 12.92
      : math.pow((channel + 0.055) / 1.055, 2.4).toDouble();
}

/// WCAG relative luminance: `0.2126R + 0.7152G + 0.0722B` over linearised
/// channels.
double _relativeLuminance(Color color) {
  // A translucent foreground or ground has no single ratio — it depends on
  // whatever is behind it — so refuse to produce a number that would look
  // authoritative and be wrong. Every token this file enumerates is opaque;
  // `LaCasaColors.line` (the one alpha-carrying token) is a hairline border,
  // not a text or ground color, and is deliberately not enumerated.
  expect(
    color.a,
    1.0,
    reason: 'contrast is only defined here for opaque tokens; $color is not',
  );
  return 0.2126 * _linearise(color.r) +
      0.7152 * _linearise(color.g) +
      0.0722 * _linearise(color.b);
}

/// WCAG contrast ratio: `(Llighter + 0.05) / (Ldarker + 0.05)`.
double _contrastRatio(Color foreground, Color background) {
  final a = _relativeLuminance(foreground);
  final b = _relativeLuminance(background);
  final lighter = a > b ? a : b;
  final darker = a > b ? b : a;
  return (lighter + 0.05) / (darker + 0.05);
}

/// One sanctioned (foreground, background) pairing, the floor it must clear,
/// and where in `lib/` it renders — so a failure names the screens it breaks
/// rather than just two hex values.
typedef _Pairing = ({
  String name,
  Color foreground,
  Color background,
  double minimum,
  String rendersAt,
});

/// Every pairing of a `LaCasaColors` text/icon token with a `LaCasaColors`
/// ground that `lib/` actually paints.
///
/// Built by reading the call sites, not by taking the cartesian product:
/// `card`, `screen` and `sunk` are the three opaque grounds text lands on
/// (`GlassSurface` is translucent and sits over one of them, so it resolves
/// to a tint of whichever it covers rather than a fourth ground), and
/// `pillInk` on `pill` is the one non-neutral pairing in the extension.
///
/// [brightness] is a [Brightness], not a string, because one of the
/// exclusions below is brightness-dependent and a stringly-typed flag there
/// is exactly the kind of thing that silently stops matching. Test names
/// still read "light …" / "dark …" via [Brightness.name].
List<_Pairing> _pairsFor(LaCasaColors c, {required Brightness brightness}) {
  final label = brightness.name;
  final grounds = <String, Color>{
    'card': c.card,
    'screen': c.screen,
    'sunk': c.sunk,
  };

  final pairings = <_Pairing>[];

  void addAcrossGrounds(
    String name,
    Color foreground,
    String rendersAt, {
    Set<String> except = const <String>{},
  }) {
    grounds.forEach((groundName, ground) {
      if (except.contains(groundName)) return;
      pairings.add((
        name: '$label $name on $groundName',
        foreground: foreground,
        background: ground,
        minimum: _aaBodyMinimum,
        rendersAt: rendersAt,
      ));
    });
  }

  addAcrossGrounds(
    'ink',
    c.ink,
    'every primary title and body string in the app',
  );
  addAcrossGrounds(
    'ink2',
    c.ink2,
    'secondary paragraph copy — empty-state messages, sheet body text, '
        'avatar initials',
  );
  addAcrossGrounds(
    'muted',
    c.muted,
    'listing-card location and spec lines (shared/widgets/'
        'full_listing_card.dart, compact_listing_card.dart), the "View all" '
        'link (shared/widgets/section_header.dart), uppercase field labels, '
        'chart axis labels, both dashboard legends, and the mute-tone '
        'StatusPill label on sunk',
    // Unselected tab icons used to be listed here and are deliberately not
    // any more: navigation/shell/glass_tab_bar.dart paints them `ink2`,
    // because `muted` on that bar's glass falls to ~1.2:1 over a dark photo.
    // Naming `muted` as their token here is what would re-seed that bug.
  );

  // `faint` skips `sunk` **in light only** — the exclusion is brightness-
  // aware on purpose. Light `faint`-on-`sunk` is 4.39:1 and is carried at
  // the non-text floor in [_documentedExceptions] because all four of its
  // call sites are decorative glyphs. Dark `faint`-on-`sunk` is 4.83:1 and
  // is a plain pass, so excluding it here would hide a real assertion; and
  // while the exclusion was brightness-blind, the two *other* dark `faint`
  // rows were generated here at 4.5:1 **and** listed as exceptions at 3:1,
  // i.e. asserted twice at two different bars.
  addAcrossGrounds(
    'faint',
    c.faint,
    'input hint text, `micro` timestamps on lead/agent rows, empty-state and '
        'limits copy (features/listing_editor/widgets/form/photos_step.dart), '
        'inactive step labels (…/form/step_indicator.dart)',
    except: brightness == Brightness.light ? const {'sunk'} : const <String>{},
  );

  pairings.add((
    name: '$label pillInk on pill',
    foreground: c.pillInk,
    background: c.pill,
    minimum: _aaBodyMinimum,
    rendersAt:
        'the selected chip/tab/segment label (features/leads/widgets/'
        'leads_kanban_screen.dart, features/auth/widgets/auth_form_widgets.'
        'dart)',
  ));

  return pairings;
}

/// Pairings that sit below [_aaBodyMinimum], each with the reason and the
/// place it renders. Asserted at the reduced floor rather than omitted, so a
/// regression past *that* still fails.
///
/// **There is exactly one**, and it is a justified WCAG 1.4.11 exemption, not
/// a parking space for known failures. The three `dark faint` rows that used
/// to sit here were the latter: `dark.faint` renders the same informational
/// text light `faint` does, so 4.5:1 was always the applicable bar, and
/// holding them at 3:1 here while `_pairsFor` simultaneously generated two of
/// them at 4.5:1 meant the file asserted both bars at once and failed. They
/// were resolved by lightening the token (#6D6D7E → #818192), which is what
/// "the fix is to lighten it" in the old note meant; see
/// `LaCasaColors.dark`. Do not re-add a row here to silence a text pairing.
final List<_Pairing> _documentedExceptions = <_Pairing>[
  (
    name: 'light faint on sunk',
    foreground: LaCasaColors.light.faint,
    background: LaCasaColors.light.sunk,
    minimum: _nonTextMinimum,
    // 4.39:1. No text is painted faint-on-sunk anywhere in `lib/` — all four
    // call sites that put the pair together are decorative glyphs standing in
    // for content that is absent: the 28px broken-image icon in
    // `shared/widgets/listing_photo.dart`, the person silhouette in
    // `shared/widgets/agent_avatar.dart`, the `location_off` icon on
    // `features/listing_detail/widgets/listing_location_section.dart`'s
    // no-coordinates panel, and the `person_off` icon in the avatar slot of
    // `features/listing_detail/widgets/listing_agent_row.dart`'s
    // unavailable-agent row. (The last two were missed when this list was
    // first written — it is `colors.sunk` + `colors.faint` in the same
    // widget, not just the two shared ones.) All are non-text graphics under
    // WCAG 1.4.11, so 3:1 is the applicable bar; the *text* beside each of
    // them is `muted`, which clears 4.65:1 on `sunk`. If a `Text` is ever
    // given `faint` on a `sunk` container, move this back up.
    rendersAt:
        'decorative placeholder glyphs only — shared/widgets/'
        'listing_photo.dart, shared/widgets/agent_avatar.dart, '
        'features/listing_detail/widgets/listing_location_section.dart, '
        'features/listing_detail/widgets/listing_agent_row.dart',
  ),
];

void main() {
  const palettes = <Brightness, LaCasaColors>{
    Brightness.light: LaCasaColors.light,
    Brightness.dark: LaCasaColors.dark,
  };

  // Guards the formula itself. Without this, a bug in `_linearise` that
  // inflated every ratio would make the whole file pass vacuously.
  group('WCAG formula', () {
    test('black on white is 21:1 and a color against itself is 1:1', () {
      expect(
        _contrastRatio(const Color(0xFF000000), const Color(0xFFFFFFFF)),
        closeTo(21, 0.01),
      );
      expect(
        _contrastRatio(const Color(0xFF808080), const Color(0xFF808080)),
        closeTo(1, 0.001),
      );
    });

    test('is symmetric in its arguments', () {
      const a = Color(0xFF6B6B7A);
      const b = Color(0xFFF6F6F8);
      expect(_contrastRatio(a, b), closeTo(_contrastRatio(b, a), 0.000001));
    });
  });

  palettes.forEach((brightness, palette) {
    group('${brightness.name} palette', () {
      for (final pairing in _pairsFor(palette, brightness: brightness)) {
        test('${pairing.name} clears ${pairing.minimum}:1', () {
          final ratio = _contrastRatio(pairing.foreground, pairing.background);
          expect(
            ratio,
            greaterThanOrEqualTo(pairing.minimum),
            reason:
                '${pairing.name} measures ${ratio.toStringAsFixed(2)}:1, under '
                'the ${pairing.minimum}:1 floor. It renders at: '
                '${pairing.rendersAt}.',
          );
        });
      }
    });
  });

  group('documented exceptions', () {
    for (final pairing in _documentedExceptions) {
      test('${pairing.name} holds at ${pairing.minimum}:1', () {
        final ratio = _contrastRatio(pairing.foreground, pairing.background);
        expect(
          ratio,
          greaterThanOrEqualTo(pairing.minimum),
          reason:
              '${pairing.name} measures ${ratio.toStringAsFixed(2)}:1, under '
              'even the reduced ${pairing.minimum}:1 floor. Context: '
              '${pairing.rendersAt}.',
        );
      });
    }
  });

  // `glyphTrack` is the one token here whose requirement is an *upper* bound.
  // It paints the "off" half of a two-state glyph pair — the unfilled star in
  // `shared/widgets/rating_stars.dart` and `features/agents/widgets/
  // rating_input.dart`, the inactive dot in `features/onboarding/widgets/
  // onboarding_screen.dart` — so what matters is not that it clears a floor
  // but that it stays *quieter than the "on" half*. It exists because these
  // call sites used to borrow `faint`, and the moment `faint` was raised to a
  // 4.5:1 text floor the empty stars (4.94:1 on white) drowned out the filled
  // ones (2.07:1) and the inactive dots (4.58:1 on `screen`) drowned out the
  // active one (3.16:1). Both controls read inverted — the bug this group
  // makes impossible to reintroduce silently.
  //
  // Note what is deliberately NOT asserted: 1.4.11's 3:1. The filled star
  // itself is 2.07:1 on white, so pushing the empty one to 3:1 would restore
  // the inversion. That the *filled* star fails 1.4.11 is a real defect in
  // `AppStatusColors`, out of this file's stated scope (see the header) and
  // not fixable from the empty side.
  group('glyphTrack stays quieter than the glyph it pairs with', () {
    const pairs = <String, ({LaCasaColors palette, Color on})>{
      'light star': (
        palette: LaCasaColors.light,
        on: AppStatusColors.ratingStar,
      ),
      'dark star': (palette: LaCasaColors.dark, on: AppStatusColors.ratingStar),
      'light dot': (palette: LaCasaColors.light, on: AppAccent.color),
      'dark dot': (palette: LaCasaColors.dark, on: AppAccent.color),
    };

    pairs.forEach((name, pair) {
      test('$name: off-state reads weaker than on-state on every ground', () {
        final grounds = <String, Color>{
          'card': pair.palette.card,
          'screen': pair.palette.screen,
          'sunk': pair.palette.sunk,
        };

        grounds.forEach((groundName, ground) {
          final off = _contrastRatio(pair.palette.glyphTrack, ground);
          final on = _contrastRatio(pair.on, ground);
          expect(
            off,
            lessThan(on),
            reason:
                '$name on $groundName: the off glyph measures '
                '${off.toStringAsFixed(2)}:1 and the on glyph '
                '${on.toStringAsFixed(2)}:1, so the inactive state is the '
                'louder one and the control reads backwards.',
          );
        });
      });
    });
  });

  // The three-tier read the palette is built on. Raising `muted`/`faint` for
  // contrast must not flatten them into `ink2`, and must not invert the ramp.
  group('light neutral ramp keeps its ordering', () {
    test('ink is darker than ink2, which is darker than muted then faint', () {
      final ink = _relativeLuminance(LaCasaColors.light.ink);
      final ink2 = _relativeLuminance(LaCasaColors.light.ink2);
      final muted = _relativeLuminance(LaCasaColors.light.muted);
      final faint = _relativeLuminance(LaCasaColors.light.faint);

      expect(ink, lessThan(ink2));
      expect(ink2, lessThan(muted));
      expect(muted, lessThan(faint));
    });

    test('ink2 stays a visible step above the secondary tokens', () {
      // Not just a measurable step: on white, `ink2` reads at ~10.9:1 against
      // `muted`'s ~5.2:1, and it is that gap — not the raw hex distance —
      // that makes a title separate from its caption.
      final ink2 = _contrastRatio(
        LaCasaColors.light.ink2,
        LaCasaColors.light.card,
      );
      final muted = _contrastRatio(
        LaCasaColors.light.muted,
        LaCasaColors.light.card,
      );
      expect(ink2 / muted, greaterThan(1.5));
    });
  });

  // The same guard for dark, added when `dark.faint` was lightened to clear
  // AA. That move pushed `faint` (luminance .224) toward `muted` (.272) — the
  // ramp survives, but there is now little room left, and lightening `faint`
  // any further would cross `muted` and invert the two tiers outright. In
  // dark the ordering is reversed from light: higher luminance is the
  // *stronger* tier, because the grounds are dark.
  group('dark neutral ramp keeps its ordering', () {
    test(
      'ink is lighter than ink2, which is lighter than muted then faint',
      () {
        final ink = _relativeLuminance(LaCasaColors.dark.ink);
        final ink2 = _relativeLuminance(LaCasaColors.dark.ink2);
        final muted = _relativeLuminance(LaCasaColors.dark.muted);
        final faint = _relativeLuminance(LaCasaColors.dark.faint);

        expect(ink, greaterThan(ink2));
        expect(ink2, greaterThan(muted));
        expect(muted, greaterThan(faint));
      },
    );
  });
}
