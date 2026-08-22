/// Furniture and Repair — the two fields SCREENS.md §3.5 gives a stated
/// **default** (`withFurniture`, `notRepaired`). Nothing applies those
/// defaults on this screen: the sheet seeds itself from its caller's
/// filters verbatim and Reset clears both to `null`, so on a fresh open
/// *neither* group has a lit chip (see `filter_sheet.dart`'s library doc
/// comment, "No invented defaults", for why a search filter must not
/// pre-select constraints the buyer never chose). This widget only ever
/// renders whatever value it's handed — `null` included, whether because
/// the field was never touched or because the user deselected back to
/// "any" by re-tapping the lit chip (`shared/widgets/
/// choice_chip_group.dart`'s `allowDeselect`).
library;

import 'package:flutter/material.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
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
        // `.field{margin-top:15px}` — Furniture→Repair is the same field gap
        // the parent sheet draws between every other pair of fields.
        const SizedBox(height: AppSpacing.field),
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
