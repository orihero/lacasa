/// SCREENS.md §25's toolbar row: "'Filter' → `filter-sheet`; '+' (Create
/// New Post) → `create-listing`." Visually mirrors
/// `features/search/widgets/search_toolbar.dart`'s own Filters button
/// (same badge-count convention) — no inline Sort control here, unlike
/// Search's toolbar, since Sort lives inside the CRM filter sheet itself
/// for this screen (SCREENS.md §3.5's CRM variant), not as a second,
/// separate row control.
library;

import 'package:flutter/material.dart';

import '../../../theme/theme.dart';

class MyListingsToolbar extends StatelessWidget {
  const MyListingsToolbar({
    super.key,
    required this.activeFilterCount,
    required this.onOpenFilters,
    required this.onCreate,
  });

  final int activeFilterCount;
  final VoidCallback onOpenFilters;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 36,
      child: Row(
        children: [
          _FiltersButton(count: activeFilterCount, onTap: onOpenFilters),
          const Spacer(),
          _CreateButton(onTap: onCreate),
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
      key: const ValueKey('myListingsFiltersButton'),
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
            Text('Filter', style: type.rowTitle.copyWith(color: colors.ink)),
            if (count > 0) ...[
              const SizedBox(width: AppSpacing.xs),
              Container(
                key: const ValueKey('myListingsFiltersBadge'),
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

class _CreateButton extends StatelessWidget {
  const _CreateButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: 'Create New Post',
      child: GestureDetector(
        key: const ValueKey('myListingsCreateButton'),
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: AppAccent.gradient,
            borderRadius: AppRadii.pill,
            boxShadow: AppShadows.accentGlow,
          ),
          child: const Icon(Icons.add_rounded, size: 20, color: Colors.white),
        ),
      ),
    );
  }
}
