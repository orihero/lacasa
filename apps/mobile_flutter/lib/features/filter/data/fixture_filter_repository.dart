/// Offline stand-in for [FilterRepository], backed by
/// `filter_ads_fixtures.dart`'s SCREENS.md §4.1 seed data. No network, no
/// [LaCasaApi] dependency — matches every other fixture repository in this
/// codebase (build spec: "must render sensibly with NO network available").
///
/// Filtering logic mirrors `apps/api/src/services/adService.js`'s
/// `buildAdFilters`/`listAds` exactly: city/district/category/type/rooms/
/// repairment/storey/furniture are exact-match, area/price are inclusive
/// ranges (`gte`/`lte`), and — matching `listAds`'s own `agentId ? {} :
/// {stage: "ACTIVE"}` branch — a non-agent-scoped query (the only kind
/// this feature ever issues) is always narrowed to `stage: "ACTIVE"`
/// first, regardless of what the caller's filters ask for.
library;

import '../../../api/api.dart';
import 'filter_ads_fixtures.dart';
import 'filter_repository.dart';

class FixtureFilterRepository implements FilterRepository {
  const FixtureFilterRepository();

  @override
  Future<int> countMatching(AdFilters filters) async {
    return filterFixtureAds.where((ad) => _matches(ad, filters)).length;
  }

  bool _matches(Ad ad, AdFilters filters) {
    if (ad.stage != AdStage.active) return false;
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
