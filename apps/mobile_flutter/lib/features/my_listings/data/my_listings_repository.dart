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

  /// The All/Active/Sold/Draft segmented counts the header strip renders
  /// (`widgets/my_listings_stage_strip.dart`), straight off
  /// `GET /my/ads/stage-counts` via [AgentAdsResource.stageCounts].
  ///
  /// **A second round trip on purpose, not a fold of [fetchMyAdsPage]'s
  /// result.** `apps/console`'s own `MyAdsScreen` derives its counts from
  /// the already-fetched list, which works there because that screen fetches
  /// the whole table at once. This screen does not: SCREENS.md §25's
  /// "Infinite scroll" is real keyset paging (see this file's doc comment),
  /// so at any moment the client holds one page of ten and folding it would
  /// print "10 active · 0 sold · 0 drafts" for an agent with two hundred ads
  /// — a wrong number, growing as the user scrolls.
  /// [AgentAdsResource.stageCounts]'s own doc comment records the one way
  /// the two can disagree (something changed between the two calls), which
  /// is a far smaller error than "whatever happens to be loaded".
  ///
  /// **Unfiltered by design** — the endpoint takes no query params at all,
  /// so these are counts over the agent's whole table, not over the list
  /// currently narrowed by the CRM filter sheet. The strip therefore keeps
  /// answering "how many drafts do I have?" even while the list below it
  /// shows one city; see `my_listings_stage_strip.dart` for why that is the
  /// question the strip is there to answer.
  Future<AdStageCounts> fetchStageCounts();

  /// Per-ad publish state for the row-level channel badges (§9.2 of the UX
  /// audit) — one batched `GET /publish/status?adIds=…` for every ad
  /// currently on screen, via [PublishResource.statusForAds].
  ///
  /// **Batched, never per row.** `PublishResource.statusForAd` (singular)
  /// exists for `publish-status` (§29) and would mean one request per
  /// visible row — ten on the first page, growing with every `loadMore`.
  /// The batch route was added for exactly this caller; its own doc comment
  /// names "the lean batched form `my-listings` (§25) needs for its channel
  /// badges".
  ///
  /// Two shape differences from the singular route that the badge widget
  /// depends on, both documented on [PublishResource.statusForAds]:
  /// an ad with no publish attempt at all maps to an **empty list** rather
  /// than five synthesized PENDING rows, and each [ChannelStatus] carries
  /// only `channel`/`status` (no `externalUrl`/`lastAttemptAt`/
  /// `errorMessage`). A badge therefore renders "never attempted" from the
  /// *absence* of a row, and anything richer than a tint has to be read on
  /// `publish-status` itself, which is what tapping the strip opens.
  Future<Map<String, List<ChannelStatus>>> fetchPublishStatuses(
    List<String> adIds,
  );

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
