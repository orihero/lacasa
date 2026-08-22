/// Riverpod state for `listing-search`. Deliberately several independent
/// pieces rather than one merged "screen state" — same rationale as
/// `home_feed_providers.dart`.
///
/// - [appliedSearchFiltersProvider] — the structured filter set (city,
///   category, price range, …) the results are currently fetched against.
///   Local-only (no server round trip of its own); changing it feeds into
///   [searchResultsProvider]'s fetch, same as [searchQueryProvider] and
///   [searchSortProvider] below.
/// - [searchResultsProvider] — the one paged network/fixture fetch,
///   re-run from page 1 whenever [appliedSearchFiltersProvider],
///   [searchQueryProvider], or [searchSortProvider] changes, and extended
///   in place by [SearchResultsNotifier.loadMore] as the results list
///   scrolls. This is the one provider widgets should watch to render the
///   results list.
/// - [searchQueryProvider] — the debounced free-text query. **Server-side**
///   as of this run (`GET /ads`'s `?q=`, see `search_repository.dart`) — a
///   change here re-fetches page 1, it does not just re-filter an
///   already-fetched page.
/// - [searchSortProvider] — the active sort. **Server-side** too (`GET
///   /ads`'s whitelisted `?sort=`) — [SearchSort.toAdListSort] maps this
///   screen's 3-option UI vocabulary onto the server's wider whitelist
///   (`AdListSort`), so a value the client never actually offers can never
///   be sent.
/// - [recentSearchesProvider] — the persisted "Recent Searches" chip row
///   list (`recent_searches_repository.dart`).
///
/// ## filter-sheet integration seam
/// [appliedSearchFiltersProvider] is this screen's half of the seam with
/// `features/filter`'s `showFilterSheet`: its "Apply Filters" button calls
/// `ref.read(appliedSearchFiltersProvider.notifier).apply(newFilters)`
/// (constructing an `AdFilters` from its own form state) and then closes
/// itself — nothing on this side needs to change.
library;

import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import '../../../l10n/generated/app_localizations.dart';
import 'recent_searches_repository_provider.dart';
import 'search_repository_provider.dart';

/// SCREENS.md §3.4's inline Sort control — the same 3 options as
/// `filter-sheet`'s CRM-variant Sort field (§3.5), wire values quoted
/// there. `newest` is the default because it matches the server's own
/// default `?sort=` resolution (`adService.js#resolveSort` falls back to
/// `newest` for a missing/unrecognized value) — selecting it is not a
/// no-op the way it used to be (there is a real server round trip now), it
/// simply asks for the same ordering the server already defaults to.
enum SearchSort {
  highestPrice,
  lowestPrice,
  newest;

  String get wire => switch (this) {
    SearchSort.highestPrice => 'highestPrice',
    SearchSort.lowestPrice => 'lowestPrice',
    SearchSort.newest => 'newest',
  };

  /// Threaded through [AppLocalizations] rather than being a bare getter
  /// (the original shape) since this enum lives in a state file with no
  /// [BuildContext] of its own — see lib/l10n/README.md's "enum-to-label
  /// extension methods" note. Callers already hold an `AppLocalizations`
  /// from their own `build(context, ...)`.
  String label(AppLocalizations l10n) => switch (this) {
    SearchSort.highestPrice => l10n.searchSortHighestPriceLabel,
    SearchSort.lowestPrice => l10n.searchSortLowestPriceLabel,
    SearchSort.newest => l10n.searchSortNewestLabel,
  };

  /// This screen's 3-option UI vocabulary, mapped onto `GET /ads`'s wider
  /// `?sort=` whitelist (`AdListSort` — `lib/api/resources/ads_resource.dart`).
  /// Deliberately a mapping, not a reuse of [wire]/`AdListSort.wireOrNull`
  /// directly: [wire] still carries the legacy `highestPrice`/`lowestPrice`
  /// strings apps/web's own history left behind (kept for *this* enum's own
  /// wire compatibility, documented on [wire] itself), while the canonical
  /// names below (`priceDesc`/`priceAsc`) are what `AdListSort` actually
  /// whitelists — see that enum's own doc comment for why both spellings
  /// exist server-side.
  AdListSort get toAdListSort => switch (this) {
    SearchSort.highestPrice => AdListSort.priceDesc,
    SearchSort.lowestPrice => AdListSort.priceAsc,
    SearchSort.newest => AdListSort.newest,
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
/// §3.4: "badge = active filter count"). Deliberately excludes `q` — the
/// free-text search box is not "a filter" in SCREENS.md's sense, and has
/// its own visible affordance (the search field itself) already showing
/// whether it's active.
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

/// Local-only debounced free-text query — see `search_bar_row.dart`'s doc
/// comment for the 300ms debounce this feeds into. `search_providers.dart`
/// used to note there was no request to debounce against (pure client-side
/// re-filter); that's no longer true — a committed query now re-fetches
/// page 1 from the server, which is exactly why debouncing it (rather than
/// firing a request per keystroke) matters more than it used to.
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

/// Builds the [AdFilters] actually sent over the wire: [base] (the applied
/// structured filters) plus [query] folded into [AdFilters.q]. A blank
/// query is omitted entirely rather than sent as `q: ''` — both are a
/// server-side no-op (`AdFilters.q`'s own doc comment), but omitting it
/// keeps `AdFilters.toQuery()`'s request tidy and matches
/// `AppliedSearchFiltersNotifier`'s own "unset means absent, not empty"
/// convention for every other field.
AdFilters _requestFilters(AdFilters base, String query) {
  final q = query.trim();
  if (q.isEmpty) return base;
  return AdFilters(
    city: base.city,
    district: base.district,
    category: base.category,
    type: base.type,
    rooms: base.rooms,
    repairment: base.repairment,
    storey: base.storey,
    furniture: base.furniture,
    areaMin: base.areaMin,
    areaMax: base.areaMax,
    priceMin: base.priceMin,
    priceMax: base.priceMax,
    q: q,
  );
}

/// [searchResultsProvider]'s state — one already-fetched (and possibly
/// still-growing) page, plus the "loading more" / "load-more failed" flags
/// [SearchResultsList] needs to render the infinite-scroll footer. Bundled
/// into one object, rather than the load-more flags living in their own
/// providers, so a fresh [SearchResultsNotifier.build] (any applied-filter/
/// query/sort change) resets everything about the *previous* fetch in one
/// place — there is no separate piece of load-more state that could
/// survive a filter change and describe the wrong page.
class SearchResultsPage {
  const SearchResultsPage({
    required this.items,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<Ad> items;
  final String? nextCursor;
  final bool isLoadingMore;
  final bool loadMoreFailed;
}

class SearchResultsNotifier extends AsyncNotifier<SearchResultsPage> {
  @override
  Future<SearchResultsPage> build() async {
    final filters = ref.watch(appliedSearchFiltersProvider);
    final query = ref.watch(searchQueryProvider);
    final sort = ref.watch(searchSortProvider);

    final page = await ref
        .read(searchRepositoryProvider)
        .fetchPage(
          filters: _requestFilters(filters, query),
          sort: sort.toAdListSort,
        );
    return SearchResultsPage(items: page.items, nextCursor: page.nextCursor);
  }

  /// Fetches the next page (using the current page's [SearchResultsPage
  /// .nextCursor]) and appends it. A no-op if there's nothing more, or a
  /// fetch is already in flight — both make this safe to call repeatedly
  /// from a scroll listener without its own debounce/guard at the call
  /// site. A failure leaves the already-loaded items in place and flips
  /// [SearchResultsPage.loadMoreFailed] so the list can offer a scoped
  /// retry, rather than losing everything already on screen (same "don't
  /// blank a partially-successful screen" rule `filter_count_provider.dart`
  /// follows for its own retry row).
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || current.nextCursor == null) return;
    if (current.isLoadingMore) return;

    state = AsyncData(
      SearchResultsPage(
        items: current.items,
        nextCursor: current.nextCursor,
        isLoadingMore: true,
      ),
    );

    try {
      final filters = ref.read(appliedSearchFiltersProvider);
      final query = ref.read(searchQueryProvider);
      final sort = ref.read(searchSortProvider);
      final next = await ref
          .read(searchRepositoryProvider)
          .fetchPage(
            filters: _requestFilters(filters, query),
            sort: sort.toAdListSort,
            cursor: current.nextCursor,
          );
      state = AsyncData(
        SearchResultsPage(
          items: [...current.items, ...next.items],
          nextCursor: next.nextCursor,
        ),
      );
    } catch (_) {
      state = AsyncData(
        SearchResultsPage(
          items: current.items,
          nextCursor: current.nextCursor,
          loadMoreFailed: true,
        ),
      );
    }
  }
}

final searchResultsProvider =
    AsyncNotifierProvider<SearchResultsNotifier, SearchResultsPage>(
      SearchResultsNotifier.new,
    );

/// `map-view`'s own feed — it prefers this over its `extra:` payload (see
/// `map_view_screen.dart`'s doc comment) and wants "whatever's currently on
/// screen", the same list [SearchResultsList] renders, as a plain
/// `List<Ad>`. No client-side filter/sort happens here any more — both
/// already happened server-side inside [searchResultsProvider]'s fetch —
/// this is purely an unwrap of [SearchResultsPage.items] out of the richer
/// state [searchResultsProvider] now carries.
final displayedSearchResultsProvider = Provider<AsyncValue<List<Ad>>>((ref) {
  return ref.watch(searchResultsProvider).whenData((page) => page.items);
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
