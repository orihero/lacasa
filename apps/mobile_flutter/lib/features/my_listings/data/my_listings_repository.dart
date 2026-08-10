/// Data-access seam for `my-listings` (SCREENS.md §25). Two implementations
/// exist: [FixtureMyListingsRepository] (bundled `work_seed_data.dart`
/// fixtures, no network) and [LiveMyListingsRepository] (the real
/// [LaCasaApi]) — see `my_listings_mode.dart` for which one the app wires
/// up by default and how to switch.
///
/// **No pagination exists (build contract §7.7).** `AgentAdsResource.
/// myList()` — the only server call [fetchMyAds] can drive — has no
/// `limit`/`cursor`/`page` param anywhere, and always returns the complete
/// result set for the caller's effective agent in one response (see that
/// resource's own doc comment). SCREENS.md §25's "Infinite scroll" is
/// therefore built as a client-side paging window over this one, already
/// fully-fetched list (`state/my_listings_providers.dart`'s
/// `myListingsVisibleCountProvider`) — there is nothing server-side to
/// actually page against, and nothing here pretends otherwise.
///
/// [AdFilters]/[AdSort] are real server-side query params on `GET /my/ads`
/// (unlike the buyer-facing `listing-search`'s client-only re-sort — see
/// `features/search/data/search_repository.dart`'s doc comment for that
/// contrast). **Status is NOT one of them** — `AgentAdsResource.myList`
/// has no `stage` filter at all, so the Status chip SCREENS.md §3.5's CRM
/// filter-sheet variant adds is applied client-side, over whatever
/// [fetchMyAds] already returned, by
/// `state/my_listings_providers.dart#displayedMyListingsProvider` — not by
/// this repository.
///
/// Every method surfaces the same [ApiException] types [LaCasaApi] itself
/// throws (`lib/api/api_exception.dart`).
library;

import '../../../api/api.dart';

abstract class MyListingsRepository {
  /// The agent/coworker's complete "My Ads" list (every stage — ACTIVE,
  /// SOLD, DRAFT — unlike the buyer-facing feed), filtered/sorted
  /// server-side by [filters]/[sort]. See this file's doc comment for why
  /// there is no `status`/pagination parameter here.
  Future<List<Ad>> fetchMyAds({
    AdFilters filters = const AdFilters(),
    AdSort sort = AdSort.newest,
  });

  /// Backs the row-level "Author" column (SCREENS.md §25) — see
  /// `state/my_listings_providers.dart#resolveAdAuthorName`'s doc comment
  /// for exactly how an [Ad]'s `coworkerId` resolves against this list
  /// (mirrors `apps/console/src/screens/myAds/deriveMyAds.ts#
  /// resolveAdAuthor`). Independent of [fetchMyAds] so a coworker-roster
  /// failure degrades the Author column alone rather than blanking the
  /// whole screen (build contract §6: "independent providers per
  /// independently-failable section").
  Future<List<Coworker>> fetchCoworkers();
}
