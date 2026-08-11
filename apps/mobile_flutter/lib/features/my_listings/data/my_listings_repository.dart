/// Data-access seam for `my-listings` (SCREENS.md §25). Two implementations
/// exist: [FixtureMyListingsRepository] (bundled `work_seed_data.dart`
/// fixtures, no network) and [LiveMyListingsRepository] (the real
/// [LaCasaApi]) — see `my_listings_mode.dart` for which one the app wires
/// up by default and how to switch.
///
/// **Real server paging (closed 2026-08-11).** `GET /my/ads` gained opt-in
/// keyset paging (`docs/04-api-spec.md`'s Ads section) — [fetchMyAdsPage]
/// drives it through [AgentAdsResource.myListPage], which always sends
/// `paged=true` and always decodes the `{ items, nextCursor }` envelope (see
/// [AdPage]'s own doc comment for why that's a distinct method/return type
/// from the older bare-array [AgentAdsResource.myList], which this
/// repository no longer calls at all). SCREENS.md §25's "Infinite scroll" is
/// therefore a real paginated fetch loop now —
/// `state/my_listings_providers.dart`'s `MyListingsResultsNotifier.loadMore`
/// requests the next page with the previous response's [AdPage.nextCursor]
/// — not a client-side window over an already-fully-fetched list.
///
/// **`stage` is now a real server param too**, unlike before this change —
/// `AgentAdsResource.myListPage`'s `stage` narrows `GET /my/ads` itself, so
/// the CRM filter sheet's Status field re-fetches through this repository
/// exactly like [filters]/[sort] do, rather than narrowing an
/// already-fetched list client-side (contrast the buyer-facing
/// `listing-search`'s client-only re-sort — see
/// `features/search/data/search_repository.dart`'s doc comment).
///
/// [AdListSort] is the full 6-value sort vocabulary — wider than the CRM
/// filter sheet's own `AdSort` (3 values, shared with `features/filter/`,
/// which this feature does not own and cannot widen in place; see
/// `state/my_listings_providers.dart#adSortToAdListSort` for the mapping
/// every call site here goes through).
///
/// Every method surfaces the same [ApiException] types [LaCasaApi] itself
/// throws (`lib/api/api_exception.dart`).
library;

import '../../../api/api.dart';

abstract class MyListingsRepository {
  /// One page of the agent/coworker's "My Ads" list (every stage — ACTIVE,
  /// SOLD, DRAFT — unlike the buyer-facing feed, unless [stage] narrows to
  /// one), filtered/sorted server-side by [filters]/[sort]/[stage]. [limit]/
  /// [cursor] are the real keyset-paging params — see this file's doc
  /// comment for why there is no separate non-paged method here: unlike
  /// [AgentAdsResource], which keeps both `myList`/`myListPage` for
  /// backward compatibility with call sites this build doesn't have, this
  /// feature was built after real paging existed and has always used it.
  Future<AdPage> fetchMyAdsPage({
    AdFilters filters = const AdFilters(),
    AdListSort sort = AdListSort.newest,
    AdStage? stage,
    int? limit,
    String? cursor,
  });

  /// Backs the row-level "Author" column (SCREENS.md §25) — see
  /// `state/my_listings_providers.dart#resolveAdAuthorName`'s doc comment
  /// for exactly how an [Ad]'s `coworkerId` resolves against this list
  /// (mirrors `apps/console/src/screens/myAds/deriveMyAds.ts#
  /// resolveAdAuthor`). Independent of [fetchMyAdsPage] so a coworker-roster
  /// failure degrades the Author column alone rather than blanking the
  /// whole screen (build contract §6: "independent providers per
  /// independently-failable section").
  Future<List<Coworker>> fetchCoworkers();
}
