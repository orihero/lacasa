/// The real, network-backed [DashboardRepository] — thin adapter over
/// [LaCasaApi], adding no wire shapes of its own.
library;

import '../../../api/api.dart';
import 'dashboard_repository.dart';

class LiveDashboardRepository implements DashboardRepository {
  const LiveDashboardRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<AdsStatistics> fetchAdsStatistics(StatisticsFilter filter) =>
      _api.statistics.ads(filterType: filter);

  /// **[StatisticsFilter.all] is remapped to [StatisticsFilter.thisMonth]
  /// here — confirmed live against a running `apps/api`, not just read from
  /// its source.** `StatisticsResource.series`'s own doc comment already
  /// says the server has no all-time option for a *bucketed* series (only
  /// the scalar `/statistics/ads` totals get one) and silently defaults to
  /// `today` when `filterType` is omitted — which is exactly what sending
  /// [StatisticsFilter.all]'s `wireOrNull` (`null`) does. Left alone, that
  /// makes `dashboard`'s "All" time-range pick show correct all-time stat
  /// tiles (`fetchAdsStatistics`, above, has a real all-time mode) right next
  /// to a chart quietly showing only today — the same screen disagreeing
  /// with itself about what "All" means, with nothing in the response
  /// shape signalling the substitution happened. `thisMonth` is not
  /// arbitrary: it is this screen's own already-established "biggest sane
  /// default" (`DashboardTimeRangeNotifier.build()`), and it is exactly what
  /// [FixtureDashboardRepository.fetchAdsSeries] already does for `.all` —
  /// this fixes live mode to match fixture mode's existing (correct) choice
  /// rather than inventing a new one.
  @override
  Future<AdsSeries> fetchAdsSeries(StatisticsFilter filter) => _api.statistics
      .series(
        filterType: filter == StatisticsFilter.all
            ? StatisticsFilter.thisMonth
            : filter,
      );

  @override
  Future<List<ActivityEvent>> fetchCoworkerActivity() =>
      _api.statistics.coworkers();

  /// `AgentAdsResource.myList()` — every stage, no pagination (see that
  /// method's own doc comment). No [AdFilters] passed: the dashboard wants
  /// the caller's complete ad set to fold client-side, not a narrowed page.
  @override
  Future<List<Ad>> fetchAllAds() => _api.agentAds.myList();

  @override
  Future<List<Lead>> fetchAllLeads() => _api.leads.list();

  @override
  Future<List<Coworker>> fetchCoworkers() => _api.coworkers.list();
}
