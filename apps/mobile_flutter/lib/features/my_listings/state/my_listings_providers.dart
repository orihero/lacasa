/// Riverpod state for `my-listings`. Several independent pieces rather
/// than one merged "screen state" provider (build contract §6:
/// "independent providers per independently-failable section"):
///
/// - [appliedMyListingsFiltersProvider] / [myListingsSortProvider] /
///   [myListingsStatusProvider] — the real `GET /my/ads` query params
///   (`AdFilters`/[AdSort]→[adSortToAdListSort]/`AdStage?`) the results are
///   currently fetched against. Changing any of the three re-fetches —
///   **`stage` included**, now that `AgentAdsResource.myListPage` takes a
///   real `stage` param server-side (unlike before, see
///   `data/my_listings_repository.dart`'s doc comment). [myListingsSortProvider]
///   stays typed as [AdSort] (3 values) rather than the wider [AdListSort]
///   (6 values) purely because it's shared state with the CRM filter
///   sheet's own Sort control, which this feature doesn't own and can't
///   widen in place (`features/filter/widgets/filter_sheet.dart`) —
///   [adSortToAdListSort] is where that narrower vocabulary becomes the
///   real wire param.
/// - [myListingsResultsProvider] — the one real fetch loop: its `build()`
///   gets page one, and its `loadMore()` method fetches the next page with
///   the previous response's `nextCursor`, appending onto what's already
///   loaded. Re-runs `build()` (discarding whatever was loaded and starting
///   over at page one) whenever filters/sort/status change, since those are
///   a genuinely new query, not a continuation of the old one.
/// - [myListingsCoworkersProvider] — the Author column's coworker roster,
///   fetched independently so a coworkers-endpoint failure degrades the
///   Author cell alone (see [resolveAdAuthorName]) rather than blanking
///   the whole ads list.
///
/// There is deliberately no more "displayed vs. fetched" split, and no more
/// client-side paging window — both were built around the old
/// no-server-pagination gap (build contract §7.7), which is closed; see
/// `README.md`'s Known gaps for the before/after.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../api/api.dart';
import 'my_listings_repository_provider.dart';

class AppliedMyListingsFiltersNotifier extends Notifier<AdFilters> {
  @override
  AdFilters build() => const AdFilters();

  void apply(AdFilters filters) => state = filters;
}

final appliedMyListingsFiltersProvider =
    NotifierProvider<AppliedMyListingsFiltersNotifier, AdFilters>(
      AppliedMyListingsFiltersNotifier.new,
    );

class MyListingsSortNotifier extends Notifier<AdSort> {
  @override
  AdSort build() => AdSort.newest;

  void setSort(AdSort sort) => state = sort;
}

final myListingsSortProvider = NotifierProvider<MyListingsSortNotifier, AdSort>(
  MyListingsSortNotifier.new,
);

/// [AgentAdsResource.myList]'s narrower legacy sort vocabulary (3 values) →
/// [AdListSort]'s full one (6 values), the type [AgentAdsResource.myListPage]
/// actually takes. `AdSort.highestPrice`/`.lowestPrice` and
/// `AdListSort.priceDesc`/`.priceAsc` are the same wire concept under two
/// names (`docs/04-api-spec.md`: "the legacy wire values highestPrice/
/// lowestPrice \[are\] aliases for priceDesc/priceAsc") — this is a rename,
/// not a behavior change.
AdListSort adSortToAdListSort(AdSort sort) => switch (sort) {
  AdSort.newest => AdListSort.newest,
  AdSort.highestPrice => AdListSort.priceDesc,
  AdSort.lowestPrice => AdListSort.priceAsc,
};

/// See this file's doc comment — a real `GET /my/ads` `stage` param now,
/// not a client-only narrowing.
class MyListingsStatusNotifier extends Notifier<AdStage?> {
  @override
  AdStage? build() => null;

  void setStatus(AdStage? status) => state = status;
}

final myListingsStatusProvider =
    NotifierProvider<MyListingsStatusNotifier, AdStage?>(
      MyListingsStatusNotifier.new,
    );

/// The number of active fields on the CRM filter sheet's current
/// selection — Sort excluded (like `listing-search`'s own
/// `activeFilterCount`, a sort choice is never "a filter" for badge
/// purposes), Status included since it genuinely narrows the visible set.
int activeMyListingsFilterCount(AdFilters filters, AdStage? status) {
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
  if (status != null) count++;
  return count;
}

final activeMyListingsFilterCountProvider = Provider<int>((ref) {
  final filters = ref.watch(appliedMyListingsFiltersProvider);
  final status = ref.watch(myListingsStatusProvider);
  return activeMyListingsFilterCount(filters, status);
});

/// The number of ads requested per real `GET /my/ads` page — both the
/// first `build()` fetch and every subsequent [MyListingsResultsNotifier
/// .loadMore] call send this as `limit`. 10 keeps SCREENS.md §25's
/// infinite-scroll feel on a short list without a huge over-fetch; the
/// server itself defaults to 20 and caps at 100; nothing about that default
/// requires this client to match it.
const int myListingsPageSize = 10;

/// [myListingsResultsProvider]'s value — the ads loaded so far (across
/// however many pages [loadMore] has fetched) plus the cursor for the next
/// one. [nextCursor] `null` means the last page has already been reached;
/// [isLoadingMore] gates [loadMore] against firing twice for the same page
/// (e.g. two scroll-listener ticks in the same frame).
class MyListingsPageState {
  const MyListingsPageState({
    required this.ads,
    required this.nextCursor,
    this.isLoadingMore = false,
    this.loadMoreFailed = false,
  });

  final List<Ad> ads;
  final String? nextCursor;
  final bool isLoadingMore;

  /// Mirrors `search_providers.dart`'s `SearchResultsPage.loadMoreFailed` —
  /// this screen's scroll listener (`my_listings_screen.dart`'s `_onScroll`)
  /// is invisible the same way search's is, so a load-more failure needs a
  /// visible "this failed" row (`LoadMoreFooter`), not just a silently
  /// re-appearing spinner slot with no explanation. Cleared back to `false`
  /// the moment a subsequent [loadMore] call actually starts, same as
  /// [isLoadingMore].
  final bool loadMoreFailed;

  bool get hasMore => nextCursor != null;

  MyListingsPageState copyWith({
    List<Ad>? ads,
    String? nextCursor,
    bool clearNextCursor = false,
    bool? isLoadingMore,
    bool? loadMoreFailed,
  }) {
    return MyListingsPageState(
      ads: ads ?? this.ads,
      nextCursor: clearNextCursor ? null : (nextCursor ?? this.nextCursor),
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      loadMoreFailed: loadMoreFailed ?? this.loadMoreFailed,
    );
  }
}

class MyListingsResultsNotifier extends AsyncNotifier<MyListingsPageState> {
  @override
  Future<MyListingsPageState> build() async {
    // Watching (not reading) filters/sort/status is what makes the CRM
    // filter sheet's "Apply Filters" re-trigger this fetch automatically —
    // and, since `build()` re-running always starts a fresh
    // `MyListingsPageState` at page one, it's also what resets any partial
    // "loaded more" progress from a previous filter selection.
    final filters = ref.watch(appliedMyListingsFiltersProvider);
    final sort = ref.watch(myListingsSortProvider);
    final status = ref.watch(myListingsStatusProvider);
    final page = await ref
        .read(myListingsRepositoryProvider)
        .fetchMyAdsPage(
          filters: filters,
          sort: adSortToAdListSort(sort),
          stage: status,
          limit: myListingsPageSize,
        );
    return MyListingsPageState(ads: page.items, nextCursor: page.nextCursor);
  }

  /// Fetches the next page (using the current [MyListingsPageState
  /// .nextCursor]) and appends it. A no-op if there's no current data, no
  /// next page, or a fetch is already in flight — called from the screen's
  /// scroll listener, which can fire more than once before the first
  /// request resolves.
  Future<void> loadMore() async {
    final current = state.value;
    if (current == null || !current.hasMore || current.isLoadingMore) return;

    state = AsyncData(
      current.copyWith(isLoadingMore: true, loadMoreFailed: false),
    );
    try {
      final page = await ref
          .read(myListingsRepositoryProvider)
          .fetchMyAdsPage(
            filters: ref.read(appliedMyListingsFiltersProvider),
            sort: adSortToAdListSort(ref.read(myListingsSortProvider)),
            stage: ref.read(myListingsStatusProvider),
            limit: myListingsPageSize,
            cursor: current.nextCursor,
          );
      state = AsyncData(
        MyListingsPageState(
          ads: [...current.ads, ...page.items],
          nextCursor: page.nextCursor,
        ),
      );
    } catch (_) {
      // A load-more failure degrades to "stop spinning, keep what's already
      // on screen" rather than blanking the whole list the way a first-page
      // failure does — the list the user was already looking at is still
      // good data. `nextCursor` is left as-is, so scrolling back down tries
      // again rather than silently giving up on "more" forever.
      // `loadMoreFailed` — unlike the old degrade this replaces — makes that
      // failure visible via `LoadMoreFooter`'s tappable "Couldn't load more
      // — Retry" row, not a spinner slot that quietly stops appearing with
      // no explanation (this screen's scroll listener has no other way to
      // tell the user anything went wrong at all).
      state = AsyncData(
        current.copyWith(isLoadingMore: false, loadMoreFailed: true),
      );
    }
  }
}

final myListingsResultsProvider =
    AsyncNotifierProvider<MyListingsResultsNotifier, MyListingsPageState>(
      MyListingsResultsNotifier.new,
    );

class MyListingsCoworkersNotifier extends AsyncNotifier<List<Coworker>> {
  @override
  Future<List<Coworker>> build() {
    return ref.read(myListingsRepositoryProvider).fetchCoworkers();
  }
}

final myListingsCoworkersProvider =
    AsyncNotifierProvider<MyListingsCoworkersNotifier, List<Coworker>>(
      MyListingsCoworkersNotifier.new,
    );

/// Resolves the row-level "Author" text (SCREENS.md §25). Mirrors
/// `apps/console/src/screens/myAds/deriveMyAds.ts#resolveAdAuthor` field
/// for field, including its one known simplification: an ad with an empty
/// `coworkerId` is treated as authored by the *current signed-in session*
/// (`currentUser`), not by a lookup on `Ad.agentId` — literally correct
/// only when that session is the owning agent themselves. A coworker
/// session viewing a teammate's or the agent's own un-assigned ad would
/// see their own name instead of the true author's, because neither `Ad`
/// nor `AuthUser` carries the owning agent's `fullName` anywhere a
/// coworker session can read it (`AuthUser.agentId` is an id only). Not
/// silently "fixed" here since `apps/console`'s own `MyAdsScreen` (which a
/// coworker session can open too, per SCREENS.md §1) ships the identical
/// behavior — matching an established web/console precedent is this
/// build's own stated tie-breaker for an otherwise unspecified judgment
/// call (SCREENS.md's row anatomy names "Author" but does not define its
/// resolution rule).
///
/// Returns `null` — never a guess — when [ad] names a `coworkerId` that
/// isn't (or isn't yet) in [coworkers]; the caller renders an em dash for
/// that case, matching build contract §7.6's "em-dash if none" convention.
String? resolveAdAuthorName(
  Ad ad,
  List<Coworker> coworkers,
  AuthUser? currentUser,
) {
  final coworkerId = ad.coworkerId;
  if (coworkerId.isNotEmpty) {
    for (final coworker in coworkers) {
      if (coworker.id == coworkerId) return coworker.fullName;
    }
    return null;
  }
  return currentUser?.fullName;
}
