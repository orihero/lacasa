/// Rooms — single-select chip group, `1`–`6`, unset by default.
library;

import 'package:flutter/material.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../data/filter_options.dart';

class FilterRoomsSection extends StatelessWidget {
  const FilterRoomsSection({
    super.key,
    required this.rooms,
    required this.onChanged,
  });

  final int? rooms;
  final ValueChanged<int?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        FieldLabel(AppLocalizations.of(context).filterRoomsFieldLabel),
        ChoiceChipGroup<int>(
          keyPrefix: 'filterRooms',
          options: [
            for (final n in filterRoomOptions) FilterOption(n, '$n'),
          ],
          selected: rooms,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
