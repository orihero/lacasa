/// The real, network-backed [FilterRepository] — thin adapter over
/// [LaCasaApi], adding no wire shapes of its own. `AdsResource.count` is
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
  Future<int> countMatching(AdFilters filters) {
    // `AdsResource.count`, not `list(...).length`. The two ask the server
    // the same question with the same `where`, but the bare-array branch of
    // `GET /ads` has no `take` at all — it answers with every matching row,
    // fully serialized, photo URLs included. This method runs once when the
    // sheet opens and again 300ms after every chip tap and every price/area/
    // storey keystroke, so paying a whole-catalogue download per edit to
    // render one integer was a cost that grew with the catalogue while the
    // answer never got bigger than an int.
    return _api.ads.count(filters: filters);
  }
}
