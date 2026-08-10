/// A controllable [DashboardRepository] fake for widget tests — no network,
/// no fixture-file coupling. [adsStatisticsByFilter] lets a test hand back a
/// different [AdsStatistics] per [StatisticsFilter], so the time-range
/// selector's re-fetch can be asserted against a value that visibly changes.
library;

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/work_dashboard/data/dashboard_repository.dart';

class FakeDashboardRepository implements DashboardRepository {
  FakeDashboardRepository({
    Map<StatisticsFilter, AdsStatistics>? adsStatisticsByFilter,
    List<ActivityEvent>? coworkerActivity,
    List<Ad>? ads,
    List<Lead>? leads,
    List<Coworker>? coworkers,
    this.adsStatisticsError,
    this.coworkerActivityError,
    this.adsError,
    this.leadsError,
    this.coworkersError,
  }) : adsStatisticsByFilter = adsStatisticsByFilter ?? const {},
       coworkerActivity = coworkerActivity ?? const [],
       ads = ads ?? const [],
       leads = leads ?? const [],
       coworkers = coworkers ?? const [];

  final Map<StatisticsFilter, AdsStatistics> adsStatisticsByFilter;
  final List<ActivityEvent> coworkerActivity;
  final List<Ad> ads;
  final List<Lead> leads;
  final List<Coworker> coworkers;

  final Object? adsStatisticsError;
  final Object? coworkerActivityError;
  final Object? adsError;
  final Object? leadsError;
  final Object? coworkersError;

  int adsStatisticsCallCount = 0;
  final List<StatisticsFilter> adsStatisticsFilterCalls = [];
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
