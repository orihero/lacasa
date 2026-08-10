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
