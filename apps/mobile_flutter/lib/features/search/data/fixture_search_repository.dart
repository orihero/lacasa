/// Offline stand-in for [SearchRepository], backed by
/// `search_fixtures.dart`'s SCREENS.md §4.1 seed data. No network, no
/// [LaCasaApi] dependency — what `listing-search` renders from by default
/// (see `search_mode.dart`), so the screen "must render sensibly with no
/// network available" the same way Home's own fixture repository does.
///
/// **Mirrors the live endpoint's contract field for field**, not just its
/// shape: [_matchesFilters] mirrors
/// `apps/api/src/services/adService.js#buildAdFilters` (exact-match on
/// city/district/category/type/rooms/repairment/storey/furniture, `gte`/
/// `lte` range on area/price) plus the unconditional `stage: "ACTIVE"`
/// scope `listAds` applies whenever no `agentId` is given — i.e. every
/// public search. [_matchesQuery] mirrors `applySearch` (case-insensitive
/// substring, OR'd across title/description/address/district/city).
/// [_applySort] mirrors `SORT_WHITELIST` and, for the two nullable numeric
/// fields (`area`), `buildCursorWhere`'s null placement (nulls-first for a
/// `desc` sort, nulls-last for `asc` — the SQL-standard default Postgres/
/// Prisma apply, which this fixture reproduces rather than picking its own
/// convention). This repository has no `agentId` parameter (this screen
/// never needs one), so it always applies the ACTIVE scope, exactly like
/// the live endpoint always would for this screen's calls.
///
/// **Real, cursor-paged chunking** — [_pageSize] is deliberately smaller
/// than the 8-row fixture pool so `listing-search`'s infinite scroll
/// (`search_providers.dart`'s `SearchResultsNotifier.loadMore`) actually
/// exercises its paged-fetch-loop code path in fixture mode too, not only
/// against the live API. The cursor is a plain stringified offset into the
/// filtered+sorted list — opaque to every caller exactly as
/// [AdPage.nextCursor]'s contract requires, and a malformed one degrades to
/// "start from the top" (clamped to `0`), mirroring `decodeCursor`'s own
/// documented behavior for a garbled cursor server-side.
library;

import '../../../api/api.dart';
import 'search_fixtures.dart';
import 'search_repository.dart';

class FixtureSearchRepository implements SearchRepository {
  const FixtureSearchRepository();

  static const int _pageSize = 4;

  @override
  Future<AdPage> fetchPage({
    AdFilters filters = const AdFilters(),
    AdListSort sort = AdListSort.newest,
    String? cursor,
  }) async {
    var matched = searchFixtureAllAds
        .where((ad) => ad.stage == AdStage.active)
        .where((ad) => _matchesFilters(ad, filters))
        .toList();

    final q = filters.q?.trim();
    if (q != null && q.isNotEmpty) {
      matched = matched.where((ad) => _matchesQuery(ad, q)).toList();
    }

    final sorted = _applySort(matched, sort);

    final rawStart = cursor == null ? 0 : (int.tryParse(cursor) ?? 0);
    final start = rawStart.clamp(0, sorted.length);
    final end = (start + _pageSize).clamp(0, sorted.length);
    final nextCursor = end >= sorted.length ? null : end.toString();

    return AdPage(items: sorted.sublist(start, end), nextCursor: nextCursor);
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

  bool _matchesQuery(Ad ad, String q) {
    final needle = q.toLowerCase();
    return ad.title.toLowerCase().contains(needle) ||
        (ad.description?.toLowerCase().contains(needle) ?? false) ||
        (ad.address?.toLowerCase().contains(needle) ?? false) ||
        ad.district.toLowerCase().contains(needle) ||
        ad.city.toLowerCase().contains(needle);
  }

  List<Ad> _applySort(List<Ad> ads, AdListSort sort) {
    final sorted = [...ads];
    switch (sort) {
      case AdListSort.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      case AdListSort.oldest:
        sorted.sort((a, b) => a.createdAt.compareTo(b.createdAt));
      case AdListSort.priceAsc:
        sorted.sort((a, b) => _ascNullsLast(a.price, b.price));
      case AdListSort.priceDesc:
        sorted.sort((a, b) => _descNullsFirst(a.price, b.price));
      case AdListSort.areaAsc:
        sorted.sort((a, b) => _ascNullsLast(a.area, b.area));
      case AdListSort.areaDesc:
        sorted.sort((a, b) => _descNullsFirst(a.area, b.area));
    }
    return sorted;
  }

  int _ascNullsLast(num? a, num? b) {
    if (a == null && b == null) return 0;
    if (a == null) return 1;
    if (b == null) return -1;
    return a.compareTo(b);
  }

  int _descNullsFirst(num? a, num? b) {
    if (a == null && b == null) return 0;
    if (a == null) return -1;
    if (b == null) return 1;
    return b.compareTo(a);
  }
}
