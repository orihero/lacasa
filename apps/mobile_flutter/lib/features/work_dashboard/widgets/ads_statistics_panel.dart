/// SCREENS.md §24's "Ads statistics" panel — an area chart, series "Created"
/// / "Sold", matching `mockup-e-liquid-glass.html`'s `.panel` (the 12-point
/// SVG path with `#f5439b`/`#5a5ac8` gradients).
///
/// **One rendering path, driven by a real [AdsSeries], in both modes —
/// contract ruling 7.1 is closed.** `GET /statistics/ads/series` now
/// returns a real, server-bucketed day/hour series
/// (`data/dashboard_repository.dart`'s `fetchAdsSeries`), so this file no
/// longer needs its old fixture-vs-live fork: [_SeriesAreaChart] plots
/// [adsSeriesProvider]'s data with the same `CustomPainter` this screen has
/// always used — `apps/console` made the same call not to pull in a
/// charting library for one screen, and matching it is deliberate — the
/// only difference between modes is *whose* [AdsSeries] it is (the fixture
/// repository's own `workDashboardChartFixture`-derived series, or the real
/// API's). [AdsSeries.granularity] (`hour`/`day`) drives the axis-label
/// format below rather than assuming every series is daily.
library;

import 'dart:math' as math;
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import '../../../shared/shared.dart';
import '../../../theme/theme.dart';
import '../state/dashboard_providers.dart';
import 'dashboard_colors.dart';

class AdsStatisticsPanel extends ConsumerWidget {
  const AdsStatisticsPanel({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;
    final seriesAsync = ref.watch(adsSeriesProvider);
    final l10n = AppLocalizations.of(context);

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
                  l10n.dashboardAdsStatisticsTitle,
                  overflow: TextOverflow.ellipsis,
                  style: type.panelHeading.copyWith(color: colors.ink),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Blank while loading/error rather than a stale/guessed
              // caption — the real range is only known once the series
              // itself has loaded.
              Text(
                seriesAsync.maybeWhen(
                  data: (series) => _captionFor(l10n, series),
                  orElse: () => '',
                ),
                style: type.bodySmall.copyWith(color: colors.muted),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          seriesAsync.when(
            loading: () => const SizedBox(
              height: 120,
              child: Center(child: ShimmerBox(width: double.infinity, height: 120)),
            ),
            error: (error, stackTrace) => SizedBox(
              height: 120,
              child: Center(
                child: RailRetryCard(
                  width: 220,
                  message: l10n.dashboardAdsStatisticsLoadErrorMessage,
                  onRetry: () => ref.invalidate(adsSeriesProvider),
                ),
              ),
            ),
            data: (series) => _SeriesAreaChart(
              key: const ValueKey('adsStatisticsChart'),
              series: series,
            ),
          ),
        ],
      ),
    );
  }

  /// "Days 1–12" for a multi-bucket day-granularity series that stays
  /// within one calendar month (fixture mode always does, by construction —
  /// see `fixture_dashboard_repository.dart`'s doc comment; live mode may or
  /// may not); "Day 12" for a single bucket; falls back to a month/day (or
  /// hour) range once a series crosses a month boundary or is hourly, so
  /// the caption never claims a precision the data doesn't have.
  ///
  /// The month/day-only fallback (`"{month}/{day}"`) carries no English
  /// words to localize — a bare numeric date, unlike the "Hour"/"Hours"/
  /// "Day"/"Days" branches below — so only those four go through
  /// [AppLocalizations].
  static String _captionFor(AppLocalizations l10n, AdsSeries series) {
    final buckets = series.buckets;
    if (buckets.isEmpty) return '';

    if (series.granularity == SeriesGranularity.hour) {
      String hourLabel(DateTime dt) => '${dt.hour.toString().padLeft(2, '0')}:00';
      return buckets.length == 1
          ? l10n.dashboardCaptionHour(hourLabel(buckets.first.bucketStart))
          : l10n.dashboardCaptionHoursRange(
              hourLabel(buckets.first.bucketStart),
              hourLabel(buckets.last.bucketStart),
            );
    }

    final first = buckets.first.bucketStart;
    final last = buckets.last.bucketStart;
    final sameMonth = first.year == last.year && first.month == last.month;
    if (buckets.length == 1) {
      return sameMonth ? l10n.dashboardCaptionDay(first.day) : '${first.month}/${first.day}';
    }
    return sameMonth
        ? l10n.dashboardCaptionDaysRange(first.day, last.day)
        : '${first.month}/${first.day}–${last.month}/${last.day}';
  }
}

// ---------------------------------------------------------------------
// The chart itself — one implementation for both fixture and live mode.
// ---------------------------------------------------------------------

class _SeriesAreaChart extends StatelessWidget {
  const _SeriesAreaChart({super.key, required this.series});

  final AdsSeries series;

  /// How many axis labels to show at most — the original static fixture
  /// chart showed 7 of its 12 points ("1,3,5,7,9,11,12"); this keeps the
  /// same rough density for series of any length instead of crowding every
  /// bucket's label onto the axis.
  static const int _maxLabels = 7;

  List<int> _labelIndices(int bucketCount) {
    if (bucketCount <= _maxLabels) {
      return List.generate(bucketCount, (i) => i);
    }
    final step = (bucketCount - 1) / (_maxLabels - 1);
    final indices = <int>{};
    for (var i = 0; i < _maxLabels; i++) {
      indices.add((i * step).round());
    }
    return indices.toList()..sort();
  }

  String _axisLabel(DateTime bucketStart, bool sameMonth) {
    if (series.granularity == SeriesGranularity.hour) {
      return '${bucketStart.hour.toString().padLeft(2, '0')}:00';
    }
    // Day granularity: bare day-of-month when every bucket falls in one
    // month (fixture mode always does; live mode often does) — matches
    // this chart's original "1,3,5,..." look. Once a series crosses a
    // month boundary, disambiguate with the month too rather than show two
    // different days with the same bare number.
    return sameMonth
        ? '${bucketStart.day}'
        : '${bucketStart.month}/${bucketStart.day}';
  }

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    final buckets = series.buckets;
    if (buckets.isEmpty) {
      // A caller-side validation error (see `StatisticsResource.series`'s
      // doc comment) surfaces through the `error` branch above, not this
      // one — an empty-but-successful response is a real, if unusual,
      // outcome (e.g. a range with truly zero activity would still
      // zero-fill every bucket, so this only fires for a genuinely
      // bucket-less response) and gets an honest empty state rather than a
      // blank 120px box.
      return SizedBox(
        height: 120,
        child: Center(
          child: Text(
            AppLocalizations.of(context).dashboardNoDataForRangeMessage,
            style: type.bodySmall.copyWith(color: colors.muted),
          ),
        ),
      );
    }

    final first = buckets.first.bucketStart;
    final last = buckets.last.bucketStart;
    final sameMonth = first.year == last.year && first.month == last.month;
    final labelIndices = _labelIndices(buckets.length);

    return Column(
      children: [
        SizedBox(
          height: 120,
          width: double.infinity,
          child: CustomPaint(
            painter: _DualSeriesChartPainter(
              created: buckets.map((b) => b.adCreatedCount).toList(),
              sold: buckets.map((b) => b.adSoldCount).toList(),
              createdColor: AppAccent.color,
              soldColor: kDashboardSoldColor,
              gridColor: colors.line,
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: labelIndices
              .map(
                (i) => Text(
                  _axisLabel(buckets[i].bucketStart, sameMonth),
                  style: type.micro.copyWith(color: colors.faint),
                ),
              )
              .toList(),
        ),
        const SizedBox(height: AppSpacing.base),
        Row(
          children: [
            _LegendDot(
              color: AppAccent.color,
              label: AppLocalizations.of(context).dashboardLegendCreated,
            ),
            const SizedBox(width: AppSpacing.lg),
            _LegendDot(
              color: kDashboardSoldColor,
              label: AppLocalizations.of(context).dashboardLegendSold,
            ),
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
    if (n == 0) return;
    if (n == 1) {
      // A single-bucket series (e.g. the "Today" filter, whose range can
      // resolve to one bucket) has no line to draw — a dot at the one real
      // value beats either a blank chart or fabricating a second point.
      final y = size.height - (series[0] / maxValue) * size.height * 0.9;
      canvas.drawCircle(Offset(size.width / 2, y), 4, Paint()..color = color);
      return;
    }

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
