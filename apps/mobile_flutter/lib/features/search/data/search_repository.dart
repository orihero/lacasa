/// Data-access seam for the `listing-search` screen (SCREENS.md §3.4). Two
/// implementations exist: [FixtureSearchRepository] (bundled SCREENS.md
/// §4.1 seed data, no network) and [LiveSearchRepository] (the real
/// [LaCasaApi]) — see `search_mode.dart` for which one the app wires up by
/// default and how to switch.
///
/// **No longer client-side.** `GET /ads` gained `?q=`, a whitelisted
/// `?sort=`, and opt-in keyset paging (`docs/04-api-spec.md`'s Ads
/// section) — this repository now sends all three server-side instead of
/// fetching one bare page and filtering/sorting it in Dart. [fetchPage]
/// mirrors `AdsResource.listPage`'s own shape exactly ([AdPage] — `{ items,
/// nextCursor }`), which is what makes `search_providers.dart`'s infinite
/// scroll a real paged fetch loop rather than lazy widget building over an
/// already-complete list.
///
/// Every method surfaces the same [ApiException] types [LaCasaApi] itself
/// throws (`lib/api/api_exception.dart`).
library;

import '../../../api/api.dart';

abstract class SearchRepository {
  /// One page of the filtered browse feed backing the results list. Already
  /// scoped to active listings by the server (`GET /ads` always filters
  /// `stage: "ACTIVE"` regardless of [filters] — see `ads_resource.dart`),
  /// or, for the fixture, by construction (mirrors that same scoping so the
  /// fixture and the live API never disagree about what a public search can
  /// surface).
  ///
  /// [filters.q] is the free-text query (case-insensitive substring, OR'd
  /// across title/description/address/district/city — see [AdFilters.q]'s
  /// own doc comment); [sort] is the server's whitelisted `?sort=` vocabulary,
  /// not a client-only re-sort. [cursor] is the previous call's
  /// [AdPage.nextCursor]; omit for the first page.
  Future<AdPage> fetchPage({
    AdFilters filters = const AdFilters(),
    AdListSort sort = AdListSort.newest,
    String? cursor,
  });
}
