/// City + District — a cascading Region → District picker sourced from
/// `GET /regions` (`regions_repository_provider.dart`'s cached
/// `regionsDataProvider`), closing the gap `data/filter_options.dart` used
/// to document (free-text fields, no shared vocabulary). District stays
/// disabled until City is non-empty and is scoped to the chosen region's
/// `regionId` — the cascade *behavior* is unchanged from the free-text
/// build, only the input mechanism (tap-to-pick instead of type-to-fill) is
/// new.
///
/// Each field renders as a tappable `GlassSurface` (not a `TextField`) that
/// opens `showFilterOptionPicker`. Three states for the region fetch:
///  - loading: both fields disabled, "Loading…" placeholder.
///  - error: both fields disabled, an inline retry row (mirrors
///    `filter_sheet.dart`'s own `_CountErrorRow` for the live-count
///    preview — same "don't blank the rest of the sheet over one failed
///    piece" rule).
///  - data: City enabled; District enabled only once a City is chosen.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/regions_repository_provider.dart';
import 'filter_option_picker_sheet.dart';
import 'filter_picker_field.dart';

class FilterCityDistrictSection extends ConsumerWidget {
  const FilterCityDistrictSection({
    super.key,
    required this.city,
    required this.district,
    required this.onCityChanged,
    required this.onDistrictChanged,
  });

  final String? city;
  final String? district;

  /// `null` means "Any city" was chosen (clears the filter); a non-null
  /// value is the picked region's name, verbatim (matches `AdFilters.city`
  /// — free text server-side, see `regions_repository.dart`'s doc comment
  /// for why a name, not an id, is what flows through here).
  final ValueChanged<String?> onCityChanged;
  final ValueChanged<String?> onDistrictChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final regionsAsync = ref.watch(regionsDataProvider);
    final l10n = AppLocalizations.of(context);

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(l10n.filterCityFieldLabel),
              regionsAsync.when(
                loading: () => FilterPickerField(
                  key: const ValueKey('filterField-city'),
                  value: null,
                  placeholder: l10n.filterRegionsLoadingPlaceholder,
                  enabled: false,
                ),
                error: (error, stackTrace) => FilterPickerField(
                  key: const ValueKey('filterField-city'),
                  value: null,
                  placeholder: l10n.filterRegionsErrorPlaceholder,
                  enabled: false,
                  onRetry: () => ref.invalidate(regionsDataProvider),
                ),
                data: (regions) => FilterPickerField(
                  key: const ValueKey('filterField-city'),
                  value: city,
                  placeholder: l10n.filterCityAnyOptionLabel,
                  enabled: true,
                  onTap: () async {
                    final selected = await showFilterOptionPicker(
                      context,
                      title: l10n.filterCityPickerTitle,
                      options: regions.regions.map((r) => r.name).toList(),
                      current: city,
                      anyLabel: l10n.filterCityAnyOptionLabel,
                    );
                    onCityChanged(selected);
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.base),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              FieldLabel(l10n.filterDistrictFieldLabel),
              regionsAsync.when(
                loading: () => FilterPickerField(
                  key: const ValueKey('filterField-district'),
                  value: null,
                  placeholder: l10n.filterRegionsLoadingPlaceholder,
                  enabled: false,
                ),
                error: (error, stackTrace) => FilterPickerField(
                  key: const ValueKey('filterField-district'),
                  value: null,
                  placeholder: l10n.filterRegionsErrorPlaceholder,
                  enabled: false,
                ),
                data: (regions) {
                  final selectedRegion = city == null
                      ? null
                      : regions.regions
                            .where((r) => r.name == city)
                            .firstOrNull;
                  final districtEnabled = selectedRegion != null;
                  final districtOptions = selectedRegion == null
                      ? const <String>[]
                      : regions.districts
                            .where((d) => d.regionId == selectedRegion.id)
                            .map((d) => d.name)
                            .toList();

                  return FilterPickerField(
                    key: const ValueKey('filterField-district'),
                    value: district,
                    placeholder: districtEnabled
                        ? l10n.filterDistrictAnyOptionLabel
                        : l10n.filterDistrictPickCityFirstPlaceholder,
                    enabled: districtEnabled,
                    onTap: districtEnabled
                        ? () async {
                            final selected = await showFilterOptionPicker(
                              context,
                              title: l10n.filterDistrictPickerTitle,
                              options: districtOptions,
                              current: district,
                              anyLabel: l10n.filterDistrictAnyOptionLabel,
                            );
                            onDistrictChanged(selected);
                          }
                        : null,
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }
}
