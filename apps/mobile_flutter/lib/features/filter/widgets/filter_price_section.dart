/// Min/Max price — two single-select chip groups over
/// `filterPriceLadder` (SCREENS.md §3.5's fixed 9-value ladder), not free
/// text. Mirrors `apps/web/src/components/filter/Filter.jsx`'s own
/// mutual-ordering behavior (a `priceMin` above the chosen `priceMax`, or
/// vice versa, doesn't make sense) — implemented here as disabling the
/// offending chip rather than web's approach of hiding the option
/// entirely from the `<select>`, since a disabled-but-visible chip reads
/// more clearly in this chip-based UI than an option silently missing.
///
/// `groupThousands` duplicates the digit-grouping algorithm from
/// `lib/shared/formatters/formatters.dart#Formatters._groupInteger` —
/// that method is `Ad`-shaped (`groupedPrice(Ad ad)`), not reusable for a
/// bare ladder value, and the private helper underneath it isn't exported.
/// Flagged in the build report as a second, small instance of the same
/// duplication `filter_ads_fixtures.dart` already flags.
library;

import 'package:flutter/material.dart';

import '../data/filter_options.dart';
import 'filter_choice_chip_group.dart';
import 'filter_field_label.dart';

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
    final options = [
      for (final p in filterPriceLadder) FilterOption(p, groupThousands(p)),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterFieldLabel('Min price'),
        FilterChoiceChipGroup<int>(
          keyPrefix: 'filterPriceMin',
          options: options,
          selected: priceMin,
          onChanged: onPriceMinChanged,
          isEnabled: (value) => priceMax == null || value <= priceMax!,
        ),
        const SizedBox(height: 14),
        const FilterFieldLabel('Max price'),
        FilterChoiceChipGroup<int>(
          keyPrefix: 'filterPriceMax',
          options: options,
          selected: priceMax,
          onChanged: onPriceMaxChanged,
          isEnabled: (value) => priceMin == null || value >= priceMin!,
        ),
      ],
    );
  }
}
