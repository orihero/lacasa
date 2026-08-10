/// Category (Rent/Sale) and Type (Residential/Nonresidential) — two
/// independent single-select chip groups, no stated default per
/// SCREENS.md (unlike Furniture/Repair below), so both start unset
/// ("any").
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import '../data/filter_options.dart';

class FilterCategoryTypeSection extends StatelessWidget {
  const FilterCategoryTypeSection({
    super.key,
    required this.category,
    required this.type,
    required this.onCategoryChanged,
    required this.onTypeChanged,
  });

  final AdCategory? category;
  final AdType? type;
  final ValueChanged<AdCategory?> onCategoryChanged;
  final ValueChanged<AdType?> onTypeChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Category'),
        ChoiceChipGroup<AdCategory>(
          keyPrefix: 'filterCategory',
          options: filterCategoryOptions,
          selected: category,
          onChanged: onCategoryChanged,
        ),
        const SizedBox(height: 14),
        const FieldLabel('Type'),
        ChoiceChipGroup<AdType>(
          keyPrefix: 'filterType',
          options: filterTypeOptions,
          selected: type,
          onChanged: onTypeChanged,
        ),
      ],
    );
  }
}
