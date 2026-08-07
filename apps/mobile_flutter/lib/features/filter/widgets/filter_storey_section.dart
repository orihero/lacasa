/// Storey — a single number input, placeholder "5" per SCREENS.md §3.5.
library;

import 'package:flutter/material.dart';

import 'filter_field_label.dart';
import 'filter_text_field.dart';

class FilterStoreySection extends StatelessWidget {
  const FilterStoreySection({
    super.key,
    required this.storeyController,
    required this.onChanged,
  });

  final TextEditingController storeyController;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const FilterFieldLabel('Storey'),
        FilterTextField(
          key: const ValueKey('filterField-storey'),
          controller: storeyController,
          placeholder: '5',
          keyboardType: TextInputType.number,
          onChanged: onChanged,
        ),
      ],
    );
  }
}
