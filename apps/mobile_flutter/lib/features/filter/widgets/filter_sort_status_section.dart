/// Sort + Status — the two fields SCREENS.md §3.5 appends to the CRM
/// variant of `filter-sheet` only (`my-listings`, `isCrm: true`). Same
/// single-select chip shape as every other field in this sheet
/// (`filter_choice_chip_group.dart`), just two independent groups stacked
/// under one heading pair rather than one — mirrors
/// `filter_category_type_section.dart`'s own two-groups-in-one-section
/// shape exactly.
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import '../data/filter_options.dart';

class FilterSortStatusSection extends StatelessWidget {
  const FilterSortStatusSection({
    super.key,
    required this.sort,
    required this.status,
    required this.onSortChanged,
    required this.onStatusChanged,
  });

  final AdSort sort;
  final AdStage? status;
  final ValueChanged<AdSort?> onSortChanged;
  final ValueChanged<AdStage?> onStatusChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Sort'),
        ChoiceChipGroup<AdSort>(
          keyPrefix: 'filterCrmSort',
          options: filterCrmSortOptions,
          selected: sort,
          // Sort always has a value (`AdSort.newest` is the "no sort
          // param sent" sentinel, not a null/"any" state — see that
          // enum's own doc comment), so a re-tap of the already-selected
          // chip is a no-op rather than clearing to null.
          onChanged: (value) => onSortChanged(value ?? AdSort.newest),
        ),
        const SizedBox(height: 14),
        const FieldLabel('Status'),
        ChoiceChipGroup<AdStage>(
          keyPrefix: 'filterCrmStatus',
          options: filterCrmStatusOptions,
          selected: status,
          onChanged: onStatusChanged,
        ),
      ],
    );
  }
}
