/// SCREENS.md §3.5's fixed option lists for `filter-sheet`.
///
/// **City/District** used to be free-text fields here — no longer: `GET
/// /regions` now serves the `@lacasa/domain` region/district vocabulary
/// over HTTP (`regions_repository.dart`), which is what
/// `widgets/filter_city_district_section.dart` picks from. Nothing about
/// that vocabulary is a fixed "option list" the way the fields below are
/// (it's fetched, cached, and cascades Region → District), so it doesn't
/// live in this file — see `regions_repository_provider.dart`.
///
/// **Price ladder**: hardcoded here because there is no endpoint for
/// it — matches both SCREENS.md §3.5's own list and
/// `apps/web/src/components/filter/Filter.jsx`'s `priceList` exactly.
library;

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/widgets/choice_chip_group.dart';

/// One labeled value for a single-select chip group — an alias for the
/// shared [ChoiceOption], kept under this feature's own name since every
/// call site here already spells it `FilterOption`.
typedef FilterOption<T> = ChoiceOption<T>;

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

/// Built from [AppLocalizations] rather than a top-level `const` list (the
/// original shape) since every option label is now a localized lookup,
/// which requires a [BuildContext] and so cannot be `const` — every call
/// site already has a `context` (they're all inside a widget's `build`).
List<FilterOption<AdCategory>> filterCategoryOptions(AppLocalizations l10n) => [
  FilterOption(AdCategory.rent, l10n.filterCategoryRentOptionLabel),
  FilterOption(AdCategory.sale, l10n.filterCategorySaleOptionLabel),
];

List<FilterOption<AdType>> filterTypeOptions(AppLocalizations l10n) => [
  FilterOption(AdType.residential, l10n.filterTypeResidentialOptionLabel),
  FilterOption(AdType.nonresidential, l10n.filterTypeNonresidentialOptionLabel),
];

/// SCREENS.md §3.5 marks `withFurniture` as this field's **default**, and
/// this list deliberately does *not* honour that: on a search filter,
/// "unset" means "any", so a pre-selected chip would apply a constraint
/// the buyer never chose (the full argument lives in
/// `widgets/filter_sheet.dart`'s library doc comment, under "No invented
/// defaults"). The sheet therefore opens with neither chip lit and
/// `null` as the field's value.
///
/// The follow-up that would honour the mockup's appearance *and* keep
/// "apply nothing" reachable is to prepend an explicit `FilterOption(
/// null, <"Any furniture">)` here (widening this to
/// `List<FilterOption<Furniture?>>`, which `ChoiceChipGroup<Furniture?>`
/// already accepts unchanged) so that "any" becomes a visible,
/// selectable, initially-selected chip rather than an invisible empty
/// state. That needs a new localized label — no existing ARB key fits,
/// and `filterCityAnyOptionLabel`/`filterDistrictAnyOptionLabel`/
/// `filterPriceAnyOptionLabel` are all field-specific — so it is blocked
/// on l10n rather than on this file.
List<FilterOption<Furniture>> filterFurnitureOptions(AppLocalizations l10n) => [
  FilterOption(Furniture.withFurniture, l10n.filterFurnitureWithOptionLabel),
  FilterOption(
    Furniture.withoutFurniture,
    l10n.filterFurnitureWithoutOptionLabel,
  ),
];

/// SCREENS.md §3.5 marks `notRepaired` as this field's **default**, which
/// this list likewise does not honour — same reasoning, same blocked
/// follow-up, as [filterFurnitureOptions].
List<FilterOption<Repairment>> filterRepairOptions(AppLocalizations l10n) => [
  FilterOption(Repairment.notRepaired, l10n.filterRepairNotRepairedOptionLabel),
  FilterOption(Repairment.normal, l10n.filterRepairNormalOptionLabel),
  FilterOption(Repairment.good, l10n.filterRepairGoodOptionLabel),
  FilterOption(Repairment.excellent, l10n.filterRepairExcellentOptionLabel),
];

// ---------------------------------------------------------------------
// CRM-variant-only fields (SCREENS.md §3.5: "CRM variant ... appends
// Sort ... and Status") — `my-listings` (`features/my_listings/`) is the
// one and only caller that ever passes `isCrm: true` to `showFilterSheet`/
// `showCrmFilterSheet`; see `widgets/filter_sort_status_section.dart`.
// ---------------------------------------------------------------------

/// Same 3 values `AdSort` (`api/resources/agent_ads_resource.dart`) wires
/// on `GET /my/ads`'s `sort` param — reusing that enum directly (rather
/// than a second client-only mirror the way `listing-search`'s own
/// `SearchSort` does) since `my-listings`'s Sort really is a server
/// parameter, unlike `listing-search`'s client-only re-sort of an
/// unsortable public feed.
List<FilterOption<AdSort>> filterCrmSortOptions(AppLocalizations l10n) => [
  FilterOption(AdSort.newest, l10n.filterSortNewestOptionLabel),
  FilterOption(AdSort.highestPrice, l10n.filterSortHighestPriceOptionLabel),
  FilterOption(AdSort.lowestPrice, l10n.filterSortLowestPriceOptionLabel),
];

/// SCREENS.md §3.5's Status field — `AdStage.unknown` deliberately excluded
/// (never a real, selectable filter value; matches `filterCrmStatusOptions`
/// having no "any" chip counterpart of its own — the chip group's own
/// deselect-to-null behavior already covers "All stages").
List<FilterOption<AdStage>> filterCrmStatusOptions(AppLocalizations l10n) => [
  FilterOption(AdStage.active, l10n.filterStatusActiveOptionLabel),
  FilterOption(AdStage.sold, l10n.filterStatusSoldOptionLabel),
  FilterOption(AdStage.draft, l10n.filterStatusDraftOptionLabel),
];
