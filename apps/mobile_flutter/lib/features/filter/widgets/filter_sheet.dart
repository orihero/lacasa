/// `filter-sheet` (SCREENS.md §3.5) — the buyer-facing full listing
/// attribute filter form, opened as a swipe-to-dismiss bottom sheet (§1:
/// "Bottom sheet (swipe-to-dismiss, partial height)") from
/// `listing-search`'s toolbar (and, later, `my-listings`'s — see
/// [isCrm]).
///
/// **Not a route.** Unlike `map-view`/`photo-gallery`, `filter-sheet` has
/// no entry in `route_paths.dart`/`app_router.dart` — SCREENS.md buckets
/// it as a bottom sheet, not a pushed/modal screen, and the recon brief
/// confirms there is nothing to wire in the router for it. The
/// integration point is [showFilterSheet], called directly from whichever
/// screen owns a "Filters" button:
/// ```dart
/// import 'package:lacasa_mobile/features/filter/filter.dart';
///
/// final applied = await showFilterSheet(context, initialFilters: currentFilters);
/// if (applied != null) {
///   // re-run the search/list fetch with `applied`.
/// }
/// ```
/// Returns the caller's new [AdFilters] on "Apply Filters" (commit +
/// close), or `null` if the sheet was dismissed any other way (close "X",
/// swipe-down, back gesture on the scrim) — the caller's own applied
/// filters are the source of truth; this sheet never mutates anything
/// outside itself, per this task's "return its result to the caller
/// rather than mutating global state directly" requirement.
///
/// **CRM variant.** SCREENS.md §3.5 also describes a second variant,
/// opened from `my-listings`, that appends Sort + Status fields to this
/// same form. [isCrm] (plus [FilterSheet]'s own `initialSort`/
/// `initialStatus`) is that variant's switch — wired by `my-listings`
/// (`features/my_listings/`), the one and only caller of
/// [showCrmFilterSheet] (see rule 3 in the build contract's §0 and §3.1).
/// [showFilterSheet]'s own `isCrm` parameter is kept for source
/// compatibility with the seam's original shape but should be left at its
/// `false` default by every caller other than [showCrmFilterSheet] itself
/// — a caller that wants the CRM fields back needs [showCrmFilterSheet]'s
/// richer [FilterSheetResult] return type, not [showFilterSheet]'s bare
/// [AdFilters].
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import '../state/filter_count_provider.dart';
import 'filter_area_section.dart';
import 'filter_category_type_section.dart';
import 'filter_city_district_section.dart';
import 'filter_furniture_repair_section.dart';
import 'filter_price_section.dart';
import 'filter_rooms_section.dart';
import 'filter_sheet_footer.dart';
import 'filter_sort_status_section.dart';
import 'filter_storey_section.dart';

/// The sheet's full result — [filters] is always populated; [sort]/
/// [status] are only ever non-null when the sheet was opened via
/// [showCrmFilterSheet] ([sort] specifically: always non-null in that
/// case, since `AdSort` has no "unset" value of its own — see
/// `filter_sort_status_section.dart`).
class FilterSheetResult {
  const FilterSheetResult({required this.filters, this.sort, this.status});

  final AdFilters filters;
  final AdSort? sort;
  final AdStage? status;
}

/// Opens `FilterSheet` as a modal bottom sheet and returns its result —
/// see this file's doc comment for the exact contract. The buyer-facing
/// entry point: only ever returns the [AdFilters] half of
/// [FilterSheetResult], since no caller other than [showCrmFilterSheet]
/// needs the Sort/Status fields.
Future<AdFilters?> showFilterSheet(
  BuildContext context, {
  AdFilters initialFilters = const AdFilters(),
  bool isCrm = false,
}) async {
  final result = await showModalBottomSheet<FilterSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) =>
        FilterSheet(initialFilters: initialFilters, isCrm: isCrm),
  );
  return result?.filters;
}

/// The CRM entry point (`my-listings` only — see this file's doc comment).
/// Returns the full [FilterSheetResult] (filters + sort + status), or
/// `null` on any dismissal other than "Apply Filters".
Future<FilterSheetResult?> showCrmFilterSheet(
  BuildContext context, {
  AdFilters initialFilters = const AdFilters(),
  AdSort initialSort = AdSort.newest,
  AdStage? initialStatus,
}) {
  return showModalBottomSheet<FilterSheetResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) => FilterSheet(
      initialFilters: initialFilters,
      isCrm: true,
      initialSort: initialSort,
      initialStatus: initialStatus,
    ),
  );
}

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({
    super.key,
    this.initialFilters = const AdFilters(),
    this.isCrm = false,
    this.initialSort = AdSort.newest,
    this.initialStatus,
  });

  final AdFilters initialFilters;

  /// See this file's doc comment.
  final bool isCrm;

  /// Only read when [isCrm] is true.
  final AdSort initialSort;

  /// Only read when [isCrm] is true.
  final AdStage? initialStatus;

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late String? _city;
  late String? _district;
  late AdCategory? _category;
  late AdType? _type;
  late int? _rooms;
  late num? _areaMin;
  late num? _areaMax;
  late int? _priceMin;
  late int? _priceMax;
  late Furniture? _furniture;
  late Repairment? _repairment;
  late int? _storey;

  /// Only ever read/mutated when [FilterSheet.isCrm] is true — see this
  /// file's doc comment.
  late AdSort _sort;
  late AdStage? _status;

  late final TextEditingController _areaMinController;
  late final TextEditingController _areaMaxController;
  late final TextEditingController _storeyController;

  AdFilters get _draft => AdFilters(
    city: _city,
    district: _district,
    category: _category,
    type: _type,
    rooms: _rooms,
    repairment: _repairment,
    storey: _storey,
    furniture: _furniture,
    areaMin: _areaMin,
    areaMax: _areaMax,
    priceMin: _priceMin,
    priceMax: _priceMax,
  );

  @override
  void initState() {
    super.initState();
    _applyToLocalState(_seedDefaults(widget.initialFilters));
    _sort = widget.initialSort;
    _status = widget.initialStatus;
    _areaMinController = TextEditingController(
      text: _areaMin == null ? '' : _trimNum(_areaMin!),
    );
    _areaMaxController = TextEditingController(
      text: _areaMax == null ? '' : _trimNum(_areaMax!),
    );
    _storeyController = TextEditingController(text: _storey?.toString() ?? '');
    // Seed the live count preview immediately (no debounce) so the Apply
    // button already shows a number before the user touches anything.
    // Skipped entirely for the CRM variant — see `filter_sheet_footer.dart`'s
    // `showLiveCount` doc comment for why that preview would be dishonest
    // there (it queries the wrong, buyer-facing endpoint).
    if (!widget.isCrm) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          ref.read(filterCountProvider.notifier).recountNow(_draft);
        }
      });
    }
  }

  @override
  void dispose() {
    _areaMinController.dispose();
    _areaMaxController.dispose();
    _storeyController.dispose();
    super.dispose();
  }

  /// Furniture/Repair are the only two fields SCREENS.md §3.5 gives a
  /// stated default (`withFurniture`, `notRepaired`) — applied whenever
  /// the incoming value is `null`. A caller re-opening the sheet with
  /// previously-*applied* filters that explicitly cleared one of these
  /// two back to "any" gets that `null` preserved as-is (the field was
  /// deliberately set, not merely never touched) — this only fills the
  /// gap for a truly fresh `const AdFilters()`.
  static AdFilters _seedDefaults(AdFilters initial) {
    return AdFilters(
      city: initial.city,
      district: initial.district,
      category: initial.category,
      type: initial.type,
      rooms: initial.rooms,
      repairment: initial.repairment ?? Repairment.notRepaired,
      storey: initial.storey,
      furniture: initial.furniture ?? Furniture.withFurniture,
      areaMin: initial.areaMin,
      areaMax: initial.areaMax,
      priceMin: initial.priceMin,
      priceMax: initial.priceMax,
    );
  }

  void _applyToLocalState(AdFilters f) {
    _city = f.city;
    _district = f.district;
    _category = f.category;
    _type = f.type;
    _rooms = f.rooms;
    _areaMin = f.areaMin;
    _areaMax = f.areaMax;
    _priceMin = f.priceMin?.round();
    _priceMax = f.priceMax?.round();
    _furniture = f.furniture;
    _repairment = f.repairment;
    _storey = f.storey;
  }

  void _onFieldChanged() {
    setState(() {});
    if (!widget.isCrm) {
      ref.read(filterCountProvider.notifier).scheduleRecount(_draft);
    }
  }

  void _onSortChanged(AdSort sort) {
    setState(() => _sort = sort);
  }

  void _onStatusChanged(AdStage? status) {
    setState(() => _status = status);
  }

  void _onCityChanged(String? value) {
    if (value == _city) return; // re-picking the same region: a no-op
    _city = value;
    // Any city change — clearing it, or swapping to a different region —
    // invalidates whatever District was picked under the old one, since
    // the District picker's option list is scoped to the chosen region's
    // `regionId`; a stale district name paired with a new/no city would be
    // a filter combination the picker itself could never produce again.
    _district = null;
    _onFieldChanged();
  }

  void _onDistrictChanged(String? value) {
    if (value == _district) return;
    _district = value;
    _onFieldChanged();
  }

  void _onAreaMinChanged(String value) {
    _areaMin = num.tryParse(value);
    _onFieldChanged();
  }

  void _onAreaMaxChanged(String value) {
    _areaMax = num.tryParse(value);
    _onFieldChanged();
  }

  void _onStoreyChanged(String value) {
    _storey = int.tryParse(value);
    _onFieldChanged();
  }

  void _reset() {
    setState(() {
      _applyToLocalState(_seedDefaults(const AdFilters()));
      _areaMinController.clear();
      _areaMaxController.clear();
      _storeyController.clear();
      if (widget.isCrm) {
        _sort = AdSort.newest;
        _status = null;
      }
    });
    if (!widget.isCrm) {
      // Reset is one explicit action, not a stream of edits — recount
      // immediately rather than debouncing it.
      unawaited(ref.read(filterCountProvider.notifier).recountNow(_draft));
    }
  }

  void _apply() {
    Navigator.of(context).pop(
      FilterSheetResult(
        filters: _draft,
        sort: widget.isCrm ? _sort : null,
        status: widget.isCrm ? _status : null,
      ),
    );
  }

  String _trimNum(num value) => value == value.roundToDouble()
      ? value.round().toString()
      : value.toString();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);
    // Never watched for the CRM variant — see `showLiveCount`'s doc
    // comment on `filter_sheet_footer.dart` for why that preview doesn't
    // apply there.
    final countAsync = widget.isCrm ? null : ref.watch(filterCountProvider);

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: FractionallySizedBox(
        heightFactor: 0.88,
        child: Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(AppRadii.sheet),
              topRight: Radius.circular(AppRadii.sheet),
            ),
          ),
          child: Column(
            children: [
              const SizedBox(height: AppSpacing.sm),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: colors.line,
                  borderRadius: AppRadii.pill,
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenGutter,
                  AppSpacing.lg,
                  AppSpacing.base,
                  AppSpacing.base,
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        l10n.filterSheetTitle,
                        style: type.sheetTitle.copyWith(color: colors.ink),
                      ),
                    ),
                    GestureDetector(
                      key: const ValueKey('filterSheet-close'),
                      onTap: () => Navigator.of(context).pop(),
                      child: Icon(
                        Icons.close_rounded,
                        color: colors.ink2,
                        size: 22,
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const MaterialScrollBehavior().copyWith(
                    overscroll: false,
                  ),
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.screenGutter,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        FilterCityDistrictSection(
                          city: _city,
                          district: _district,
                          onCityChanged: _onCityChanged,
                          onDistrictChanged: _onDistrictChanged,
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FilterCategoryTypeSection(
                          category: _category,
                          type: _type,
                          onCategoryChanged: (v) {
                            _category = v;
                            _onFieldChanged();
                          },
                          onTypeChanged: (v) {
                            _type = v;
                            _onFieldChanged();
                          },
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FilterRoomsSection(
                          rooms: _rooms,
                          onChanged: (v) {
                            _rooms = v;
                            _onFieldChanged();
                          },
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FilterAreaSection(
                          areaMinController: _areaMinController,
                          areaMaxController: _areaMaxController,
                          onAreaMinChanged: _onAreaMinChanged,
                          onAreaMaxChanged: _onAreaMaxChanged,
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FilterPriceSection(
                          priceMin: _priceMin,
                          priceMax: _priceMax,
                          onPriceMinChanged: (v) {
                            _priceMin = v;
                            _onFieldChanged();
                          },
                          onPriceMaxChanged: (v) {
                            _priceMax = v;
                            _onFieldChanged();
                          },
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FilterFurnitureRepairSection(
                          furniture: _furniture,
                          repairment: _repairment,
                          onFurnitureChanged: (v) {
                            _furniture = v;
                            _onFieldChanged();
                          },
                          onRepairmentChanged: (v) {
                            _repairment = v;
                            _onFieldChanged();
                          },
                        ),
                        const SizedBox(height: AppSpacing.section),
                        FilterStoreySection(
                          storeyController: _storeyController,
                          onChanged: _onStoreyChanged,
                        ),
                        if (widget.isCrm) ...[
                          const SizedBox(height: AppSpacing.section),
                          FilterSortStatusSection(
                            sort: _sort,
                            status: _status,
                            onSortChanged: (v) =>
                                _onSortChanged(v ?? AdSort.newest),
                            onStatusChanged: _onStatusChanged,
                          ),
                        ],
                        if (countAsync != null && countAsync.hasError) ...[
                          const SizedBox(height: AppSpacing.base),
                          _CountErrorRow(
                            onRetry: () => ref
                                .read(filterCountProvider.notifier)
                                .recountNow(_draft),
                          ),
                        ],
                        const SizedBox(height: AppSpacing.section),
                      ],
                    ),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  AppSpacing.screenGutter,
                  AppSpacing.base,
                  AppSpacing.screenGutter,
                  AppSpacing.lg,
                ),
                child: FilterSheetFooter(
                  onReset: _reset,
                  onApply: _apply,
                  showLiveCount: !widget.isCrm,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _CountErrorRow extends StatelessWidget {
  const _CountErrorRow({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Icon(
          Icons.error_outline_rounded,
          size: 16,
          color: AppStatusColors.warningText,
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Text(
            l10n.filterCountErrorMessage,
            style: type.bodySmall.copyWith(color: AppStatusColors.warningText),
          ),
        ),
        GestureDetector(
          key: const ValueKey('filterSheet-countRetry'),
          onTap: onRetry,
          child: Text(
            l10n.sharedRetryLabel,
            style: type.label.copyWith(color: AppAccent.color),
          ),
        ),
      ],
    );
  }
}
