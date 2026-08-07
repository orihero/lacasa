/// Data-access seam for the `listing-search` screen (SCREENS.md §3.4). Two
/// implementations exist: [FixtureSearchRepository] (bundled SCREENS.md
/// §4.1 seed data, no network) and [LiveSearchRepository] (the real
/// [LaCasaApi]) — see `search_mode.dart` for which one the app wires up by
/// default and how to switch.
///
/// **Deliberately narrow**: this interface only covers what `GET /ads`
/// itself can do — filter by [AdFilters]. Sort, free-text search and
/// pagination are NOT here, because `ads_resource.dart`'s own doc comment
/// (and `apps/api/src/services/adService.js`) confirm the server has no
/// `sort`/`q`/`skip`/`take` params at all: `listAds` always orders
/// `createdAt: "desc"` and returns the complete filtered result set in one
/// response. `search_providers.dart` applies sort and free-text search
/// client-side, over whatever this method returns — see that file's doc
/// comment for the exact client-side algorithm and why building a `sort=`
/// query param into [AdFilters] here would just be silently ignored
/// server-side.
///
/// Every method surfaces the same [ApiException] types [LaCasaApi] itself
/// throws (`lib/api/api_exception.dart`).
library;

import '../../../api/api.dart';

abstract class SearchRepository {
  /// The filtered browse feed backing the results list. Already scoped to
  /// active listings by the server (`GET /ads` always filters
  /// `stage: "ACTIVE"` regardless of [filters] — see `ads_resource.dart`),
  /// or, for the fixture, by construction (mirrors that same scoping so the
  /// fixture and the live API never disagree about what a public search can
  /// surface).
  Future<List<Ad>> fetchResults({AdFilters filters});
}
