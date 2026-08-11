/// A controllable [DashboardRepository] fake for widget tests — no network,
/// no fixture-file coupling. [adsStatisticsByFilter] lets a test hand back a
/// different [AdsStatistics] per [StatisticsFilter], so the time-range
/// selector's re-fetch can be asserted against a value that visibly changes.
/// [adsSeriesByFilter] does the same for [fetchAdsSeries].
///
/// **[fetchAdsSeries] deliberately does *not* remap [StatisticsFilter.all] to
/// `.thisMonth` the way [LiveDashboardRepository] does.** That substitution
/// is documented there as a live-wire-only workaround for the bucketed
/// `/statistics/ads/series` endpoint having no all-time mode — it is not part
/// of the [DashboardRepository] contract itself, and [AdsSeriesNotifier]
/// passes whatever filter [dashboardTimeRangeProvider] holds straight
/// through, [StatisticsFilter.all] included. If this fake silently coalesced
/// `.all` into the `.thisMonth` entry of [adsSeriesByFilter], any test built
/// on top of it would be unable to tell "the provider passed `.all`, as it
/// should" apart from "the provider incorrectly passed `.thisMonth`" — both
/// would read the same map entry and render identically. Recording the raw
/// filter in [adsSeriesFilterCalls] (mirroring [adsStatisticsFilterCalls]'s
/// own no-remapping behaviour) keeps that distinction assertable; the actual
/// `.all` → `.thisMonth` remap is [LiveDashboardRepository]'s concern alone
/// and belongs in a test that exercises that class directly.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/work_dashboard/data/dashboard_repository.dart';

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({
    Map<StatisticsFilter, AdsStatistics>? adsStatisticsByFilter,
    Map<StatisticsFilter, AdsSeries>? adsSeriesByFilter,
    List<ActivityEvent>? coworkerActivity,
    List<Ad>? ads,
    List<Lead>? leads,
    List<Coworker>? coworkers,
    this.adsStatisticsError,
    this.adsSeriesError,
    this.coworkerActivityError,
    this.adsError,
    this.leadsError,
    this.coworkersError,
  }) : adsStatisticsByFilter = adsStatisticsByFilter ?? const {},
       adsSeriesByFilter = adsSeriesByFilter ?? const {},
       coworkerActivity = coworkerActivity ?? const [],
       ads = ads ?? const [],
       leads = leads ?? const [],
       coworkers = coworkers ?? const [];

  final Map<StatisticsFilter, AdsStatistics> adsStatisticsByFilter;
  final Map<StatisticsFilter, AdsSeries> adsSeriesByFilter;
  final List<ActivityEvent> coworkerActivity;
  final List<Ad> ads;
  final List<Lead> leads;
  final List<Coworker> coworkers;

  final Object? adsStatisticsError;
  final Object? adsSeriesError;
  final Object? coworkerActivityError;
  final Object? adsError;
  final Object? leadsError;
  final Object? coworkersError;

  int adsStatisticsCallCount = 0;
  final List<StatisticsFilter> adsStatisticsFilterCalls = [];
  int adsSeriesCallCount = 0;
  final List<StatisticsFilter> adsSeriesFilterCalls = [];
  int coworkersCallCount = 0;
  int leadsCallCount = 0;
  int adsCallCount = 0;

  @override
  Future<AdsStatistics> fetchAdsStatistics(StatisticsFilter filter) async {
    adsStatisticsCallCount++;
    adsStatisticsFilterCalls.add(filter);
    if (adsStatisticsError != null) throw adsStatisticsError!;
    return adsStatisticsByFilter[filter] ??
        const AdsStatistics(adsNewCount: 0, adsSoldCount: 0);
  }

  @override
  Future<AdsSeries> fetchAdsSeries(StatisticsFilter filter) async {
    adsSeriesCallCount++;
    adsSeriesFilterCalls.add(filter);
    if (adsSeriesError != null) throw adsSeriesError!;
    return adsSeriesByFilter[filter] ?? _defaultAdsSeries;
  }

  /// The series a test gets when it doesn't bother configuring
  /// [adsSeriesByFilter] for the filter in play — most of
  /// `dashboard_screen_test.dart`'s cases only care about the stat tiles or
  /// the coworker section, not the chart. 12 buckets, day granularity, dated
  /// the 1st–12th of a fixed reference month (the same `DateTime.utc(2024,
  /// 3, day)` anchor [FixtureDashboardRepository] uses) so
  /// `ads_statistics_panel.dart`'s caption renders the legacy-familiar "Days
  /// 1–12" the "static 12-point chart" test asserts on, without this fake
  /// reaching into `lib/shared/fixtures/work_seed_data.dart` for it. Counts
  /// are honestly zero rather than fabricated — [AdsSeries]'s own doc
  /// comment already establishes that a zero-filled bucket is a legitimate
  /// real response shape, not a placeholder that needs faking believable
  /// numbers.
  static final AdsSeries _defaultAdsSeries = AdsSeries(
    granularity: SeriesGranularity.day,
    from: DateTime.utc(2024, 3, 1),
    to: DateTime.utc(2024, 3, 12),
    buckets: List.generate(
      12,
      (i) => AdsSeriesBucket(
        bucketStart: DateTime.utc(2024, 3, i + 1),
        adCreatedCount: 0,
        adSoldCount: 0,
      ),
      growable: false,
    ),
  );

  @override
  Future<List<ActivityEvent>> fetchCoworkerActivity() async {
    if (coworkerActivityError != null) throw coworkerActivityError!;
    return coworkerActivity;
  }

  @override
  Future<List<Ad>> fetchAllAds() async {
    adsCallCount++;
    if (adsError != null) throw adsError!;
    return ads;
  }

  @override
  Future<List<Lead>> fetchAllLeads() async {
    leadsCallCount++;
    if (leadsError != null) throw leadsError!;
    return leads;
  }

  @override
  Future<List<Coworker>> fetchCoworkers() async {
    coworkersCallCount++;
    if (coworkersError != null) throw coworkersError!;
    return coworkers;
  }
}
