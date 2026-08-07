/// The real, network-backed [SearchRepository] — thin adapter over
/// [LaCasaApi], adding no wire shapes of its own (same rule
/// `live_home_feed_repository.dart` follows). No sort/search/pagination
/// params are sent, because `AdsResource`/`AdFilters` don't expose them —
/// see `search_repository.dart`'s doc comment for why.
library;

import '../../../api/api.dart';
import 'search_repository.dart';

class LiveSearchRepository implements SearchRepository {
  const LiveSearchRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<List<Ad>> fetchResults({AdFilters filters = const AdFilters()}) {
    return _api.ads.list(filters: filters);
  }
}
