/// City + District — free-text fields, not the `regions.json`-backed
/// selects SCREENS.md §3.5 specifies. See `data/filter_options.dart`'s doc
/// comment for the full gap explanation. District stays disabled until
/// City is non-empty, which is the one piece of the cascade contract this
/// build *can* honor without the region vocabulary.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';
import 'filter_field_label.dart';
import 'filter_text_field.dart';

class FilterCityDistrictSection extends StatelessWidget {
  const FilterCityDistrictSection({
    super.key,
    required this.cityController,
    required this.districtController,
    required this.districtEnabled,
    required this.onCityChanged,
    required this.onDistrictChanged,
  });

  final TextEditingController cityController;
  final TextEditingController districtController;
  final bool districtEnabled;
  final ValueChanged<String> onCityChanged;
  final ValueChanged<String> onDistrictChanged;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FilterFieldLabel('City'),
              FilterTextField(
                key: const ValueKey('filterField-city'),
                controller: cityController,
                placeholder: 'e.g. Tashkent',
                onChanged: onCityChanged,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const FilterFieldLabel('District'),
              FilterTextField(
                key: const ValueKey('filterField-district'),
                controller: districtController,
                placeholder: districtEnabled ? 'e.g. Chilonzor' : 'Pick a city first',
                enabled: districtEnabled,
                onChanged: onDistrictChanged,
              ),
            ],
          ),
        ),
      ],
    );
  }
}
