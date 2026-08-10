/// Min/Max total area — two number inputs side by side, placeholders
/// "20"/"40", suffix "m²" per SCREENS.md §3.5.
library;

import 'package:flutter/material.dart';

import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import 'filter_text_field.dart';

class FilterAreaSection extends StatelessWidget {
  const FilterAreaSection({
    super.key,
    required this.areaMinController,
    required this.areaMaxController,
    required this.onAreaMinChanged,
    required this.onAreaMaxChanged,
  });

  final TextEditingController areaMinController;
  final TextEditingController areaMaxController;
  final ValueChanged<String> onAreaMinChanged;
  final ValueChanged<String> onAreaMaxChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel('Min. total area'),
              FilterTextField(
                key: const ValueKey('filterField-areaMin'),
                controller: areaMinController,
                placeholder: '20',
                suffixText: 'm²',
                keyboardType: TextInputType.number,
                onChanged: onAreaMinChanged,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FieldLabel('Max total area'),
              FilterTextField(
                key: const ValueKey('filterField-areaMax'),
                controller: areaMaxController,
                placeholder: '40',
                suffixText: 'm²',
                keyboardType: TextInputType.number,
                onChanged: onAreaMaxChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
