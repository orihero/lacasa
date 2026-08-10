/// The real, network-backed [MyListingsRepository] — thin adapter over
/// [LaCasaApi], adding no wire shapes of its own (same rule
/// `live_search_repository.dart` follows). [AgentAdsResource.myList]/
/// [CoworkersResource.list] are already exactly the shapes this feature
/// needs, so this file has nothing to translate.
library;

import '../../../api/api.dart';
import 'my_listings_repository.dart';

class LiveMyListingsRepository implements MyListingsRepository {
  const LiveMyListingsRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<List<Ad>> fetchMyAds({
    AdFilters filters = const AdFilters(),
    AdSort sort = AdSort.newest,
  }) {
    return _api.agentAds.myList(filters: filters, sort: sort);
  }

  @override
  Future<List<Coworker>> fetchCoworkers() => _api.coworkers.list();
}
