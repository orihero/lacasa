/// Category (Rent/Sale) and Type (Residential/Nonresidential) — two
/// independent single-select chip groups, no stated default per
/// SCREENS.md (unlike Furniture/Repair below), so both start unset
/// ("any").
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
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
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(l10n.filterCategoryFieldLabel),
        ChoiceChipGroup<AdCategory>(
          keyPrefix: 'filterCategory',
          options: filterCategoryOptions(l10n),
          selected: category,
          onChanged: onCategoryChanged,
        ),
        // `.field{margin-top:15px}` — Category→Type is the same field gap as
        // Type→Rooms, even though that one is the parent sheet's to draw.
        const SizedBox(height: AppSpacing.field),
        FieldLabel(l10n.filterTypeFieldLabel),
        ChoiceChipGroup<AdType>(
          keyPrefix: 'filterType',
          options: filterTypeOptions(l10n),
          selected: type,
          onChanged: onTypeChanged,
        ),
      ],
    );
  }
}
