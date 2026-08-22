/// SCREENS.md §24's "Ads statistics" panel — an area chart, series "Created"
/// / "Sold", matching `mockup-e-liquid-glass.html`'s `.panel` (the 12-point
/// SVG path with `#f5439b`/`#5a5ac8` gradients).
///
/// **One rendering path, driven by a real [AdsSeries] — contract ruling 7.1
/// is closed.** `GET /statistics/ads/series` returns a real, server-bucketed
/// day/hour series (`data/dashboard_repository.dart`'s `fetchAdsSeries`), so
/// the fixture-vs-live fork this file used to carry is gone, along with the
/// fixture repositories and the compile-time switch that chose between them:
/// there is exactly one `DashboardRepository` implementation now
/// (`LiveDashboardRepository`) and one chart. [_SeriesAreaChart] — named
/// `_FixtureAreaChart` while it plotted seed points — draws
/// [adsSeriesProvider]'s data with the same `CustomPainter` this screen has
/// always used; `apps/console` made the same call not to pull in a charting
/// library for one screen, and matching it is deliberate.
/// [AdsSeries.granularity] (`hour`/`day`) drives the axis-label format below
/// rather than assuming every series is daily.
///
/// **The chart states its own scale and summarises itself out loud.** The
/// series was normalized against a `maxValue` computed inside `paint` and
/// never surfaced, so a peak of 4 and a peak of 400 drew the identical
/// shape, and the `CustomPaint` emitted no semantics at all — a silent hole
/// on a screen where every other figure is labelled. [_peakValueOf] is now
/// computed in `build`, printed on the plot as up to two right-aligned
/// `micro` ticks, and folded into a one-sentence [Semantics] label with the
/// range and both series' totals. Still no charting library: `apps/console`
/// made the same call for the same one screen, and two ticks plus a
/// sentence is not a reason to reverse it.
///
/// **A quiet month prints 0, not 1.** That peak used to be floored at 1 so
/// it could always divide, which is a lie the moment it is *printed*: an
/// all-zero range — an ordinary quiet month, and the shape of a genuine
/// zero-filled response — drew a top tick reading "1" over a flat baseline,
/// a scale nothing in the series reaches. The floor now lives in
/// [_dyForValue] and the painter, which are the only places a zero divisor
/// is actually a problem, so the tick is free to print the real peak.
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
    final filter = ref.watch(dashboardTimeRangeProvider);
    final l10n = AppLocalizations.of(context);
    final caption = seriesAsync.maybeWhen(
      data: (series) => _captionFor(l10n, series, filter),
      orElse: () => '',
    );

    // `.panel{background:var(--card);border-radius:22px;padding:16px 14px;
    // box-shadow:0 12px 26px -22px rgba(30,24,44,.6)}` — a solid card, not
    // a glass lens: the mockup marks none of its three `.panel`s `gl`, and
    // the contrast against the glass `.tile gl` grid above is deliberate.
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppRadii.cardLg),
        boxShadow: AppShadows.card,
      ),
      padding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: AppSpacing.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Both halves are flex, and both may wrap to a second line. The
          // caption used to be a fixed-width child laid out first, which
          // left the title whatever was over — including nothing at all
          // once the caption grew: ru's "Дни 1–12 · на графике этот месяц"
          // is wider than half a 360dp panel on its own. 3:4 rather than
          // 1:1 because the caption is the longer string in every locale.
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  l10n.dashboardAdsStatisticsTitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: type.panelHeading.copyWith(color: colors.ink),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              // Blank while loading/error rather than a stale/guessed
              // caption — the real range is only known once the series
              // itself has loaded.
              Expanded(
                flex: 4,
                child: Text(
                  caption,
                  textAlign: TextAlign.right,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  // The caption is `<span class="link">Days 1–12</span>`:
                  // `.link{font-size:11.5px;font-weight:500;
                  // color:var(--muted)}` — rendered the way `SectionHeader`
                  // already resolves this rule, `specMeta` (10.5/500)
                  // resized to 11.5.
                  style: type.specMeta.copyWith(
                    fontSize: 11.5,
                    color: colors.muted,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.base),
          seriesAsync.when(
            loading: () => const SizedBox(
              height: _kChartHeight,
              child: Center(
                child: ShimmerBox(
                  width: double.infinity,
                  height: _kChartHeight,
                ),
              ),
            ),
            // A *floor*, not the fixed [_kChartHeight] box the chart and the
            // shimmer get. [RailRetryCard] does not fit in 120dp any more:
            // 16+16 of padding, a 22dp icon, a 6dp gap, one line of message
            // and the shared Retry's 48dp tap target already come to ~113dp,
            // and the message wraps to a second line at this width in ru and
            // uz ("Не удалось загрузить статистику объявлений"), which
            // overflows. Keeping the 120 as a minimum stops the panel
            // visibly shrinking when the fetch fails; letting it grow past
            // that is what keeps the card whole.
            error: (error, stackTrace) => ConstrainedBox(
              constraints: const BoxConstraints(minHeight: _kChartHeight),
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
              rangeLabel: caption,
            ),
          ),
        ],
      ),
    );
  }

  /// "Days 1–12" for a multi-bucket day-granularity series that stays
  /// within one calendar month (which the `today`/`thisWeek`/`thisMonth`
  /// ranges usually but not always do — a week can straddle a month
  /// boundary); "Day 12" for a single bucket; falls back to a month/day (or
  /// hour) range once a series crosses a month boundary or is hourly, so
  /// the caption never claims a precision the data doesn't have.
  ///
  /// The month/day-only fallback (`"{month}/{day}"`) carries no English
  /// words to localize — a bare numeric date, unlike the "Hour"/"Hours"/
  /// "Day"/"Days" branches below — so only those four go through
  /// [AppLocalizations].
  ///
  /// **[StatisticsFilter.all] says so out loud.** `GET
  /// /statistics/ads/series` has no all-time bucketed mode, so
  /// [LiveDashboardRepository.fetchAdsSeries] substitutes `thisMonth` for it
  /// (see that method's own doc comment for why, and why the substitution
  /// stays); the stat tiles above meanwhile keep showing genuine all-time
  /// totals from a different endpoint that does have one. Printing the
  /// plotted span alone ("Days 1–12") was true but not *sufficient* — a
  /// reader who picked "All" has no way to tell whether those twelve days
  /// are the whole history or one month of it. Wrapping the span in
  /// [AppLocalizations.dashboardCaptionAllTimeChartNote] states the
  /// substitution in the one place that already describes what is on the
  /// canvas. Dropping the "All" chip instead would have cost the tiles their
  /// real all-time numbers, which is the more useful half.
  static String _captionFor(
    AppLocalizations l10n,
    AdsSeries series,
    StatisticsFilter filter,
  ) {
    final span = _spanCaptionFor(l10n, series);
    if (span.isEmpty || filter != StatisticsFilter.all) return span;
    return l10n.dashboardCaptionAllTimeChartNote(span);
  }

  /// The plotted span on its own — see [_captionFor], which wraps it.
  static String _spanCaptionFor(AppLocalizations l10n, AdsSeries series) {
    final buckets = series.buckets;
    if (buckets.isEmpty) return '';

    if (series.granularity == SeriesGranularity.hour) {
      String hourLabel(DateTime dt) =>
          '${dt.hour.toString().padLeft(2, '0')}:00';
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
      return sameMonth
          ? l10n.dashboardCaptionDay(first.day)
          : '${first.month}/${first.day}';
    }
    return sameMonth
        ? l10n.dashboardCaptionDaysRange(first.day, last.day)
        : '${first.month}/${first.day}–${last.month}/${last.day}';
  }
}

// ---------------------------------------------------------------------
// The chart itself.
// ---------------------------------------------------------------------

/// The chart canvas's height — the fixed box the plot and its loading
/// shimmer get. Shared by the painter's geometry and by the y-tick labels
/// stacked over it, which have to resolve the same `value → dy` mapping the
/// painter draws with. The error branch treats it as a floor instead; see
/// the `ConstrainedBox` above.
const double _kChartHeight = 120;

/// The share of [_kChartHeight] the plot itself uses — the remaining tenth
/// is headroom above the tallest point, matching the mockup's own
/// top-8px-of-120 gap so a peak never touches the panel's top edge.
const double _kPlotFraction = 0.9;

/// The scale both series are drawn against: the tallest value in either,
/// **including a perfectly honest 0**.
///
/// Computed in `build` and passed *into* the painter rather than derived
/// inside `paint`, because it is the number the y-ticks print — a value the
/// chart was normalizing against and never stating, which is exactly why a
/// peak of 4 and a peak of 400 used to render identically.
///
/// It used to be `math.max(1, …)`, floored so the `value / maxValue`
/// division could never blow up. That floor was invisible while the number
/// only scaled a path; the moment it became printed text it started
/// claiming a magnitude the data never had — an all-zero month (an ordinary
/// quiet month, and the shape of a genuine zero-filled response) drew a top
/// tick reading "1" above a flat baseline. The guard moved to the two
/// places that actually divide by it ([_dyForValue] and the painter's own
/// `_dy`), which map every value in a zero series onto the baseline, where
/// it belongs.
int _peakValueOf(List<int> created, List<int> sold) =>
    [...created, ...sold].fold(0, math.max);

/// Where [value] sits inside a [_kChartHeight]-tall canvas. An all-zero
/// series ([maxValue] 0) has no scale to divide by and every point sits on
/// the baseline — see [_peakValueOf].
double _dyForValue(int value, int maxValue) => maxValue <= 0
    ? _kChartHeight
    : _kChartHeight - (value / maxValue) * _kChartHeight * _kPlotFraction;

/// One right-aligned magnitude printed on the plot — the whole of this
/// chart's y axis, which had none.
///
/// **It sits at its own value's plotted height, not on a grid line.** The
/// four guides are evenly spaced decoration inherited from the mockup, and
/// the plot reserves [_kPlotFraction]'s tenth of headroom above the peak, so
/// the topmost guide is not `maxValue` and no guide is exactly half of it.
/// A tick that lined up with a guide would therefore have to lie about its
/// own number; lining it up with the height the number actually plots at is
/// the version a reader can measure a curve against.
///
/// **It carries its own card-coloured backing.** The plot spans the panel's
/// full width, so the last bucket's point sits exactly under `right: 0` —
/// where this label is — and the top tick sits exactly at the peak's own
/// height. A series that ends on (or near) its peak therefore draws a
/// 2.4dp stroke and a gradient fill straight through the one number that
/// states the scale. Reserving a gutter for the axis would shorten the plot
/// on every chart to fix a collision that only some of them have; a 2dp
/// inset of [LaCasaColors.card] behind the digits keeps them readable
/// wherever the curve happens to run, and is invisible everywhere else
/// because it is the panel's own background colour.
class _YAxisTick extends StatelessWidget {
  const _YAxisTick({required this.value, required this.maxValue});

  final int value;
  final int maxValue;

  /// Half a `micro` line, so the label is centred on its value's height
  /// rather than hanging below it.
  static const double _halfLine = 6;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).extension<LaCasaColors>()!;
    final type = Theme.of(context).extension<LaCasaTypography>()!;

    return Positioned(
      top: (_dyForValue(value, maxValue) - _halfLine).clamp(
        0.0,
        _kChartHeight - 2 * _halfLine,
      ),
      right: 0,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 2),
          child: Text(
            '$value',
            key: ValueKey('adsStatisticsYTick-$value'),
            textAlign: TextAlign.right,
            maxLines: 1,
            style: LaCasaTypography.tabular(
              type.micro,
            ).copyWith(color: colors.faint),
          ),
        ),
      ),
    );
  }
}

class _SeriesAreaChart extends StatelessWidget {
  const _SeriesAreaChart({
    super.key,
    required this.series,
    required this.rangeLabel,
  });

  final AdsSeries series;

  /// The panel's own caption ("Days 1–12"), reused verbatim as the range
  /// half of this chart's spoken summary rather than re-derived — the two
  /// must name the same span, and there is only one right answer.
  final String rangeLabel;

  /// How many axis labels to show at most — the mockup's own static
  /// 12-point chart showed 7 of them ("1,3,5,7,9,11,12"); this keeps the
  /// same rough density for series of any length instead of crowding every
  /// bucket's label onto the axis.
  static const int _maxLabels = 7;

  /// The mockup's own axis for a 12-bucket series is `1,3,5,7,9,11,12` —
  /// six evenly-spaced buckets plus the final one, which is *not* the same
  /// as seven evenly-spaced buckets across the whole range (that lands on
  /// `1,3,5,7,8,10,12`, an obviously uneven axis). So the spacing is
  /// computed over everything *except* the last bucket, which is then
  /// always appended.
  List<int> _labelIndices(int bucketCount) {
    if (bucketCount <= _maxLabels) {
      return List.generate(bucketCount, (i) => i);
    }
    final step = (bucketCount - 2) / (_maxLabels - 2);
    final indices = <int>{};
    for (var i = 0; i < _maxLabels - 1; i++) {
      indices.add((i * step).floor());
    }
    indices.add(bucketCount - 1);
    return indices.toList()..sort();
  }

  String _axisLabel(DateTime bucketStart, bool sameMonth) {
    if (series.granularity == SeriesGranularity.hour) {
      return '${bucketStart.hour.toString().padLeft(2, '0')}:00';
    }
    // Day granularity: bare day-of-month when every bucket falls in one
    // month, which most ranges do — matches this chart's original
    // "1,3,5,..." look. Once a series crosses a month boundary,
    // disambiguate with the month too rather than show two different days
    // with the same bare number.
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
        height: _kChartHeight,
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

    final created = buckets.map((b) => b.adCreatedCount).toList();
    final sold = buckets.map((b) => b.adSoldCount).toList();
    // Lifted out of `paint`, where it used to be computed and discarded:
    // the ticks below and the painter must agree on the scale, and nothing
    // outside `paint` could see it.
    final maxValue = _peakValueOf(created, sold);
    // Half the scale, floored to an integer so the tick sits exactly at the
    // height of a value it can print without rounding. Suppressed when it
    // would collide with a tick already drawn — a `maxValue` of 1, where
    // half floors to the baseline, and an all-zero series, whose single
    // honest tick is the "0" the peak itself prints.
    final midValue = maxValue ~/ 2;

    return Column(
      children: [
        Semantics(
          // The canvas emitted nothing at all before this — the one
          // unlabelled thing on a screen where every tile, row and legend
          // is spoken. One sentence carrying the range and both totals is
          // the honest summary of two paths a reader cannot trace;
          // `excludeSemantics` keeps the y-ticks from being read as two
          // stray numbers on top of it.
          label: AppLocalizations.of(context).dashboardChartSemanticsLabel(
            rangeLabel,
            created.fold(0, (sum, value) => sum + value),
            sold.fold(0, (sum, value) => sum + value),
          ),
          excludeSemantics: true,
          child: SizedBox(
            height: _kChartHeight,
            width: double.infinity,
            child: Stack(
              children: [
                Positioned.fill(
                  child: CustomPaint(
                    painter: _DualSeriesChartPainter(
                      created: created,
                      sold: sold,
                      createdColor: AppAccent.color,
                      soldColor: kDashboardSoldColor,
                      gridColor: colors.line,
                      maxValue: maxValue,
                    ),
                  ),
                ),
                _YAxisTick(value: maxValue, maxValue: maxValue),
                if (midValue > 0 && midValue < maxValue)
                  _YAxisTick(value: midValue, maxValue: maxValue),
              ],
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
    required this.maxValue,
  });

  final List<int> created;
  final List<int> sold;
  final Color createdColor;
  final Color soldColor;
  final Color gridColor;

  /// The scale both series are normalized against — [_peakValueOf],
  /// computed by the caller so the y-ticks drawn over this canvas can print
  /// it. It used to be derived here and never leave `paint`. May legitimately
  /// be 0 (an all-zero series); [_dy] treats that as "everything sits on the
  /// baseline" rather than dividing by it.
  final int maxValue;

  @override
  void paint(Canvas canvas, Size size) {
    if (created.isEmpty) return;

    // 3 faint horizontal guides, matching the mockup's own 4-line grid.
    final gridPaint = Paint()
      ..color = gridColor
      ..strokeWidth = 1;
    for (var i = 0; i <= 3; i++) {
      final y = size.height * i / 3;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    _paintSeries(canvas, size, created, createdColor);
    _paintSeries(canvas, size, sold, soldColor);
  }

  /// [_kPlotFraction]'s tenth of headroom above the tallest point, matching
  /// the mockup's own top-8px-of-120 gap, so a peak never touches the
  /// panel's top edge. The same expression [_dyForValue] resolves for the
  /// y-ticks — they have to land on the curve's own scale. A [maxValue] of
  /// 0 has no scale: every point is the baseline.
  double _dy(int value, double height) => maxValue <= 0
      ? height
      : height - (value / maxValue) * height * _kPlotFraction;

  void _paintSeries(Canvas canvas, Size size, List<int> series, Color color) {
    final n = series.length;
    if (n == 0) return;
    if (n == 1) {
      // A single-bucket series (e.g. the "Today" filter, whose range can
      // resolve to one bucket) has no line to draw — a dot at the one real
      // value beats either a blank chart or fabricating a second point.
      canvas.drawCircle(
        Offset(size.width / 2, _dy(series[0], size.height)),
        4,
        Paint()..color = color,
      );
      return;
    }

    final dx = size.width / (n - 1);
    Offset pointAt(int i) => Offset(dx * i, _dy(series[i], size.height));

    final linePath = Path()..moveTo(0, pointAt(0).dy);
    for (var i = 1; i < n; i++) {
      linePath.lineTo(pointAt(i).dx, pointAt(i).dy);
    }

    final fillPath = Path.from(linePath)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = ui.Gradient.linear(Offset(0, 0), Offset(0, size.height), [
        color.withValues(alpha: 0.32),
        color.withValues(alpha: 0),
      ]);
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
        oldDelegate.maxValue != maxValue ||
        oldDelegate.createdColor != createdColor ||
        oldDelegate.soldColor != soldColor ||
        oldDelegate.gridColor != gridColor;
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

    // `.legend i{width:9px;height:9px;border-radius:3px}` — a rounded
    // square, not a dot — with a 6px gap and a 10.5px `--muted` label.
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: AppSpacing.sm),
        Text(label, style: type.specMeta.copyWith(color: colors.muted)),
      ],
    );
  }
}
