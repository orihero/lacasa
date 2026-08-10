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

    final List<WorkDashboardChartPoint> points;
    switch (filter) {
      case StatisticsFilter.today:
        points = [workDashboardChartFixture.last];
      case StatisticsFilter.thisWeek:
        points = workDashboardChartFixture.length <= 7
            ? workDashboardChartFixture
            : workDashboardChartFixture.sublist(
                workDashboardChartFixture.length - 7,
              );
      case StatisticsFilter.all:
      case StatisticsFilter.thisMonth:
        points = workDashboardChartFixture;
    }

    return AdsStatistics(
      adsNewCount: points.fold<int>(0, (sum, p) => sum + p.created),
      adsSoldCount: points.fold<int>(0, (sum, p) => sum + p.sold),
    );
  }

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
