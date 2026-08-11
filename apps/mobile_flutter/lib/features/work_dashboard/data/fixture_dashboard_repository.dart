/// Offline stand-in for [DashboardRepository], backed by
/// `lib/shared/fixtures/work_seed_data.dart`'s SCREENS.md §4 seed data. No
/// network, no [LaCasaApi] dependency — this is what `dashboard` renders
/// from by default (see `dashboard_mode.dart`).
///
/// **`fetchAdsStatistics`'s two fixture sources don't reconcile, and that's
/// deliberate, not a bug to "fix" by deriving one from the other.**
/// [workDashboardStatsFixture] (§4.5) is the literal "this month" totals
/// table (42 created / 11 sold); [workDashboardChartFixture] (§4.6) is a
/// literal 12-day series whose own doc comment says day 12 is "today" and
/// the real month-end total keeps accumulating past it — the two are not
/// meant to sum to each other. So: [StatisticsFilter.thisMonth] (the
/// screen's default) returns §4.5's own figures verbatim, matching the seed
/// data's own labelling exactly; the other three range options don't have a
/// same-labelled fixture at all, so they fold whatever days of §4.6's
/// series the selected range actually covers (all 12 days / the last 7 /
/// day 12 alone) — genuine fixture data, not fabricated, just a different
/// (and honestly smaller-looking) slice than the "this month" headline
/// figure. This is also why the time-range selector visibly does something
/// in fixture mode instead of silently ignoring every option but the default.
///
/// **`fetchAdsSeries` always plots §4.6's per-day points, regardless of
/// filter** — [_pointsForFilter] is the same day-slicing [fetchAdsStatistics]
/// uses for every filter but `thisMonth` (a chart has nothing to plot §4.5's
/// flat totals against, so that special case doesn't apply here). Each
/// [WorkDashboardChartPoint.day] (1–12) is mapped onto a synthetic calendar
/// date via [_dateForDay] purely so [AdsSeriesBucket.bucketStart] has
/// *something* real to hold — day 1 lands on the 1st of a fixed reference
/// month so the axis labels below (`widgets/ads_statistics_panel.dart`) show
/// the exact same "1..12" numbers this screen has always shown, not because
/// any of these dates mean anything.
library;

import '../../../api/api.dart';
import '../../../shared/fixtures/work_seed_data.dart';
import 'dashboard_repository.dart';

class FixtureDashboardRepository implements DashboardRepository {
  const FixtureDashboardRepository();

  @override
  Future<AdsStatistics> fetchAdsStatistics(StatisticsFilter filter) async {
    if (filter == StatisticsFilter.thisMonth) {
      return AdsStatistics(
        adsNewCount: workDashboardStatsFixture.adsCreatedThisMonth,
        adsSoldCount: workDashboardStatsFixture.adsSoldThisMonth,
      );
    }

    final points = _pointsForFilter(filter);
    return AdsStatistics(
      adsNewCount: points.fold<int>(0, (sum, p) => sum + p.created),
      adsSoldCount: points.fold<int>(0, (sum, p) => sum + p.sold),
    );
  }

  @override
  Future<AdsSeries> fetchAdsSeries(StatisticsFilter filter) async {
    final buckets = _pointsForFilter(filter)
        .map(
          (p) => AdsSeriesBucket(
            bucketStart: _dateForDay(p.day),
            adCreatedCount: p.created,
            adSoldCount: p.sold,
          ),
        )
        .toList(growable: false);

    return AdsSeries(
      granularity: SeriesGranularity.day,
      from: buckets.first.bucketStart,
      to: buckets.last.bucketStart,
      buckets: buckets,
    );
  }

  /// Same slice §4.6's 12 points get for every filter but `thisMonth`
  /// (which [fetchAdsStatistics] special-cases to §4.5's own totals instead
  /// — see this file's doc comment).
  List<WorkDashboardChartPoint> _pointsForFilter(StatisticsFilter filter) {
    switch (filter) {
      case StatisticsFilter.today:
        return [workDashboardChartFixture.last];
      case StatisticsFilter.thisWeek:
        return workDashboardChartFixture.length <= 7
            ? workDashboardChartFixture
            : workDashboardChartFixture.sublist(
                workDashboardChartFixture.length - 7,
              );
      case StatisticsFilter.all:
      case StatisticsFilter.thisMonth:
        return workDashboardChartFixture;
    }
  }

  /// Day 1 of a fixed, arbitrary reference month (chosen only so every
  /// `day` 1–12 lands in the same calendar month, and therefore renders as
  /// the bare "1".."12" the fixture chart has always shown — see this
  /// file's doc comment).
  static DateTime _dateForDay(int day) => DateTime.utc(2024, 3, day);

  @override
  Future<List<ActivityEvent>> fetchCoworkerActivity() async =>
      workStatisticsCoworkersFixture;

  @override
  Future<List<Ad>> fetchAllAds() async => workAdsFixtures;

  @override
  Future<List<Lead>> fetchAllLeads() async => workLeadsFixtures;

  @override
  Future<List<Coworker>> fetchCoworkers() async => workCoworkersFixtures;
}
