/// The real, network-backed [FilterRepository] — thin adapter over
/// [LaCasaApi], adding no wire shapes of its own. `AdsResource.list` is
/// already exactly the shape SCREENS.md's filter-sheet fields map to
/// (`AdFilters` — city/district/category/type/rooms/repairment/storey/
/// furniture/areaMin/areaMax/priceMin/priceMax), so this file has nothing
/// to translate.
library;

import '../../../api/api.dart';
import 'filter_repository.dart';

class LiveFilterRepository implements FilterRepository {
  const LiveFilterRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<int> countMatching(AdFilters filters) async {
    final ads = await _api.ads.list(filters: filters);
    return ads.length;
  }
}
