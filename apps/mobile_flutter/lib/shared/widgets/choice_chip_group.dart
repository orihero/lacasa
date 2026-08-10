/// A single-select chip [Wrap]. Promoted out of two independent copies:
/// `features/filter/widgets/filter_choice_chip_group.dart`'s
/// `FilterChoiceChipGroup` (every filter field is optional — tapping the
/// already-selected chip deselects back to "any"/`null`, and a per-option
/// [isEnabled] can dim+disable a chip, e.g. the price ladder's min/max
/// mutual-ordering constraint) and `features/listing_editor/widgets/form/
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

  /// Optional per-option enablement (e.g. the price ladder's min/max
  /// mutual ordering constraint — see `filter_price_section.dart`).
  /// Disabled chips render dimmed and ignore taps. `null` (every Listing
  /// call site) leaves every chip enabled.
  final bool Function(T value)? isEnabled;

  /// `true` (Filter's original behavior): tapping the already-selected
  /// chip deselects back to "any" (`onChanged(null)`). `false` (Listing's
  /// original behavior): the field always has a value, so re-tapping the
  /// selected chip calls `onChanged` with that same value again rather
  /// than clearing it.
  final bool allowDeselect;

  @override
  Widget build(BuildContext context) {
    final chips = Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
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
    final foreground = isOn ? colors.pillInk : colors.ink;

    final content = Text(label, style: type.rowTitle.copyWith(color: foreground));

    final chip = isOn
        ? Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            decoration: BoxDecoration(color: colors.pill, borderRadius: AppRadii.pill),
            alignment: Alignment.center,
            child: content,
          )
        : GlassSurface(
            variant: GlassVariant.onSurface,
            borderRadius: AppRadii.pill,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
            alignment: Alignment.center,
            child: content,
          );

    return Opacity(
      opacity: isEnabled ? 1 : 0.4,
      child: GestureDetector(onTap: isEnabled ? onTap : null, child: chip),
    );
  }
}
