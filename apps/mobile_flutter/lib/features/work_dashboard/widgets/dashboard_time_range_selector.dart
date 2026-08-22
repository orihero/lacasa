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
import '../../../shared/shared.dart';
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
    final l10n = AppLocalizations.of(context);

    // `.opts{display:flex;flex-wrap:wrap;gap:7px}` /
    // `.opt{height:38px;border-radius:19px;padding:0 15px;font-size:12px;
    // font-weight:500}` / `.opt.on{background:var(--pill);
    // color:var(--pill-ink);box-shadow:0 8px 16px -8px rgba(21,21,27,.6)}`
    // — exactly the box [ChoiceChipGroup] already renders, so this row
    // reuses it rather than keeping a second, drifting copy of `.opt`.
    // [allowDeselect] is `false`: the dashboard always has a range, so
    // re-tapping the selected chip re-selects it instead of clearing to
    // `null`.
    return ChoiceChipGroup<StatisticsFilter>(
      keyPrefix: 'dashboardRange',
      options: [
        for (final option in _displayOrder)
          ChoiceOption(option, _filterLabel(l10n, option)),
      ],
      selected: selected,
      allowDeselect: false,
      onChanged: (option) =>
          ref.read(dashboardTimeRangeProvider.notifier).select(option!),
    );
  }
}
