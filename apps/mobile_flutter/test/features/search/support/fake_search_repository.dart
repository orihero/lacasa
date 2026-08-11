/// A controllable [SearchRepository] fake for widget tests — no network, no
/// coupling to `search_fixtures.dart`, same shape as
/// `test/features/home/support/fake_home_feed_repository.dart`.
///
/// **Real filter/sort/paging, not a "return everything" shortcut.**
/// `search_repository.dart#fetchPage` is a genuine server-side (or, live,
/// fixture) contract now — `?q=`, a whitelisted `?sort=`, and keyset paging
/// — and `search_screen_test.dart`'s existing sort-chip group and debounced
/// query group both assert on the *rendered order/membership* of the
/// results list, not just on what was recorded in [lastFilters]. A fake that
/// just echoed [ads] back unfiltered/unsorted on every call would make both
/// of those groups pass for the wrong reason (the widget doing work it no
/// longer does) or not at all. So this fake mirrors
/// `FixtureSearchRepository`'s own `_matchesFilters`/`_matchesQuery`/
/// `_applySort` logic field-for-field (see that class's doc comment for the
/// server-side methods each mirrors) rather than reinventing it — this is
/// the same contract, just served from a test-controlled [ads] list instead
/// of the bundled fixture pool, with no `stage: ACTIVE` scoping applied
/// (this fake's callers hand it exactly the ads they want visible; scoping
/// that is `FixtureSearchRepository`'s concern, not a test double's).
library;

import 'dart:async';

import 'package:lacasa_mobile/api/api.dart';
import 'package:lacasa_mobile/features/search/data/search_repository.dart';

class FakeSearchRepository implements SearchRepository {
  FakeSearchRepository({
    List<Ad>? ads,
    this.error,
    this.loadMoreError,
    this.hold,
    this.pageSize = 4,
  }) : ads = ads ?? const [];

  final List<Ad> ads;

  /// Thrown by the first page of a fetch (`cursor == null` — i.e. the
  /// `build()` fetch or a Retry after one). See [loadMoreError] for the
  /// separate knob that fails only a *subsequent* page.
  final Object? error;

  /// Thrown by a page fetch that carries a cursor (i.e. one
  /// [SearchResultsNotifier.loadMore] issued), leaving [error] free to keep
  /// governing the first page independently. Split into its own field
  /// rather than reusing [error] for both because
  /// `LoadMoreFooter`'s "Couldn't load more — Retry" state specifically
  /// needs a fetch that *starts* by succeeding (so there's already a page of
  /// results and a footer to show) and only fails once scrolled into the
  /// next page — a single [error] shared across both calls could never
  /// express that sequencing.
  final Object? loadMoreError;

  /// When set, [fetchPage] awaits this before returning — the only way to
  /// observe a loading state in a widget test, same reasoning as
  /// `FakeSavedListingsRepository.hold`. Applies to every call (first page
  /// or load-more), same as the fake this one replaced.
  final Completer<void>? hold;

  /// How many (already filtered+sorted) ads go out per page. Defaults to 4
  /// — the same deliberately-small choice `FixtureSearchRepository` makes
  /// for its own 8-row pool — so a test that hands this fake more than 4
  /// ads exercises real, multi-page `loadMore` behaviour without every
  /// existing (2-3-ad) test needing to opt into paging explicitly; those
  /// stay a single page (`nextCursor: null`) exactly as before this fake
  /// grew paging support.
  final int pageSize;

  int fetchCallCount = 0;

  /// The [AdFilters] the most recent [fetchPage] call was made with — lets
  /// a test assert the filter-sheet handoff actually re-fetches with the
  /// applied filters, not just that a fetch happened.
  AdFilters? lastFilters;

  @override
  Future<AdPage> fetchPage({
    AdFilters filters = const AdFilters(),
    AdListSort sort = AdListSort.newest,
    String? cursor,
  }) async {
    fetchCallCount++;
    lastFilters = filters;
    if (hold != null) await hold!.future;

    if (cursor == null) {
      if (error != null) throw error!;
    } else {
      if (loadMoreError != null) throw loadMoreError!;
    }

    var matched = ads.where((ad) => _matchesFilters(ad, filters)).toList();

    final q = filters.q?.trim();
    if (q != null && q.isNotEmpty) {
      matched = matched.where((ad) => _matchesQuery(ad, q)).toList();
    }

    final sorted = _applySort(matched, sort);

    final rawStart = cursor == null ? 0 : (int.tryParse(cursor) ?? 0);
    final start = rawStart.clamp(0, sorted.length);
    final end = (start + pageSize).clamp(0, sorted.length);
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

  /// Mirrors `FixtureSearchRepository._applySort` — the same `AdListSort`
  /// semantics `search_providers.dart`'s `SearchSort.toAdListSort` maps this
  /// screen's 3-option UI onto, plus the wider values
  /// `LiveSearchRepository`/`FixtureSearchRepository` both support for
  /// callers (e.g. `map-view`, other future screens) that reach this
  /// repository directly.
  ///
  /// **Why this exists at all in a fake:** this repository used to declare
  /// one `@override Future<List<Ad>> fetchResults(...)` that returned a
  /// single bare, unsorted page — back when `listing-search` re-sorted
  /// results client-side on every sort-chip tap. That's gone: sorting moved
  /// server-side (`GET /ads`'s whitelisted `?sort=`, per
  /// `search_repository.dart`'s own doc comment), so `fetchResults` no
  /// longer overrides anything on [SearchRepository] — only [fetchPage]
  /// does now. Simply deleting the stale `@override`/method would have
  /// silently broken `search_screen_test.dart`'s existing sort-chip group,
  /// which still asserts on the *rendered order* changing per chip: with
  /// sorting server-side, something standing in for "the server" has to do
  /// it, and this fake is that something. So the annotation and the method
  /// it sat on are gone, but the behaviour they were guarding — a fake that
  /// actually reorders by the requested [AdListSort] — was reconciled
  /// forward into this helper rather than dropped.
  List<Ad> _applySort(List<Ad> input, AdListSort sort) {
    final sorted = [...input];
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
