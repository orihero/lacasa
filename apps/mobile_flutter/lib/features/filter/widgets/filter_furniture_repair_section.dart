/// Furniture and Repair — the two fields SCREENS.md gives a stated
/// **default** (`withFurniture`, `notRepaired`). That default is applied
/// by `FilterSheet._seedDefaults` (on first open / after Reset), not
/// here — this widget just renders whatever value it's handed, including
/// `null` if the user has explicitly deselected back to "any" (tapping
/// the already-selected chip again — see `filter_choice_chip_group.dart`).
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../data/filter_options.dart';

class FilterFurnitureRepairSection extends StatelessWidget {
  const FilterFurnitureRepairSection({
    super.key,
    required this.furniture,
    required this.repairment,
    required this.onFurnitureChanged,
    required this.onRepairmentChanged,
  });

  final Furniture? furniture;
  final Repairment? repairment;
  final ValueChanged<Furniture?> onFurnitureChanged;
  final ValueChanged<Repairment?> onRepairmentChanged;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(l10n.filterFurnitureFieldLabel),
        ChoiceChipGroup<Furniture>(
          keyPrefix: 'filterFurniture',
          options: filterFurnitureOptions(l10n),
          selected: furniture,
          onChanged: onFurnitureChanged,
        ),
        const SizedBox(height: 14),
        FieldLabel(l10n.filterRepairFieldLabel),
        ChoiceChipGroup<Repairment>(
          keyPrefix: 'filterRepair',
          options: filterRepairOptions(l10n),
          selected: repairment,
          onChanged: onRepairmentChanged,
        ),
      ],
    );
  }
}
