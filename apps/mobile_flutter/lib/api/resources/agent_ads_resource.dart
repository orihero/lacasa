/// The agent/coworker-scoped ad CRM surface: `/api/my/ads`,
/// `/api/my/ads/stage-counts`, and the write half of `/api/ads` (create/
/// update/delete) — behind `my-listings` (§25), `create-listing` (§26) and
/// `edit-listing` (§27).
///
/// Kept as its own resource rather than added to [AdsResource]
/// (`ads_resource.dart`) — that class's own doc comment says create/
/// update/delete are deliberately out of its scope ("agent-only CRM
/// screens, not the four buyer-facing screens this resource set was built
/// for"); this file is that missing half, not a change to the existing one.
library;

import '../api_client.dart';
import '../models/ad.dart';
import '../models/ad_stage_counts.dart';
import '../models/ad_write_input.dart';
import 'ads_resource.dart' show AdFilters;

/// `GET /my/ads`'s `sort` query param — same 3 values `listing-search`'s
/// own sort control offers (SCREENS.md §4), but [newest] is a client-only
/// sentinel: it means "send no `sort` param at all", which is what makes
/// the server fall back to its own `createdAt desc` default. Never sent on
/// the wire as the literal string `"newest"` — there is no such wire value.
enum AdSort {
  newest,
  highestPrice,
  lowestPrice;

  String? get wireOrNull => switch (this) {
    AdSort.newest => null,
    AdSort.highestPrice => 'highestPrice',
    AdSort.lowestPrice => 'lowestPrice',
  };
}

class AgentAdsResource {
  final ApiClient _client;

  const AgentAdsResource(this._client);

  /// `GET /my/ads`. Scoped server-side to `agentId: effectiveAgentId` —
  /// **all stages included** (ACTIVE/SOLD/DRAFT), unlike the public
  /// `GET /ads` feed, which forces `stage: "ACTIVE"`. [filters] reuses
  /// [AdFilters]'s query-param set (city/district/category/type/rooms/...);
  /// its own `agentId` field is ignored here — the server sets that from
  /// the caller's token, not from a query param, on this route.
  ///
  /// **No pagination exists** — the complete list returns every call; see
  /// the API contract survey's §25 gap note. A screen wanting "infinite
  /// scroll" has to fake it client-side over this one full list.
  Future<List<Ad>> myList({AdFilters? filters, AdSort sort = AdSort.newest}) async {
    final query = <String, Object?>{
      ...(filters ?? const AdFilters()).toQuery(),
      'sort': sort.wireOrNull,
    };
    final json = await _client.request(
      method: 'GET',
      path: '/my/ads',
      query: query,
    );
    return (json as List<dynamic>)
        .map((e) => Ad.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /my/ads/stage-counts`. Independent of [myList] — call both if a
  /// screen needs both the rows and the All/Active/Sold/Draft segmented
  /// counts (`apps/console`'s own `MyAdsScreen` instead derives the counts
  /// from the already-fetched list rather than a second round trip — a
  /// reasonable alternative to consider, since this endpoint's counts and a
  /// freshly-derived-from-[myList] count can only disagree if something
  /// changed between the two calls).
  Future<AdStageCounts> stageCounts() async {
    final json = await _client.request(
      method: 'GET',
      path: '/my/ads/stage-counts',
    );
    return AdStageCounts.fromJson(json as Map<String, dynamic>);
  }

  /// `POST /api/ads`. See [AdWriteInput]'s own doc comment for the
  /// omit-vs-clear field convention. Throws [ApiErrorException] with
  /// `code: validation` (400, `tour3dLink` is the one field actually
  /// schema-checked on write) or `code: forbidden` (403, caller's role
  /// can't resolve an `agentId`).
  Future<Ad> create(AdWriteInput input) async {
    final json = await _client.request(
      method: 'POST',
      path: '/ads',
      body: input.toJson(),
    );
    return Ad.fromJson(json as Map<String, dynamic>);
  }

  /// `PATCH /api/ads/:id`. Scoped `findAdByIdForAgent` server-side — throws
  /// `code: notFound` (404) if [id] isn't owned by the caller's effective
  /// agent. **`coworkerId` cannot be reassigned through this call** — it is
  /// set once at creation and the server's update path never reads it back
  /// out of the body even if a caller includes it (there is deliberately no
  /// field for it on [AdWriteInput]) — `apps/console`'s own editor renders
  /// "Assign coworker" read-only for exactly this reason (see the
  /// web/console survey).
  Future<Ad> update(String id, AdWriteInput input) async {
    final json = await _client.request(
      method: 'PATCH',
      path: '/ads/$id',
      body: input.toJson(),
    );
    return Ad.fromJson(json as Map<String, dynamic>);
  }

  /// `DELETE /api/ads/:id`. AGENT only — throws `code: forbidden` (403) for
  /// a COWORKER caller, `code: notFound` (404) if [id] isn't owned by the
  /// caller's own agent id (not coworker-scoped, unlike most other CRM
  /// reads/writes).
  Future<void> delete(String id) async {
    await _client.request(method: 'DELETE', path: '/ads/$id');
  }
}
