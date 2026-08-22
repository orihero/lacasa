/// The `.selbox` tap-to-pick field — a `GlassVariant.flatForm` surface the
/// same height (52) and radius (18) as [FilterTextField], but read-only: a
/// caret replaces the text cursor as the "this opens something" affordance,
/// and tapping it opens `showFilterOptionPicker`.
///
/// Lifted out of `filter_city_district_section.dart` (where it was private)
/// once Min/Max price became select boxes too — the mockup's `filter-sheet`
/// renders City, District, Min price and Max price as four identical
/// `.selbox`es, so they should be one widget, not two lookalikes.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class FilterPickerField extends StatelessWidget {
  const FilterPickerField({
    super.key,
    required this.value,
    required this.placeholder,
    required this.enabled,
    this.onTap,
    this.onRetry,
  });

  final String? value;
  final String placeholder;
  final bool enabled;
  final VoidCallback? onTap;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Opacity(
      opacity: enabled ? 1 : 0.5,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled ? onTap : onRetry,
        child: GlassSurface(
          variant: GlassVariant.flatForm,
          borderRadius: BorderRadius.circular(AppRadii.control),
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          // `.inp,.ta,.selbox{height:52px}` — every control in this sheet is
          // the same height.
          height: 52,
          child: Row(
            children: [
              Expanded(
                child: Text(
                  value ?? placeholder,
                  overflow: TextOverflow.ellipsis,
                  style: type.body.copyWith(
                    color: value == null ? colors.faint : colors.ink,
                  ),
                ),
              ),
              Icon(
                onRetry != null
                    ? Icons.refresh_rounded
                    : Icons.unfold_more_rounded,
                size: 15,
                color: colors.muted,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
