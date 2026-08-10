/// Riverpod state for `my-listings`. Several independent pieces rather
/// than one merged "screen state" provider (build contract §6:
/// "independent providers per independently-failable section"):
///
/// - [appliedMyListingsFiltersProvider] / [myListingsSortProvider] — the
///   real `GET /my/ads` query params (`AdFilters`/`AdSort`) the results
///   are currently fetched against. Changing either re-fetches.
/// - [myListingsStatusProvider] — the CRM filter-sheet's Status field.
///   **Not** a server param (`AgentAdsResource.myList` has no `stage`
///   filter — see `data/my_listings_repository.dart`'s doc comment), so
///   changing it never re-fetches; it only narrows
///   [displayedMyListingsProvider]'s already-fetched list, client-side.
/// - [myListingsResultsProvider] — the one network/fixture fetch, re-run
///   whenever [appliedMyListingsFiltersProvider]/[myListingsSortProvider]
///   change.
/// - [myListingsCoworkersProvider] — the Author column's coworker roster,
///   fetched independently so a coworkers-endpoint failure degrades the
///   Author cell alone (see [resolveAdAuthorName]) rather than blanking
///   the whole ads list.
/// - [displayedMyListingsProvider] — [myListingsResultsProvider]'s data
///   with [myListingsStatusProvider]'s filter applied, client-side, on
///   every rebuild. This is the one widgets should actually watch to
///   render the results list.
/// - [myListingsVisibleCountProvider] — the client-side paging window
///   behind SCREENS.md §25's "Infinite scroll" (build contract §7.7: no
///   server-side pagination exists to drive a real one).
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

/// See this file's doc comment — local-only, never triggers a re-fetch.
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

class MyListingsResultsNotifier extends AsyncNotifier<List<Ad>> {
  @override
  Future<List<Ad>> build() {
    // Watching (not reading) filters/sort is what makes the CRM filter
    // sheet's "Apply Filters" re-trigger this fetch automatically.
    final filters = ref.watch(appliedMyListingsFiltersProvider);
    final sort = ref.watch(myListingsSortProvider);
    return ref
        .read(myListingsRepositoryProvider)
        .fetchMyAds(filters: filters, sort: sort);
  }
}

final myListingsResultsProvider =
    AsyncNotifierProvider<MyListingsResultsNotifier, List<Ad>>(
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

/// [myListingsResultsProvider]'s data, client-side status-filtered by
/// [myListingsStatusProvider] (there is no server-side status filter, see
/// this file's doc comment). Loading and error states pass through from
/// [myListingsResultsProvider] unchanged; only the `data` case is
/// transformed.
final displayedMyListingsProvider = Provider<AsyncValue<List<Ad>>>((ref) {
  final results = ref.watch(myListingsResultsProvider);
  final status = ref.watch(myListingsStatusProvider);

  return results.whenData((ads) {
    if (status == null) return ads;
    return ads.where((ad) => ad.stage == status).toList();
  });
});

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

/// Client-side paging window over [displayedMyListingsProvider]'s already
/// fully-fetched list — see `data/my_listings_repository.dart`'s doc
/// comment (build contract §7.7) for why "infinite scroll" here can only
/// ever reveal more of a list already sitting in memory, never drive a
/// real paginated fetch loop.
const int myListingsPageSize = 10;

class MyListingsVisibleCountNotifier extends Notifier<int> {
  @override
  int build() => myListingsPageSize;

  /// Called when the list scrolls near its bottom and more of the
  /// already-fetched list can be revealed.
  void showMore() => state += myListingsPageSize;

  /// Called whenever filters/sort/status change (a new "view" of the
  /// list) so a shorter result set never leaves this stuck above its own
  /// length, and a longer one starts back at one page rather than
  /// revealing everything at once.
  void reset() => state = myListingsPageSize;
}

final myListingsVisibleCountProvider =
    NotifierProvider<MyListingsVisibleCountNotifier, int>(
      MyListingsVisibleCountNotifier.new,
    );
