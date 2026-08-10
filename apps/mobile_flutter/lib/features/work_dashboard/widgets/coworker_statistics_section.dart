/// SCREENS.md §24's "Coworker statistics" section — "bar chart per coworker
/// (Ads count / Lead count / Sale count) plus a list with the same columns
/// ... Tap coworker row → coworker-detail."
///
/// **"Sale count" renders as an honest em dash, never a number — this is
/// contract ruling 7.6's own call-out**: "'Deals closed'/a 6th 'Success'
/// lead status does not exist anywhere in the schema". "Ads count"/"Lead
/// count" are both real, both derived — [CoworkerStatRow.adsCount] folds
/// `GET /statistics/coworkers`'s [ActivityEvent] stream by `coworkerId`/
/// `ActivityEventStage.adCreated`, [CoworkerStatRow.leadCount] folds
/// [Lead.coworkerId] directly (`state/dashboard_providers.dart`'s
/// `coworkerStatRowsProvider` doc comment explains why the two columns use
/// two different real sources) — only the sale/"deals closed" figure has no
/// backing field anywhere in the schema, so only that column is flagged
/// rather than the whole section.
///
/// Row tap uses `context.go`, not `context.push`, per
/// `WORK_TAB_CONTRACT.md` §2.2: `coworker-detail` is named there as one of
/// the three Work-only-concept screens that always navigate by `go`, even
/// from inside the Work branch itself.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../navigation/route_paths.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/dashboard_providers.dart';
import 'dashboard_colors.dart';

class CoworkerStatisticsSection extends ConsumerWidget {
  const CoworkerStatisticsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rowsAsync = ref.watch(coworkerStatRowsProvider);

    return rowsAsync.when(
      loading: () => const _Panel(
        child: SizedBox(
          height: 96,
          child: Center(
            child: ShimmerBox(width: 220, height: 48),
          ),
        ),
      ),
      error: (error, stackTrace) => _Panel(
        child: RailRetryCard(
          width: double.infinity,
          message: "Couldn't load coworker statistics",
          onRetry: () => ref.invalidate(dashboardCoworkersProvider),
        ),
      ),
      data: (rows) {
        if (rows.isEmpty) {
          return const _Panel(
            child: FullWidthState(
              icon: Icons.groups_outlined,
              message: 'No coworkers yet.',
            ),
          );
        }
        return _Panel(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _CoworkerBarChart(rows: rows),
              const SizedBox(height: AppSpacing.base),
              _Legend(),
              const SizedBox(height: AppSpacing.section),
              _CoworkerList(rows: rows),
            ],
          ),
        );
      },
    );
  }
}

class _Panel extends StatelessWidget {
  const _Panel({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: BorderRadius.circular(AppRadii.cardLg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: child,
    );
  }
}

class _CoworkerBarChart extends StatelessWidget {
  const _CoworkerBarChart({required this.rows});

  final List<CoworkerStatRow> rows;

  @override
  Widget build(BuildContext context) {
    final maxCount = rows.fold<int>(
      1,
      (max, row) => [max, row.adsCount, row.leadCount].reduce(
        (a, b) => a > b ? a : b,
      ),
    );

    return Column(
      children: [
        for (final row in rows) ...[
          _BarRow(row: row, maxCount: maxCount),
          if (row != rows.last) const SizedBox(height: AppSpacing.base),
        ],
      ],
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.row, required this.maxCount});

  final CoworkerStatRow row;
  final int maxCount;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final firstName = row.coworker.fullName.trim().split(RegExp(r'\s+')).first;

    double fractionOf(int value) => maxCount == 0 ? 0 : value / maxCount;

    return Row(
      key: ValueKey('coworkerBarRow-${row.coworker.id}'),
      children: [
        SizedBox(
          width: 64,
          child: Text(
            firstName,
            overflow: TextOverflow.ellipsis,
            style: type.bodySmall.copyWith(color: colors.ink2),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _Track(
                fraction: fractionOf(row.adsCount),
                color: AppAccent.color,
              ),
              const SizedBox(height: 4),
              _Track(
                fraction: fractionOf(row.leadCount),
                color: kDashboardSoldColor,
              ),
            ],
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        SizedBox(
          width: 22,
          child: Text(
            '${row.adsCount}',
            textAlign: TextAlign.right,
            style: LaCasaTypography.tabular(
              type.rowTitle,
            ).copyWith(color: colors.ink),
          ),
        ),
      ],
    );
  }
}

class _Track extends StatelessWidget {
  const _Track({required this.fraction, required this.color});

  final double fraction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadii.pillValue),
      child: LinearProgressIndicator(
        value: fraction.clamp(0, 1),
        minHeight: 6,
        backgroundColor: colors.sunk,
        valueColor: AlwaysStoppedAnimation(color),
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Wrap(
      spacing: AppSpacing.lg,
      runSpacing: AppSpacing.xs,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        _dot(context, AppAccent.color, 'Ads count'),
        _dot(context, kDashboardSoldColor, 'Lead count'),
        _dot(context, colors.faint, 'Sale count — not tracked'),
      ]
          .map(
            (child) => DefaultTextStyle.merge(
              style: type.bodySmall.copyWith(color: colors.ink2),
              child: child,
            ),
          )
          .toList(),
    );
  }

  Widget _dot(BuildContext context, Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label),
      ],
    );
  }
}

class _CoworkerList extends StatelessWidget {
  const _CoworkerList({required this.rows});

  final List<CoworkerStatRow> rows;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              flex: 3,
              child: Text(
                'COWORKERS',
                style: type.label.copyWith(color: colors.muted),
              ),
            ),
            _HeaderCell('ADS'),
            _HeaderCell('LEADS'),
            _HeaderCell('SALES'),
          ],
        ),
        const SizedBox(height: AppSpacing.base),
        Divider(height: 1, color: colors.line),
        for (final row in rows) _CoworkerListRow(row: row),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  const _HeaderCell(this.label);

  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return SizedBox(
      width: 44,
      child: Text(
        label,
        textAlign: TextAlign.right,
        style: type.label.copyWith(color: colors.muted),
      ),
    );
  }
}

class _CoworkerListRow extends StatelessWidget {
  const _CoworkerListRow({required this.row});

  final CoworkerStatRow row;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Semantics(
      button: true,
      label: row.coworker.fullName,
      child: GestureDetector(
        key: ValueKey('coworkerStatListRow-${row.coworker.id}'),
        behavior: HitTestBehavior.opaque,
        onTap: () =>
            context.go('${RoutePaths.work}/coworkers/${row.coworker.id}'),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: AppSpacing.base),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: colors.line)),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Row(
                  children: [
                    AgentAvatar(
                      avatarUrl: row.coworker.avatar,
                      fullName: row.coworker.fullName,
                      size: 28,
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        row.coworker.fullName,
                        overflow: TextOverflow.ellipsis,
                        style: type.rowTitle.copyWith(color: colors.ink),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${row.adsCount}',
                  textAlign: TextAlign.right,
                  style: LaCasaTypography.tabular(
                    type.bodySmall,
                  ).copyWith(color: colors.ink2),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '${row.leadCount}',
                  textAlign: TextAlign.right,
                  style: LaCasaTypography.tabular(
                    type.bodySmall,
                  ).copyWith(color: colors.ink2),
                ),
              ),
              SizedBox(
                width: 44,
                child: Text(
                  '—',
                  textAlign: TextAlign.right,
                  style: type.bodySmall.copyWith(color: colors.faint),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
