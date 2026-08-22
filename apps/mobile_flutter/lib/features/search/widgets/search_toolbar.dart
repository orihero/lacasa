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
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/search_providers.dart';

/// Left-to-right order of the sort strip, which is the mockup's `.opts`
/// order, not the order SCREENS.md §3.4 happens to list the three controls
/// in. That sentence fixes the labels and wire values (both unchanged); the
/// arrangement is the mockup's call, and it is load-bearing: the default sort
/// is [SearchSort.newest], so putting it first is what keeps the *selected*
/// chip on screen and sends "Highest price" off the right edge instead.
const _sortDisplayOrder = <SearchSort>[
  SearchSort.newest,
  SearchSort.lowestPrice,
  SearchSort.highestPrice,
];

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

    // `.tools` source order: Filters → map → `.tools__sp{flex:1}` spacer →
    // the sort strip, hard against the trailing edge.
    return SizedBox(
      height: 38,
      child: Row(
        children: [
          _FiltersButton(count: activeCount, onTap: onOpenFilters),
          const SizedBox(width: AppSpacing.md),
          _MapIconButton(onTap: onOpenMap),
          const SizedBox(width: AppSpacing.md),
          Flexible(
            // The mockup's `.tools__sp{flex:1}` right-aligns the strip when it
            // fits; when it doesn't, `.opts{overflow-x:auto}` sits at offset 0
            // and the overflow runs off the *screen* edge, which reads as
            // "scroll for more". `reverse: true` inverted that second case: it
            // pinned the strip's tail, so on a real phone the first chip was
            // sliced in half mid-layout, hard against the map button. Giving
            // the row the track's width as a minimum reproduces both cases —
            // narrower than the track, `MainAxisAlignment.end` pushes it to the
            // trailing edge; wider, the row takes its own width and the
            // viewport starts at the first chip.
            // [ShadowSafeClip] + `Clip.none`: the selected sort chip is
            // 32dp in a 38dp toolbar and its [AppShadows.selectedChip] lift
            // needs ~22dp below it, so the scroll view's own viewport clip
            // was cutting the shadow into a hard line under the pill. The
            // strip cannot simply stop clipping, though — it shares its row
            // with the Filters and map buttons, and chips scrolled past the
            // leading edge would paint straight over them. So the scroll
            // view stops clipping and the wrapper puts the horizontal clip
            // back, without the vertical one. See `shadow_safe_clip.dart`.
            child: LayoutBuilder(
              builder: (context, constraints) => ShadowSafeClip(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minWidth: constraints.maxWidth,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        for (final option in _sortDisplayOrder) ...[
                          if (option != _sortDisplayOrder.first)
                            const SizedBox(width: AppSpacing.sm),
                          _SortChip(
                            key: ValueKey('sortChip-${option.name}'),
                            option: option,
                            selected: option == sort,
                            onTap: () => ref
                                .read(searchSortProvider.notifier)
                                .setSort(option),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
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
      // `.opt{height:38px;border-radius:19px;padding:0 15px;font-size:12px;
      // font-weight:500}` — `body` is the 12px role, the weight is the
      // override, same as `choice_chip_group.dart`'s own `.opt`.
      child: GlassSurface(
        variant: GlassVariant.onSurface,
        borderRadius: AppRadii.pill,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        height: 38,
        alignment: Alignment.center,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.tune_rounded, size: 15, color: colors.ink),
            const SizedBox(width: AppSpacing.sm),
            Text(
              AppLocalizations.of(context).searchFiltersButtonLabel,
              style: type.body.copyWith(
                fontWeight: FontWeight.w500,
                color: colors.ink,
              ),
            ),
            if (count > 0) ...[
              // `.tools__f .cnt` — a pink accent bubble with white digits,
              // not the near-black `.pill` used by selected chips.
              const SizedBox(width: 2),
              Container(
                key: const ValueKey('filtersBadge'),
                constraints: const BoxConstraints(minWidth: 17, minHeight: 17),
                padding: const EdgeInsets.symmetric(horizontal: 5),
                alignment: Alignment.center,
                decoration: const BoxDecoration(
                  color: AppAccent.color,
                  borderRadius: AppRadii.pill,
                ),
                child: Text(
                  '$count',
                  style: type.caption.copyWith(color: Colors.white),
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

    // The sort chips are `.opt--sm{height:32px;padding:0 12px;font-size:11px}`,
    // a size down from the Filters/map `.opt` pills beside them. `.opt--sm`
    // overrides the box and the size only — the `font-weight:500` from `.opt`
    // still applies, so the weight comes from `.opt` and the 11px from here.
    final content = Text(
      option.label(AppLocalizations.of(context)),
      style: type.body.copyWith(
        fontWeight: FontWeight.w500,
        fontSize: 11,
        color: foreground,
      ),
    );

    return GestureDetector(
      onTap: onTap,
      child: selected
          ? Container(
              height: 32,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: colors.pill,
                borderRadius: AppRadii.pill,
                // `.opt.on{box-shadow:0 8px 16px -8px rgba(21,21,27,.6)}`.
                boxShadow: AppShadows.selectedChip,
              ),
              alignment: Alignment.center,
              child: content,
            )
          : GlassSurface(
              variant: GlassVariant.onSurface,
              borderRadius: AppRadii.pill,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              height: 32,
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
      // Also an `.opt` pill (not a square icon button), carrying the
      // *filled* map-trifold glyph.
      child: GlassSurface(
        variant: GlassVariant.onSurface,
        borderRadius: AppRadii.pill,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        height: 38,
        alignment: Alignment.center,
        child: Icon(Icons.map_rounded, size: 17, color: colors.ink),
      ),
    );
  }
}
