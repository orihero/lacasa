/// SCREENS.md §24's 2×2 stat-tile grid — "Ads created" / "Ads sold" /
/// "Active leads" / "Coworkers", matching `mockup-e-liquid-glass.html`'s
/// `.tile gl` rows exactly (the shipped mockup has four tiles; SCREENS.md
/// §3.24's own prose only names the first two, but §4.5's seed-data table is
/// titled "Dashboard stat metrics (4)" and `apps/console`'s own
/// `StatisticsScreen` renders the identical four — see this feature's own
/// `dashboard_repository.dart` doc comment for the same "shipped mockup over
/// terse prose" precedent `home_feed_screen.dart` already established).
///
/// Each tile reads its own [AsyncValue] independently (`WORK_TAB_CONTRACT.md`
/// §6's "independent providers per independently-failable section") — a
/// failed leads fetch shows "—" on the Active leads tile without touching
/// the other three.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../api/api.dart';
import '../../../navigation/route_paths.dart';
import '../../../theme/theme.dart';
import '../state/dashboard_providers.dart';

String _rangeSubtitle(StatisticsFilter filter) => switch (filter) {
  StatisticsFilter.all => 'all time',
  StatisticsFilter.thisMonth => 'this month',
  StatisticsFilter.thisWeek => 'this week',
  StatisticsFilter.today => 'today',
};

String _callbackSubtitle(int dueToday) =>
    dueToday == 1 ? '1 needs a call back' : '$dueToday need a call back';

class DashboardStatTiles extends ConsumerWidget {
  const DashboardStatTiles({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final range = ref.watch(dashboardTimeRangeProvider);
    final adsStats = ref.watch(adsStatisticsProvider);
    final leadsAsync = ref.watch(dashboardLeadsProvider);
    final coworkersAsync = ref.watch(dashboardCoworkersProvider);
    final rangeLabel = _rangeSubtitle(range);

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _StatTile(
                key: const ValueKey('dashboardTile-adsCreated'),
                label: 'Ads created',
                valueAsync: adsStats.whenData((s) => s.adsNewCount),
                subtitle: rangeLabel,
                onRetry: () => ref.invalidate(adsStatisticsProvider),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: _StatTile(
                key: const ValueKey('dashboardTile-adsSold'),
                label: 'Ads sold',
                valueAsync: adsStats.whenData((s) => s.adsSoldCount),
                subtitle: rangeLabel,
                onRetry: () => ref.invalidate(adsStatisticsProvider),
              ),
            ),
          ],
        ),
        const SizedBox(height: 11),
        Row(
          children: [
            Expanded(
              child: _StatTile(
                key: const ValueKey('dashboardTile-activeLeads'),
                label: 'Active leads',
                valueAsync: leadsAsync.whenData((leads) => leads.length),
                subtitle: leadsAsync.whenOrNull(
                  data: (leads) =>
                      _callbackSubtitle(countCallbacksDueToday(leads)),
                ),
                onRetry: () => ref.invalidate(dashboardLeadsProvider),
              ),
            ),
            const SizedBox(width: AppSpacing.base),
            Expanded(
              child: _StatTile(
                key: const ValueKey('dashboardTile-coworkers'),
                label: 'Coworkers',
                valueAsync: coworkersAsync.whenData((list) => list.length),
                subtitle: 'tap to manage',
                onRetry: () => ref.invalidate(dashboardCoworkersProvider),
                onTap: () => context.push(RoutePaths.workCoworkers),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({
    super.key,
    required this.label,
    required this.valueAsync,
    required this.onRetry,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final AsyncValue<int> valueAsync;
  final String? subtitle;
  final VoidCallback onRetry;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final Widget valueWidget = valueAsync.when(
      loading: () =>
          Text('…', style: type.numericDisplay.copyWith(color: colors.faint)),
      error: (error, stackTrace) => Text(
        '—',
        style: type.numericDisplay.copyWith(color: AppStatusColors.errorText),
      ),
      data: (value) => Text(
        '$value',
        style: type.numericDisplay.copyWith(color: colors.ink),
      ),
    );

    final Widget? subtitleWidget = valueAsync.hasError
        ? GestureDetector(
            onTap: onRetry,
            child: Text(
              'Retry',
              style: type.bodySmall.copyWith(
                color: AppAccent.color,
                fontWeight: FontWeight.w600,
              ),
            ),
          )
        : (subtitle == null
              ? null
              : Text(
                  subtitle!,
                  overflow: TextOverflow.ellipsis,
                  style: type.bodySmall.copyWith(color: colors.muted),
                ));

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: type.label.copyWith(color: colors.muted),
        ),
        const SizedBox(height: 6),
        valueWidget,
        if (subtitleWidget != null) ...[
          const SizedBox(height: 4),
          subtitleWidget,
        ],
      ],
    );

    final tile = GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: BorderRadius.circular(AppRadii.card),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: content,
    );

    if (onTap == null) return tile;

    return Semantics(
      button: true,
      label: subtitle == null ? label : '$label, $subtitle',
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: tile,
      ),
    );
  }
}
