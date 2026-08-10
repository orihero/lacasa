/// Riverpod state for `listing-search`. Deliberately several independent
/// pieces rather than one merged "screen state" — same rationale as
/// `home_feed_providers.dart` — plus the client-side sort/search
/// composition `search_repository.dart`'s doc comment describes:
///
/// - [appliedSearchFiltersProvider] — the filter set the results are
///   currently fetched against. Local-only today (no `filter-sheet` screen
///   exists yet in this build batch — it is a sibling agent's screen,
///   under construction in parallel; see this file's "filter-sheet
///   integration seam" note below). Changing it re-fetches.
/// - [searchResultsProvider] — the one network/fixture fetch, re-run
///   whenever [appliedSearchFiltersProvider] changes.
/// - [searchQueryProvider] — the debounced free-text query. Local-only,
///   never re-fetches (there is no server-side search — see
///   `search_repository.dart`).
/// - [searchSortProvider] — the active client-side sort. Local-only, never
///   re-fetches (there is no server-side sort either).
/// - [displayedSearchResultsProvider] — [searchResultsProvider]'s data with
///   [searchQueryProvider]'s substring filter and [searchSortProvider]'s
///   ordering applied, client-side, on every rebuild. This is the one
///   widgets should actually watch to render the results list.
/// - [recentSearchesProvider] — the persisted "Recent Searches" chip row
///   list (`recent_searches_repository.dart`).
///
/// ## filter-sheet integration seam
/// SCREENS.md §5 (`filter-sheet`) is a different screen in this same build
/// batch, built by a different agent working in its own feature directory
/// — this task's hard rules forbid importing it, and it may not exist yet
/// at all while this file is being written. [appliedSearchFiltersProvider]
/// is this screen's half of that seam: once `filter-sheet` exists, its
/// "Apply Filters" button should call
/// `ref.read(appliedSearchFiltersProvider.notifier).apply(newFilters)`
/// (constructing an `AdFilters` from its own form state) and then close
/// itself — nothing on this side needs to change. Until then this provider
/// simply always holds `const AdFilters()` (no filters applied), which is
/// consistent with SCREENS.md §3.3's "View More → listing-search
/// (unfiltered results already loaded)".
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import 'recent_searches_repository_provider.dart';
import 'search_repository_provider.dart';

/// SCREENS.md §3.4's inline Sort control — the same 3 options as
/// `filter-sheet`'s CRM-variant Sort field (§3.5), wire values quoted
/// there. `newest` is the default because it matches the server's own
/// unconditional `createdAt: "desc"` ordering (`adService.js#listAds`) —
/// selecting it client-side is a no-op re-sort of an already-sorted list.
enum SearchSort {
  highestPrice,
  lowestPrice,
  newest;

  String get wire => switch (this) {
    SearchSort.highestPrice => 'highestPrice',
    SearchSort.lowestPrice => 'lowestPrice',
    SearchSort.newest => 'newest',
  };

  String get label => switch (this) {
    SearchSort.highestPrice => 'Highest price',
    SearchSort.lowestPrice => 'Lowest price',
    SearchSort.newest => 'Newest',
  };
}

/// See this file's "filter-sheet integration seam" doc comment above.
class AppliedSearchFiltersNotifier extends Notifier<AdFilters> {
  @override
  AdFilters build() => const AdFilters();

  void apply(AdFilters filters) => state = filters;

  void reset() => state = const AdFilters();
}

final appliedSearchFiltersProvider =
    NotifierProvider<AppliedSearchFiltersNotifier, AdFilters>(
      AppliedSearchFiltersNotifier.new,
    );

/// The number of non-null fields on [appliedSearchFiltersProvider]'s
/// current value — the "Filters" toolbar button's badge count (SCREENS.md
/// §3.4: "badge = active filter count").
int activeFilterCount(AdFilters filters) {
  var count = 0;
  if (filters.city != null) count++;
  if (filters.district != null) count++;
  if (filters.category != null) count++;
  if (filters.type != null) count++;
  if (filters.rooms != null) count++;
  if (filters.repairment != null) count++;
  if (filters.storey != null) count++;
  if (filters.furniture != null) count++;
  if (filters.areaMin != null) count++;
  if (filters.areaMax != null) count++;
  if (filters.priceMin != null) count++;
  if (filters.priceMax != null) count++;
  return count;
}

final activeFilterCountProvider = Provider<int>((ref) {
  return activeFilterCount(ref.watch(appliedSearchFiltersProvider));
});

class SearchResultsNotifier extends AsyncNotifier<List<Ad>> {
  @override
  Future<List<Ad>> build() {
    // Watching (not reading) the applied filters is what makes a
    // filter-sheet "Apply" re-trigger this fetch automatically once that
    // screen is wired to appliedSearchFiltersProvider.
    final filters = ref.watch(appliedSearchFiltersProvider);
    return ref.read(searchRepositoryProvider).fetchResults(filters: filters);
  }
}

final searchResultsProvider =
    AsyncNotifierProvider<SearchResultsNotifier, List<Ad>>(
      SearchResultsNotifier.new,
    );

/// Local-only debounced free-text query — see this file's doc comment for
/// why the debounce timer lives in the search-bar widget rather than here
/// (there is no fetch to debounce against; this exists purely so the
/// results list doesn't re-filter/re-sort on every keystroke).
class SearchQueryNotifier extends Notifier<String> {
  @override
  String build() => '';

  void setQuery(String query) => state = query.trim();

  void clear() => state = '';
}

final searchQueryProvider = NotifierProvider<SearchQueryNotifier, String>(
  SearchQueryNotifier.new,
);

/// Local-only active sort — SCREENS.md §5: "the Sort field applies
/// immediately without debounce", so unlike [searchQueryProvider] nothing
/// upstream of this needs a timer.
class SearchSortNotifier extends Notifier<SearchSort> {
  @override
  SearchSort build() => SearchSort.newest;

  void setSort(SearchSort sort) => state = sort;
}

final searchSortProvider = NotifierProvider<SearchSortNotifier, SearchSort>(
  SearchSortNotifier.new,
);

/// [searchResultsProvider]'s data, client-side text-filtered by
/// [searchQueryProvider] (substring match against title/city/district,
/// case-insensitive — there is no server-side search endpoint, see
/// `search_repository.dart`) and client-side sorted by
/// [searchSortProvider] (there is no server-side sort either). Loading and
/// error states pass through from [searchResultsProvider] unchanged; only
/// the `data` case is transformed.
final displayedSearchResultsProvider = Provider<AsyncValue<List<Ad>>>((ref) {
  final results = ref.watch(searchResultsProvider);
  final query = ref.watch(searchQueryProvider).toLowerCase();
  final sort = ref.watch(searchSortProvider);

  return results.whenData((ads) {
    final filtered = query.isEmpty
        ? ads
        : ads.where((ad) {
            return ad.title.toLowerCase().contains(query) ||
                ad.city.toLowerCase().contains(query) ||
                ad.district.toLowerCase().contains(query);
          }).toList();

    final sorted = [...filtered];
    switch (sort) {
      case SearchSort.highestPrice:
        sorted.sort((a, b) => b.price.compareTo(a.price));
      case SearchSort.lowestPrice:
        sorted.sort((a, b) => a.price.compareTo(b.price));
      case SearchSort.newest:
        sorted.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    }
    return sorted;
  });
});

/// Caps how many distinct recent queries are kept, most-recent-first, and
/// how many "recent searches" chips the row realistically needs to show.
const int maxRecentSearches = 8;

class RecentSearchesNotifier extends AsyncNotifier<List<String>> {
  @override
  Future<List<String>> build() {
    return ref.read(recentSearchesRepositoryProvider).load();
  }

  /// Adds [query] to the front of the list (most-recent-first),
  /// de-duplicating case-insensitively and capping at
  /// [maxRecentSearches]. No-ops for a blank query.
  ///
  /// Reads the *settled* list via [future] rather than `state.value`
  /// directly — a real race, caught while writing this screen's first
  /// tests: [build]'s `load()` is async (a keystore read), and the search
  /// bar's 300ms debounce can easily fire before it resolves on a cold
  /// launch. Reading/writing `state` in that window used to work — the new
  /// query appeared as a chip immediately — only for `build()`'s own
  /// pending `Future` to resolve moments later and silently overwrite it
  /// with the pre-load list, so the chip vanished again. Awaiting [future]
  /// first guarantees `build()` has already landed before this method reads
  /// or writes anything.
  Future<void> addQuery(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;

    List<String> current;
    try {
      current = await future;
    } catch (_) {
      // A failed initial load already degrades to "no recents yet" (see
      // recent_searches_repository.dart) — a query searched afterwards
      // should still be recorded for this session, not silently dropped.
      current = const <String>[];
    }

    final deduped = [
      trimmed,
      ...current.where((q) => q.toLowerCase() != trimmed.toLowerCase()),
    ];
    final next = deduped.take(maxRecentSearches).toList();

    state = AsyncData(next);
    await ref.read(recentSearchesRepositoryProvider).save(next);
  }

  Future<void> clear() async {
    state = const AsyncData(<String>[]);
    await ref.read(recentSearchesRepositoryProvider).save(const <String>[]);
  }
}

final recentSearchesProvider =
    AsyncNotifierProvider<RecentSearchesNotifier, List<String>>(
      RecentSearchesNotifier.new,
    );
