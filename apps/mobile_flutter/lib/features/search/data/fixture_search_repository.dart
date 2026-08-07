/// Offline stand-in for [SearchRepository], backed by
/// `search_fixtures.dart`'s SCREENS.md §4.1 seed data. No network, no
/// [LaCasaApi] dependency — what `listing-search` renders from by default
/// (see `search_mode.dart`), so the screen "must render sensibly with no
/// network available" the same way Home's own fixture repository does.
///
/// [_matchesFilters] mirrors `apps/api/src/services/adService.js#buildAdFilters`
/// field for field (exact-match on city/district/category/type/rooms/
/// repairment/storey/furniture, `gte`/`lte` range on area/price) plus the
/// unconditional `stage: "ACTIVE"` scope `listAds` applies whenever no
/// `agentId` is given — i.e. every public search. This repository has no
/// `agentId` parameter (this screen never needs one), so it always applies
/// that ACTIVE scope, exactly like the live endpoint always would for this
/// screen's calls.
library;

import '../../../api/api.dart';
import 'search_fixtures.dart';
import 'search_repository.dart';

class FixtureSearchRepository implements SearchRepository {
  const FixtureSearchRepository();

  @override
  Future<List<Ad>> fetchResults({AdFilters filters = const AdFilters()}) async {
    return searchFixtureAllAds
        .where((ad) => ad.stage == AdStage.active)
        .where((ad) => _matchesFilters(ad, filters))
        .toList();
  }

  bool _matchesFilters(Ad ad, AdFilters filters) {
    if (filters.city != null && ad.city != filters.city) return false;
    if (filters.district != null && ad.district != filters.district) {
      return false;
    }
    if (filters.category != null && ad.category != filters.category) {
      return false;
    }
    if (filters.type != null && ad.type != filters.type) return false;
    if (filters.rooms != null && ad.rooms != filters.rooms) return false;
    if (filters.repairment != null && ad.repairment != filters.repairment) {
      return false;
    }
    if (filters.storey != null && ad.storey != filters.storey) return false;
    if (filters.furniture != null && ad.furniture != filters.furniture) {
      return false;
    }
    if (filters.areaMin != null &&
        (ad.area == null || ad.area! < filters.areaMin!)) {
      return false;
    }
    if (filters.areaMax != null &&
        (ad.area == null || ad.area! > filters.areaMax!)) {
      return false;
    }
    if (filters.priceMin != null && ad.price < filters.priceMin!) {
      return false;
    }
    if (filters.priceMax != null && ad.price > filters.priceMax!) {
      return false;
    }
    return true;
  }
}
