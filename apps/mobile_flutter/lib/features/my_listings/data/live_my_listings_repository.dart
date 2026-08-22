/// The real, network-backed [MyListingsRepository] — thin adapter over
/// [LaCasaApi], adding no wire shapes of its own (same rule
/// `live_search_repository.dart` follows). [AgentAdsResource.myListPage],
/// [AgentAdsResource.stageCounts], [PublishResource.statusForAds] and
/// [CoworkersResource.list] are already exactly the shapes this feature
/// needs, so this file has nothing to translate.
library;

import '../../../api/api.dart';
import 'my_listings_repository.dart';

class LiveMyListingsRepository implements MyListingsRepository {
  const LiveMyListingsRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<AdPage> fetchMyAdsPage({
    AdFilters filters = const AdFilters(),
    AdListSort sort = AdListSort.newest,
    AdStage? stage,
    int? limit,
    String? cursor,
  }) {
    return _api.agentAds.myListPage(
      filters: filters,
      sort: sort,
      stage: stage,
      limit: limit,
      cursor: cursor,
    );
  }

  @override
  Future<AdStageCounts> fetchStageCounts() => _api.agentAds.stageCounts();

  @override
  Future<Map<String, List<ChannelStatus>>> fetchPublishStatuses(
    List<String> adIds,
  ) => _api.publish.statusForAds(adIds);

  @override
  Future<List<Coworker>> fetchCoworkers() => _api.coworkers.list();
}
