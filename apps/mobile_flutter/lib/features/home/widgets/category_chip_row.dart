/// The `.rail.chips` row: five single-select chips, "All" active by
/// default. **Decorative** (build spec, "Category chip row" — confirmed by
/// direct markup inspection: no `data-go`/`data-filter` on any `.chip`).
/// Selecting a chip only updates [selectedCategoryChipProvider]'s local
/// index — it must never fire a fetch or filter the rails below.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../theme/theme.dart';
import '../state/home_feed_providers.dart';

class _ChipSpec {
  const _ChipSpec(this.label, this.icon);
  final String label;
  final IconData icon;
}

const List<_ChipSpec> _chips = [
  _ChipSpec('All', Icons.grid_view_rounded),
  _ChipSpec('Apartment', Icons.apartment_rounded),
  _ChipSpec('House', Icons.house_rounded),
  _ChipSpec('Office', Icons.business_rounded),
  _ChipSpec('Retail', Icons.storefront_rounded),
];

class CategoryChipRow extends ConsumerWidget {
  const CategoryChipRow({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(selectedCategoryChipProvider);

    return SizedBox(
      height: 40,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.screenGutter,
        ),
        itemCount: _chips.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final chip = _chips[index];
          final isOn = index == selected;
          return _Chip(
            key: ValueKey('categoryChip-$index'),
            spec: chip,
            selected: isOn,
            onTap: () =>
                ref.read(selectedCategoryChipProvider.notifier).select(index),
          );
        },
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  const _Chip({
    super.key,
    required this.spec,
    required this.selected,
    required this.onTap,
  });

  final _ChipSpec spec;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final foreground = selected ? colors.pillInk : colors.ink;

    final content = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(spec.icon, size: 15, color: foreground),
        const SizedBox(width: AppSpacing.sm),
        Text(spec.label, style: type.rowTitle.copyWith(color: foreground)),
      ],
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
