/// SCREENS.md §3.4's toolbar row: "'Filters' button (badge = active filter
/// count) → `filter-sheet`; map icon → `map-view`; inline Sort control —
/// 'Highest price' / 'Lowest price' / 'Newest'."
///
/// The Sort chips sit in their own horizontally-scrollable strip (rather
/// than a fixed row) so three full-word chip labels never overflow a
/// narrow phone width alongside the Filters button and map icon — see
/// `test/phone_width_overflow_test.dart`'s 360px case, which this screen
/// must not regress even though that suite doesn't reach `/search`
/// directly yet.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import '../state/search_providers.dart';

class SearchToolbar extends ConsumerWidget {
  const SearchToolbar({
    super.key,
    required this.onOpenFilters,
    required this.onOpenMap,
  });

  final VoidCallback onOpenFilters;
  final VoidCallback onOpenMap;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeCount = ref.watch(activeFilterCountProvider);
    final sort = ref.watch(searchSortProvider);

    return SizedBox(
      height: 36,
      child: Row(
        children: [
          _FiltersButton(count: activeCount, onTap: onOpenFilters),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: SearchSort.values.length,
              separatorBuilder: (context, index) =>
                  const SizedBox(width: AppSpacing.sm),
              itemBuilder: (context, index) {
                final option = SearchSort.values[index];
                return _SortChip(
                  key: ValueKey('sortChip-${option.name}'),
                  option: option,
                  selected: option == sort,
                  onTap: () =>
                      ref.read(searchSortProvider.notifier).setSort(option),
                );
              },
            ),
          ),
          const SizedBox(width: AppSpacing.sm),
          _MapIconButton(onTap: onOpenMap),
        ],
      ),
    );
  }
}

class _FiltersButton extends StatelessWidget {
  const _FiltersButton({required this.count, required this.onTap});

  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GestureDetector(
      key: const ValueKey('filtersButton'),
      onTap: onTap,
      child: GlassSurface(
        variant: GlassVariant.onSurface,
        borderRadius: AppRadii.pill,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 15, color: colors.ink),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppLocalizations.of(context).searchFiltersButtonLabel,
              style: type.rowTitle.copyWith(color: colors.ink),
            ),
            if (count > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                key: const ValueKey('filtersBadge'),
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: colors.pill,
                  borderRadius: AppRadii.pill,
                ),
                child: Text(
                  '$count',
                  style: type.caption.copyWith(color: colors.pillInk),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _SortChip extends StatelessWidget {
  const _SortChip({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final SearchSort option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final foreground = selected ? colors.pillInk : colors.ink;

    final content = Text(
      option.label(AppLocalizations.of(context)),
      style: type.rowTitle.copyWith(color: foreground),
    );

    return GestureDetector(
      onTap: onTap,
      child: selected
          ? Container(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              decoration: BoxDecoration(
                color: colors.pill,
                borderRadius: AppRadii.pill,
              ),
              alignment: Alignment.center,
              child: content,
            )
          : GlassSurface(
              variant: GlassVariant.onSurface,
              borderRadius: AppRadii.pill,
              padding: const EdgeInsets.symmetric(horizontal: 14),
              alignment: Alignment.center,
              child: content,
            ),
    );
  }
}

class _MapIconButton extends StatelessWidget {
  const _MapIconButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return GestureDetector(
      key: const ValueKey('mapViewButton'),
      onTap: onTap,
      child: GlassSurface(
        variant: GlassVariant.onSurface,
        borderRadius: AppRadii.pill,
        width: 36,
        height: 36,
        alignment: Alignment.center,
        child: Icon(Icons.map_outlined, size: 18, color: colors.ink),
      ),
    );
  }
}
