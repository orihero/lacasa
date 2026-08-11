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
/// returns every stage for the caller's own ads unless [stage] narrows it,
/// and [workAdsFixtures] itself already includes `ad-1005` (Sold) and
/// `ad-1007` (Draft) for exactly that reason (see that fixture list's own
/// doc comment).
///
/// **Honest offline paging**: [fetchMyAdsPage]'s `cursor` is this fixture's
/// own opaque stand-in — the matched-and-sorted list's next start index, as
/// a string — genuinely sliced by [limit] the same shape the real
/// `{ items, nextCursor }` envelope takes, not a fake "one big page"
/// shortcut. It only has to agree with itself (this instance's own
/// deterministic sort), never with the server's actual keyset cursor
/// format, since a fixture-mode `cursor` is never sent to a real server.
library;

import '../../../api/api.dart';
import '../../../shared/shared.dart';
import 'my_listings_repository.dart';

class FixtureMyListingsRepository implements MyListingsRepository {
  const FixtureMyListingsRepository();

  @override
  Future<AdPage> fetchMyAdsPage({
    AdFilters filters = const AdFilters(),
    AdListSort sort = AdListSort.newest,
    AdStage? stage,
    int? limit,
    String? cursor,
  }) async {
    final matched = workAdsFixtures
        .where(
          (ad) => _matches(ad, filters) && (stage == null || ad.stage == stage),
        )
        .toList();
    matched.sort((a, b) {
      return switch (sort) {
        AdListSort.newest => b.createdAt.compareTo(a.createdAt),
        AdListSort.oldest => a.createdAt.compareTo(b.createdAt),
        AdListSort.priceAsc => a.price.compareTo(b.price),
        AdListSort.priceDesc => b.price.compareTo(a.price),
        AdListSort.areaAsc => (a.area ?? 0).compareTo(b.area ?? 0),
        AdListSort.areaDesc => (b.area ?? 0).compareTo(a.area ?? 0),
      };
    });

    final start = cursor == null ? 0 : (int.tryParse(cursor) ?? 0);
    // A forged/garbled cursor is "start from the top" here too, mirroring
    // the real server's own stated behavior for one (see [AdPage]'s doc
    // comment) rather than throwing on it.
    final safeStart = start < 0 || start > matched.length ? 0 : start;
    final end = limit == null
        ? matched.length
        : (safeStart + limit).clamp(0, matched.length);
    final items = matched.sublist(safeStart, end);
    final nextCursor = end < matched.length ? end.toString() : null;
    return AdPage(items: items, nextCursor: nextCursor);
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
