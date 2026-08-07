/// The real, network-backed [HomeFeedRepository] — thin adapter over
/// [LaCasaApi], adding no wire shapes of its own (build spec requirement:
/// "fetch through the existing API client, no duplicated model classes").
library;

import '../../../api/api.dart';
import 'home_feed_repository.dart';

class LiveHomeFeedRepository implements HomeFeedRepository {
  const LiveHomeFeedRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<List<Ad>> fetchFeed() => _api.ads.list();

  @override
  Future<List<AgentSummary>> fetchTopAgents() async {
    final agents = await _api.agents.list();
    final sorted = [...agents]
      ..sort((a, b) => b.adsCount.compareTo(a.adsCount));
    return sorted.take(5).toList();
  }
}
