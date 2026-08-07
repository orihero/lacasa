/// SCREENS.md §3.5's fixed option lists for `filter-sheet`, plus the two
/// gaps flagged in the build report:
///
/// - **City/District**: SCREENS.md calls for a City select sourced from
///   `regions.json` (`packages/domain/src/data/regions.json`, 14 regions /
///   203 districts) with District cascaded from it. That file is a
///   TS/JSON package export, not reachable from this Dart app (no HTTP
///   endpoint serves it either — `Ad.city`/`Ad.district` are free text
///   server-side, never validated against it). Hand-copying ~217 rows
///   into a Dart literal was explicitly ruled out by this task's brief
///   ("do NOT invent one and do NOT copy 203 districts by hand"), so City
///   and District are built as free-text fields instead (see
///   `widgets/filter_city_district_section.dart`) — this is not a design
///   downgrade so much as it matches what the server itself actually
///   validates against (nothing; any string). District is disabled until
///   City is non-empty, preserving the cascade *behavior* SCREENS.md asks
///   for even without a shared vocabulary backing it.
/// - **Price ladder**: hardcoded here because there is no endpoint for
///   it either — matches both SCREENS.md §3.5's own list and
///   `apps/web/src/components/filter/Filter.jsx`'s `priceList` exactly.
library;

import '../../../api/api.dart';

/// One labeled value for a single-select chip group.
class FilterOption<T> {
  const FilterOption(this.value, this.label);
  final T value;
  final String label;
}

const List<int> filterRoomOptions = [1, 2, 3, 4, 5, 6];

/// SCREENS.md §3.5's price ladder, verbatim.
const List<int> filterPriceLadder = [
  100000,
  500000,
  1000000,
  5000000,
  10000000,
  30000000,
  50000000,
  100000000,
  500000000,
];

const List<FilterOption<AdCategory>> filterCategoryOptions = [
  FilterOption(AdCategory.rent, 'Rent'),
  FilterOption(AdCategory.sale, 'Sale'),
];

const List<FilterOption<AdType>> filterTypeOptions = [
  FilterOption(AdType.residential, 'Residential'),
  FilterOption(AdType.nonresidential, 'Nonresidential'),
];

/// SCREENS.md marks `withFurniture` as this field's **default** — see
/// `widgets/filter_sheet.dart`'s `_seedDefaults` for where that default is
/// actually applied (on first open / after Reset, never silently
/// overwriting a previously-applied `null`/"any" choice).
const List<FilterOption<Furniture>> filterFurnitureOptions = [
  FilterOption(Furniture.withFurniture, 'With furniture'),
  FilterOption(Furniture.withoutFurniture, 'Without Furniture'),
];

/// SCREENS.md marks `notRepaired` as this field's **default** — same note
/// as [filterFurnitureOptions].
const List<FilterOption<Repairment>> filterRepairOptions = [
  FilterOption(Repairment.notRepaired, 'Not repaired'),
  FilterOption(Repairment.normal, 'Normal'),
  FilterOption(Repairment.good, 'Good'),
  FilterOption(Repairment.excellent, 'Excellent'),
];
