/// SCREENS.md §24's "Ads statistics" panel — an area chart, series "Created"
/// / "Sold", matching `mockup-e-liquid-glass.html`'s `.panel` (the 12-point
/// SVG path with `#f5439b`/`#5a5ac8` gradients).
///
/// **Two structurally different renderings, gated on `useLiveWorkDashboardApi`
/// (`data/dashboard_mode.dart`), per contract ruling 7.1** — `GET
/// /statistics/ads` returns period totals, never a daily series, so there is
/// nothing server-backed to bind a 12-point chart to:
/// - **Fixture mode**: the real 12-point series
///   (`workDashboardChartFixture`, §4.6) drawn as a hand-painted dual-series
///   area chart — this is the one case where a 12-point chart is honest,
///   because the fixture genuinely is a 12-point series. Static: does not
///   respond to the time-range selector (ruling 7.1's own "static 12-point
///   chart" instruction).
/// - **Live mode**: degrades to `apps/console`'s own "Created vs sold"
///   two-bar period-total comparison (`StatisticsScreen.tsx`'s
///   `CreatedVsSoldBars`), reusing [adsStatisticsProvider]'s already-fetched
///   totals — which DOES respond to the time-range selector, since that's
///   the one figure this endpoint genuinely scopes by period. A caption
///   says outright why there's no day-by-day line here, matching
///   `apps/console`'s own `<Flag>` honesty move for the identical gap.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../data/dashboard_mode.dart';
import '../state/dashboard_providers.dart';
import 'dashboard_colors.dart';

class AdsStatisticsPanel extends ConsumerWidget {
  const AdsStatisticsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return GlassSurface(
      variant: GlassVariant.onSurface,
      borderRadius: BorderRadius.circular(AppRadii.cardLg),
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Ads statistics',
                  overflow: TextOverflow.ellipsis,
                  style: type.panelHeading.copyWith(color: colors.ink),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Text(
                useLiveWorkDashboardApi ? 'Period totals' : 'Days 1–12',
                style: type.bodySmall.copyWith(color: colors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          if (useLiveWorkDashboardApi)
            const _LiveCreatedVsSoldChart(key: ValueKey('adsStatisticsLive'))
          else
            const _FixtureAreaChart(key: ValueKey('adsStatisticsFixture')),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------
// Fixture mode — the real 12-point series.
// ---------------------------------------------------------------------

class _FixtureAreaChart extends StatelessWidget {
  const _FixtureAreaChart({super.key});

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final created = workDashboardChartFixture.map((p) => p.created).toList();
    final sold = workDashboardChartFixture.map((p) => p.sold).toList();

    return Column(
      children: [
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(
            painter: _DualSeriesChartPainter(
              created: created,
              sold: sold,
              createdColor: AppAccent.color,
              soldColor: kDashboardSoldColor,
              gridColor: colors.line,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [1, 3, 5, 7, 9, 11, 12]
              .map(
                (day) => Text(
                  '$day',
                  style: type.micro.copyWith(color: colors.faint),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            _LegendDot(color: AppAccent.color, label: 'Created'),
            const SizedBox(width: AppSpacing.lg),
            _LegendDot(color: kDashboardSoldColor, label: 'Sold'),
          ],
        ),
      ],
    );
  }
}

class _DualSeriesChartPainter extends CustomPainter {
  _DualSeriesChartPainter({
    required this.created,
    required this.sold,
    required this.createdColor,
    required this.soldColor,
    required this.gridColor,
  });

  final List<int> created;
  final List<int> sold;
  final Color createdColor;
  final Color soldColor;
  final Color gridColor;

  @override
  void paint(Canvas canvas, Size size) {
    if (created.isEmpty) return;

    final maxValue = math.max(
      1,
      [...created, ...sold].reduce(math.max),
    );

    // 3 faint horizontal guides, matching the mockup's own 4-line grid.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _paintSeries(canvas, size, created, createdColor, maxValue);
    _paintSeries(canvas, size, sold, soldColor, maxValue);
  }

  void _paintSeries(
    Canvas canvas,
    Size size,
    List<int> series,
    Color color,
    int maxValue,
  ) {
    final n = series.length;
    if (n < 2) return;

    final dx = size.width / (n - 1);
    Offset pointAt(int i) {
      final x = dx * i;
      // 10% headroom above the tallest point, matching the mockup's own
      // top-8px-of-120 gap, so a peak never touches the panel's top edge.
      final y = size.height - (series[i] / maxValue) * size.height * 0.9;
      return Offset(x, y);
    }

    final linePath = Path()..moveTo(0, pointAt(0).dy);
    for (var i = 1; i < n; i++) {
      linePath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(
        Offset(0, 0),
        Offset(0, size.height),
        [color.withValues(alpha: 0.32), color.withValues(alpha: 0)],
      );
    canvas.drawPath(fillPath, fillPaint);

    final strokePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.4
      ..strokeJoin = StrokeJoin.round
      ..strokeCap = StrokeCap.round;
    canvas.drawPath(linePath, strokePaint);
  }

  @override
  bool shouldRepaint(covariant _DualSeriesChartPainter oldDelegate) {
    return oldDelegate.created != created ||
        oldDelegate.sold != sold ||
        oldDelegate.createdColor != createdColor ||
        oldDelegate.soldColor != soldColor;
  }
}

// ---------------------------------------------------------------------
// Live mode — the honest 2-bar period-total comparison.
// ---------------------------------------------------------------------

class _LiveCreatedVsSoldChart extends ConsumerWidget {
  const _LiveCreatedVsSoldChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final adsStats = ref.watch(adsStatisticsProvider);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'No day-by-day breakdown is available — the API returns one total '
          'per period, so the bars below are the two real period totals, '
          'not a daily trend.',
          style: type.bodySmall.copyWith(color: colors.muted),
        ),
        const SizedBox(height: AppSpacing.base),
        adsStats.when(
          loading: () => const SizedBox(
            height: 120,
            child: Center(child: ShimmerBox(width: 120, height: 60)),
          ),
          error: (error, stackTrace) => SizedBox(
            height: 120,
            child: Center(
              child: RailRetryCard(
                width: 220,
                message: "Couldn't load ad statistics",
                onRetry: () => ref.invalidate(adsStatisticsProvider),
              ),
            ),
          ),
          data: (stats) => _CreatedVsSoldBars(
            created: stats.adsNewCount,
            sold: stats.adsSoldCount,
          ),
        ),
      ],
    );
  }
}

class _CreatedVsSoldBars extends StatelessWidget {
  const _CreatedVsSoldBars({required this.created, required this.sold});

  final int created;
  final int sold;

  @override
  Widget build(BuildContext context) {
    final maxValue = math.max(math.max(created, sold), 1);
    double heightFor(int value) =>
        math.max((value / maxValue) * 100, value > 0 ? 6 : 2);

    return SizedBox(
      height: 130,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _Bar(
            label: 'Created',
            value: created,
            heightPct: heightFor(created),
            color: AppAccent.color,
          ),
          const SizedBox(width: AppSpacing.xxl),
          _Bar(
            label: 'Sold',
            value: sold,
            heightPct: heightFor(sold),
            color: kDashboardSoldColor,
          ),
        ],
      ),
    );
  }
}

class _Bar extends StatelessWidget {
  const _Bar({
    required this.label,
    required this.value,
    required this.heightPct,
    required this.color,
  });

  final String label;
  final int value;
  final double heightPct;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return SizedBox(
      width: 64,
      height: 110,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          Text(
            '$value',
            style: type.rowTitle.copyWith(color: colors.ink),
          ),
          const SizedBox(height: AppSpacing.xs),
          Container(
            width: double.infinity,
            height: 70 * (heightPct / 100),
            decoration: BoxDecoration(
              color: color,
              borderRadius: const BorderRadius.vertical(
                top: Radius.circular(10),
              ),
            ),
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(label, style: type.micro.copyWith(color: colors.muted)),
        ],
      ),
    );
  }
}

class _LegendDot extends StatelessWidget {
  const _LegendDot({required this.color, required this.label});

  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: AppSpacing.xs),
        Text(label, style: type.bodySmall.copyWith(color: colors.ink2)),
      ],
    );
  }
}
