/// SCREENS.md §24's `.opts` row — All / This month (default) / This week /
/// Today. Selecting an option updates [dashboardTimeRangeProvider], which
/// re-fetches [adsStatisticsProvider] only (ruling 7.1/7.2 — every other
/// dashboard figure is a period-independent snapshot, see
/// `state/dashboard_providers.dart`'s own doc comment).
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../theme/theme.dart';
import '../state/dashboard_providers.dart';

/// [StatisticsFilter]'s display label — a top-level function taking
/// [AppLocalizations] rather than an extension getter, since the label now
/// needs the current locale, and every call site below already has one in
/// scope (via `build`).
String _filterLabel(AppLocalizations l10n, StatisticsFilter filter) => switch (filter) {
  StatisticsFilter.all => l10n.dashboardFilterLabelAll,
  StatisticsFilter.thisMonth => l10n.dashboardFilterLabelThisMonth,
  StatisticsFilter.thisWeek => l10n.dashboardFilterLabelThisWeek,
  StatisticsFilter.today => l10n.dashboardFilterLabelToday,
};

/// Display order per SCREENS.md §24 — deliberately *not*
/// `StatisticsFilter.values` (whose declaration order, `all, today,
/// thisWeek, thisMonth`, matches wire/API semantics, not the UI's ask).
const _displayOrder = [
  StatisticsFilter.all,
  StatisticsFilter.thisMonth,
  StatisticsFilter.thisWeek,
  StatisticsFilter.today,
];

class DashboardTimeRangeSelector extends ConsumerWidget {
  const DashboardTimeRangeSelector({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final selected = ref.watch(dashboardTimeRangeProvider);

    return SizedBox(
      height: 36,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: _displayOrder.length,
        separatorBuilder: (context, index) =>
            const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final option = _displayOrder[index];
          return _RangeChip(
            key: ValueKey('dashboardRange-${option.name}'),
            option: option,
            selected: option == selected,
            onTap: () =>
                ref.read(dashboardTimeRangeProvider.notifier).select(option),
          );
        },
      ),
    );
  }
}

class _RangeChip extends StatelessWidget {
  const _RangeChip({
    super.key,
    required this.option,
    required this.selected,
    required this.onTap,
  });

  final StatisticsFilter option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final foreground = selected ? colors.pillInk : colors.ink;
    final label = _filterLabel(AppLocalizations.of(context), option);

    final content = Text(
      label,
      style: type.rowTitle.copyWith(color: foreground),
    );

    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: GestureDetector(
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
      ),
    );
  }
}
