/// A single-select chip [Wrap]. Promoted out of two independent copies:
/// `features/filter/widgets/filter_choice_chip_group.dart`'s
/// `FilterChoiceChipGroup` (every filter field is optional — tapping the
/// already-selected chip deselects back to "any"/`null`, and a per-option
/// [ChoiceChipGroup.isEnabled] can disable a chip, originally the price
/// ladder's min/max mutual-ordering constraint) and
/// `features/listing_editor/widgets/form/
/// listing_choice_chip_group.dart`'s `ListingChoiceChipGroup` (real [Ad]
/// columns — Type/Category/Repair/Furniture/Price type/Status — that
/// always have a value, so re-tapping the selected chip is a no-op, never
/// a deselect, and there is no per-option disabling).
///
/// [allowDeselect] (default `true`, matching the original
/// `FilterChoiceChipGroup` behavior every existing filter caller relies
/// on) carries that one real behavioral difference explicitly rather than
/// silently picking one side; [label] (default `null`) lets a caller like
/// Listing's get one widget per field instead of a label sibling plus a
/// bare chip row — filter sections keep rendering their own
/// [FieldLabel] beside this widget unchanged, so [label] defaults to
/// off rather than becoming a second way to do what those eight call
/// sites already do.
library;

import 'package:flutter/material.dart';

import '../../theme/theme.dart';
import 'field_label.dart';

/// One labelled value for a [ChoiceChipGroup].
class ChoiceOption<T> {
  const ChoiceOption(this.value, this.label);
  final T value;
  final String label;
}

class ChoiceChipGroup<T> extends StatelessWidget {
  const ChoiceChipGroup({
    super.key,
    this.label,
    required this.keyPrefix,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.isEnabled,
    this.allowDeselect = true,
  });

  /// When set, this widget renders its own [FieldLabel] above the chips
  /// (Listing's usage — one field, one widget). Left `null`, only the
  /// [Wrap] of chips renders and the caller supplies its own label
  /// alongside it (every Filter usage today).
  final String? label;

  /// Prefix for each chip's `ValueKey` (`'$keyPrefix-${option.value}'`) —
  /// callers should pass something unique per field (e.g. `'category'`)
  /// so widget tests can target one chip unambiguously.
  final String keyPrefix;
  final List<ChoiceOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onChanged;

  /// Optional per-option enablement. Disabled chips render in the
  /// sunk/muted/hairline treatment described on [_Chip], ignore taps, and
  /// report `enabled: false` to the semantics tree. `null` — which is every
  /// call site in `lib/` today, see [_Chip] — leaves every chip enabled.
  final bool Function(T value)? isEnabled;

  /// `true` (Filter's original behavior): tapping the already-selected
  /// chip deselects back to "any" (`onChanged(null)`). `false` (Listing's
  /// original behavior): the field always has a value, so re-tapping the
  /// selected chip calls `onChanged` with that same value again rather
  /// than clearing it.
  final bool allowDeselect;

  @override
  Widget build(BuildContext context) {
    // `.opts{display:flex;flex-wrap:wrap;gap:7px}`.
    final chips = Wrap(
      spacing: 7,
      runSpacing: 7,
      children: [
        for (final option in options)
          _Chip<T>(
            key: ValueKey('$keyPrefix-${option.value}'),
            label: option.label,
            isOn: selected == option.value,
            isEnabled: isEnabled?.call(option.value) ?? true,
            onTap: () => onChanged(
              allowDeselect && selected == option.value ? null : option.value,
            ),
          ),
      ],
    );

    final fieldLabel = label;
    if (fieldLabel == null) return chips;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [FieldLabel(fieldLabel), chips],
    );
  }
}

/// One chip.
///
/// ## Why a disabled chip is a third *state*, not the enabled one at 0.4
///
/// This used to render `Opacity(opacity: 0.4)` over whichever of the two
/// live states applied. Opacity is a poor disabled treatment for one
/// specific reason: it scales the *whole* chip toward the background
/// uniformly, so the thing that suffers most is the label — the only part
/// that says which option this is. The motivating case was the filter
/// sheet's price ladder, where a buyer who set a max of $500 watched the
/// min chips above it fade, and the fainter they got the harder it was to
/// read *which* prices had become unavailable — exactly the information the
/// disabling was trying to convey. The audit's phrasing for the whole class
/// of defect is "dim the affordance, never the reason"; see [AppDisabled],
/// which states the rule for the two non-chip call sites too.
///
/// **[ChoiceChipGroup.isEnabled] has no caller in `lib/features/` today.**
/// The price ladder moved to a picker field
/// (`features/filter/widgets/filter_price_section.dart`), which simply does
/// not offer the out-of-range values — a strictly better answer for that
/// one field. The parameter and this state stay because the group is the
/// shared single-select control and "some options are unavailable right
/// now" is a real thing a future field will need; leaving it wired to an
/// `Opacity` would mean the next caller inherits the defect. Its own test
/// (`test/shared/widgets/choice_chip_group_test.dart`) is therefore the
/// only place the contract is exercised at all.
///
/// So the disabled chip keeps a legible label and drops the *affordance*
/// signals instead: [LaCasaColors.sunk] fill (the recessed ground already
/// used for inert surfaces app-wide, e.g. `leads-kanban`'s unselected
/// column pills), a [LaCasaColors.line] hairline where the enabled chip has
/// a glass lens and the selected chip a drop shadow, and
/// [LaCasaColors.muted] for the label.
///
/// **[LaCasaColors.muted], not [LaCasaColors.faint].** The audit entry that
/// prescribed this treatment named `faint`, and that was right for the
/// palette it was written against. It is not right for this one: light
/// `faint` on light `sunk` measures 4.39:1, under AA, and
/// `LaCasaColors.light`'s own doc comment plus the one documented exception
/// in `test/theme/contrast_test.dart` both state the rule explicitly — that
/// pairing is sanctioned for decorative glyphs only, and "no *text* is
/// painted faint-on-sunk anywhere in `lib/`. Keep it that way." A disabled
/// chip's label is text, and it is the exact text this fix exists to keep
/// readable, so painting it at a sub-AA ratio would have reintroduced the
/// defect in a different colour space. `muted` clears 4.65:1 on `sunk`, and
/// in light mode the two tokens sit four steps per channel apart anyway —
/// the visual result is what the audit asked for, at a ratio that passes.
/// Either way it is a full tier more legible than the ~1.7:1 that 0.4
/// opacity produced, while still reading as clearly subordinate to both
/// live states.
///
/// ## Semantics
///
/// A disabled chip previously exposed no disabled-ness at all: the
/// [GestureDetector] simply got a null `onTap`, which is invisible to
/// TalkBack/VoiceOver — a screen-reader user heard an ordinary label,
/// double-tapped, and got silence with no explanation. Every chip is now
/// wrapped in `Semantics(button: true, enabled: …, selected: …)` so the
/// disabled ones announce as dimmed/unavailable and the selected one
/// announces as selected. `button: true` on the enabled chips is not
/// incidental either — a bare [GestureDetector] has no role at all, so
/// these read as plain text today.
class _Chip<T> extends StatelessWidget {
  const _Chip({
    super.key,
    required this.label,
    required this.isOn,
    required this.isEnabled,
    required this.onTap,
  });

  final String label;
  final bool isOn;
  final bool isEnabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final foreground = !isEnabled
        ? AppDisabled.label(colors)
        : (isOn ? colors.pillInk : colors.ink);

    // `.opt{height:38px;border-radius:19px;padding:0 15px;font-size:12px;
    // font-weight:500}` — one global rule, so both the selected (`.opt.on`,
    // the ink pill) and unselected (glass) states get the same box; only
    // the fill differs. `body` is the 12px role; the weight is the override.
    // `Align(widthFactor: 1)` rather than either box's own `alignment:`
    // property: a [Container] (and so [GlassSurface]) given an alignment
    // *expands* to its parent's width, which inside the [Wrap] above puts
    // one chip per row. This shrink-wraps the width, fills the stated 38dp
    // height, and centres the label in both.
    final content = Align(
      alignment: Alignment.center,
      widthFactor: 1,
      child: Text(
        label,
        style: type.body.copyWith(
          fontWeight: FontWeight.w500,
          color: foreground,
        ),
      ),
    );
    const padding = EdgeInsets.symmetric(horizontal: 15);

    final Widget box;
    if (!isEnabled) {
      // Sunk fill + hairline, no lens and no shadow: the two live states are
      // the ones that get depth. See this class's doc comment.
      box = Container(
        // Deflated by the border's own 1dp so a disabled chip measures
        // exactly as wide as the enabled one it replaces — a `Wrap` of price
        // options would otherwise reflow by 2dp per chip as the ladder's
        // constraint moves.
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: AppDisabled.decoration(colors, borderRadius: AppRadii.pill),
        child: content,
      );
    } else if (isOn) {
      box = Container(
        padding: padding,
        decoration: BoxDecoration(
          color: colors.pill,
          borderRadius: AppRadii.pill,
          // `.opt.on{box-shadow:0 8px 16px -8px rgba(21,21,27,.6)}`.
          boxShadow: AppShadows.selectedChip,
        ),
        child: content,
      );
    } else {
      box = GlassSurface(
        variant: GlassVariant.onSurface,
        borderRadius: AppRadii.pill,
        padding: padding,
        child: content,
      );
    }

    return Semantics(
      button: true,
      enabled: isEnabled,
      selected: isOn,
      // The label is already painted by the [Text] inside; excluding the
      // subtree would drop it, so this only adds the role/state flags.
      child: GestureDetector(
        onTap: isEnabled ? onTap : null,
        child: SizedBox(height: 38, child: box),
      ),
    );
  }
}
