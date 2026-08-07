/// Rooms — single-select chip group, `1`–`6`, unset by default.
library;

import 'package:flutter/material.dart';

import '../data/filter_options.dart';
import 'filter_choice_chip_group.dart';
import 'filter_field_label.dart';

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
        const FilterFieldLabel('Rooms'),
        FilterChoiceChipGroup<int>(
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
