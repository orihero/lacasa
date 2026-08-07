/// A single-select chip [Wrap] for an optional filter field — tapping the
/// already-selected chip deselects back to "any" (`null`). Same visual
/// contract as `features/home/widgets/category_chip_row.dart`'s chip
/// (selected = solid `colors.pill` fill, unselected = `GlassVariant
/// .onSurface` glass), duplicated here rather than imported since that
/// widget is private to `features/home/` — see this feature's build
/// report for the promotion note.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import '../data/filter_options.dart';

class FilterChoiceChipGroup<T> extends StatelessWidget {
  const FilterChoiceChipGroup({
    super.key,
    required this.keyPrefix,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.isEnabled,
  });

  /// Prefix for each chip's `ValueKey` (`'$keyPrefix-${option.value}'`) —
  /// callers should pass something unique per field (e.g. `'category'`)
  /// so widget tests can target one chip unambiguously.
  final String keyPrefix;
  final List<FilterOption<T>> options;
  final T? selected;
  final ValueChanged<T?> onChanged;

  /// Optional per-option enablement (e.g. the price ladder's min/max
  /// mutual ordering constraint — see `filter_price_section.dart`).
  /// Disabled chips render dimmed and ignore taps.
  final bool Function(T value)? isEnabled;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        for (final option in options)
          _Chip<T>(
            key: ValueKey('$keyPrefix-${option.value}'),
            label: option.label,
            isOn: selected == option.value,
            isEnabled: isEnabled?.call(option.value) ?? true,
            onTap: () =>
                onChanged(selected == option.value ? null : option.value),
          ),
      ],
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

    final content = Text(
      label,
      style: type.rowTitle.copyWith(color: foreground),
    );

    final chip = isOn
        ? Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            decoration: BoxDecoration(
              color: colors.pill,
              borderRadius: AppRadii.pill,
            ),
            alignment: Alignment.center,
            child: content,
          )
        : GlassSurface(
            variant: GlassVariant.onSurface,
            borderRadius: AppRadii.pill,
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 9,
            ),
            alignment: Alignment.center,
            child: content,
          );

    return Opacity(
      opacity: isEnabled ? 1 : 0.4,
      child: GestureDetector(onTap: isEnabled ? onTap : null, child: chip),
    );
  }
}
