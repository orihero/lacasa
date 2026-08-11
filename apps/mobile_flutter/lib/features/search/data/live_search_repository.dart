/// The real, network-backed [SearchRepository] — thin adapter over
/// [LaCasaApi], adding no wire shapes of its own (same rule
/// `live_home_feed_repository.dart` follows). Delegates straight to
/// `AdsResource.listPage`, which is what actually sends `q`/`sort` and opts
/// into the `{ items, nextCursor }` envelope (`paged=true`, always — see
/// that method's own doc comment).
library;

import '../../../api/api.dart';
import 'search_repository.dart';

class LiveSearchRepository implements SearchRepository {
  const LiveSearchRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<AdPage> fetchPage({
    AdFilters filters = const AdFilters(),
    AdListSort sort = AdListSort.newest,
    String? cursor,
  }) {
    return _api.ads.listPage(filters: filters, sort: sort, cursor: cursor);
  }
}
