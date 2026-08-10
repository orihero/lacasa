/// Furniture and Repair — the two fields SCREENS.md gives a stated
/// **default** (`withFurniture`, `notRepaired`). That default is applied
/// by `FilterSheet._seedDefaults` (on first open / after Reset), not
/// here — this widget just renders whatever value it's handed, including
/// `null` if the user has explicitly deselected back to "any" (tapping
/// the already-selected chip again — see `filter_choice_chip_group.dart`).
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FieldLabel('Furniture'),
        ChoiceChipGroup<Furniture>(
          keyPrefix: 'filterFurniture',
          options: filterFurnitureOptions,
          selected: furniture,
          onChanged: onFurnitureChanged,
        ),
        const SizedBox(height: 14),
        const FieldLabel('Repair'),
        ChoiceChipGroup<Repairment>(
          keyPrefix: 'filterRepair',
          options: filterRepairOptions,
          selected: repairment,
          onChanged: onRepairmentChanged,
        ),
      ],
    );
  }
}
