/// Min/Max price — two `.selbox` picker fields side by side over
/// `filterPriceLadder` (SCREENS.md §3.5's fixed 9-value ladder: "*select*
/// from ladder"), not free text and not a chip grid. The mockup renders
/// them as one `.two` grid row of two 52px select boxes; the chip-group
/// build this replaced laid the same ladder out as 18 chips, adding several
/// hundred pixels of scroll to a sheet that is already tall.
///
/// Mirrors `apps/web/src/components/filter/Filter.jsx`'s mutual-ordering
/// behavior (a `priceMin` above the chosen `priceMax`, or vice versa,
/// doesn't make sense) — with a picker rather than chips, web's own
/// approach applies directly: the offending values are simply not offered.
///
/// `groupThousands` duplicates the digit-grouping algorithm from
/// `lib/shared/formatters/formatters.dart#Formatters._groupInteger` —
/// that method is `Ad`-shaped (`groupedPrice(Ad ad)`), not reusable for a
/// bare ladder value, and the private helper underneath it isn't exported.
/// Flagged in the build report as a second, small instance of the same
/// duplication `filter_ads_fixtures.dart` already flags.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../data/filter_options.dart';
import 'filter_option_picker_sheet.dart';
import 'filter_picker_field.dart';

String groupThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i != 0 && (digits.length - i) % 3 == 0) buffer.write(',');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}

class FilterPriceSection extends StatelessWidget {
  const FilterPriceSection({
    super.key,
    required this.priceMin,
    required this.priceMax,
    required this.onPriceMinChanged,
    required this.onPriceMaxChanged,
  });

  final int? priceMin;
  final int? priceMax;
  final ValueChanged<int?> onPriceMinChanged;
  final ValueChanged<int?> onPriceMaxChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(l10n.filterPriceMinFieldLabel),
              FilterPickerField(
                key: const ValueKey('filterField-priceMin'),
                value: priceMin == null ? null : groupThousands(priceMin!),
                placeholder: l10n.filterPriceAnyOptionLabel,
                enabled: true,
                onTap: () => _pick(
                  context,
                  title: l10n.filterPriceMinFieldLabel,
                  anyLabel: l10n.filterPriceAnyOptionLabel,
                  current: priceMin,
                  // A minimum above the chosen maximum is not offered at
                  // all — same rule web's `<select>` applies.
                  isAllowed: (value) => priceMax == null || value <= priceMax!,
                  onChanged: onPriceMinChanged,
                ),
              ),
            ],
          ),
        ),
        // `.two{gap:11px}`.
        const SizedBox(width: 11),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(l10n.filterPriceMaxFieldLabel),
              FilterPickerField(
                key: const ValueKey('filterField-priceMax'),
                value: priceMax == null ? null : groupThousands(priceMax!),
                placeholder: l10n.filterPriceAnyOptionLabel,
                enabled: true,
                onTap: () => _pick(
                  context,
                  title: l10n.filterPriceMaxFieldLabel,
                  anyLabel: l10n.filterPriceAnyOptionLabel,
                  current: priceMax,
                  isAllowed: (value) => priceMin == null || value >= priceMin!,
                  onChanged: onPriceMaxChanged,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Opens the shared option picker over the ladder and maps the picked
  /// *label* back to its ladder value. `showFilterOptionPicker` returns
  /// [current]'s own label on a dismissal, so a dismissed sheet resolves
  /// back to the same value — a no-op, not a clear.
  Future<void> _pick(
    BuildContext context, {
    required String title,
    required String anyLabel,
    required int? current,
    required bool Function(int value) isAllowed,
    required ValueChanged<int?> onChanged,
  }) async {
    final allowed = [
      for (final value in filterPriceLadder)
        if (isAllowed(value) || value == current) value,
    ];
    final labels = {for (final value in allowed) groupThousands(value): value};

    final picked = await showFilterOptionPicker(
      context,
      title: title,
      options: labels.keys.toList(),
      current: current == null ? null : groupThousands(current),
      anyLabel: anyLabel,
    );
    onChanged(picked == null ? null : labels[picked]);
  }
}
