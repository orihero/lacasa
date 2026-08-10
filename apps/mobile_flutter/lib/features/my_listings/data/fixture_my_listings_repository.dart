/// Offline stand-in for [MyListingsRepository], backed by
/// `work_seed_data.dart`'s [workAdsFixtures]/[workCoworkersFixtures] (build
/// contract §4.3). No network, no [LaCasaApi] dependency — what
/// `my-listings` renders from by default (see `my_listings_mode.dart`), so
/// the screen "must render sensibly with no network available" the same
/// way every other feature's fixture repository does.
///
/// [_matches] mirrors `apps/api/src/services/adService.js#buildAdFilters`
/// field for field — same algorithm
/// `features/search/data/fixture_search_repository.dart` uses for the
/// buyer feed — with one deliberate difference: **no unconditional
/// `stage: "ACTIVE"` scope**. `GET /my/ads` (unlike the public `GET /ads`)
/// returns every stage for the caller's own ads, and [workAdsFixtures]
/// itself already includes `ad-1005` (Sold) and `ad-1007` (Draft) for
/// exactly that reason (see that fixture list's own doc comment).
library;

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import 'my_listings_repository.dart';

class FixtureMyListingsRepository implements MyListingsRepository {
  const FixtureMyListingsRepository();

  @override
  Future<List<Ad>> fetchMyAds({
    AdFilters filters = const AdFilters(),
    AdSort sort = AdSort.newest,
  }) async {
    final matched = workAdsFixtures
        .where((ad) => _matches(ad, filters))
        .toList();
    matched.sort((a, b) {
      return switch (sort) {
        AdSort.highestPrice => b.price.compareTo(a.price),
        AdSort.lowestPrice => a.price.compareTo(b.price),
        AdSort.newest => b.createdAt.compareTo(a.createdAt),
      };
    });
    return matched;
  }

  @override
  Future<List<Coworker>> fetchCoworkers() async => workCoworkersFixtures;

  bool _matches(Ad ad, AdFilters filters) {
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
