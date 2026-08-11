/// `/api/ads` — the public listing feed (`GET /api/ads`) and listing detail
/// (`GET /api/ads/:id`). Both are unauthenticated. The feed is always
/// scoped to `stage: "ACTIVE"` server-side (sold/draft ads never appear
/// regardless of filters). Create/update/delete are out of this client's
/// scope (agent-only CRM screens, not the four buyer-facing screens this
/// resource set was built for).
///
/// **Paging, sort, and free-text search are no longer gaps** — the API
/// gained `?q=`, a whitelisted `?sort=`, and opt-in keyset paging
/// (`docs/04-api-spec.md`'s Ads section). [list] stays the bare-array
/// method every existing caller already decodes as one; [listPage] is the
/// new opt-in paged form. See [AdPage]'s doc comment for why those are two
/// methods with two return types rather than one method that might answer
/// either shape.
library;

import '../api_client.dart';
import '../models/ad.dart';
import '../models/ad_page.dart';
import '../models/enums.dart';
import '../transport.dart' show QueryParams;

/// `GET /api/ads` query params — every field optional; an unknown/invalid
/// enum value is silently ignored server-side rather than a 400.
class AdFilters {
  final String? city;
  final String? district;
  final AdCategory? category;
  final AdType? type;
  final int? rooms;
  final Repairment? repairment;
  final int? storey;
  final Furniture? furniture;
  final num? areaMin;
  final num? areaMax;
  final num? priceMin;
  final num? priceMax;

  /// Case-insensitive substring match, OR'd across `title`/`description`/
  /// `address`/`district`/`city` server-side (`adService.js#applySearch`).
  /// A blank/whitespace-only value is a no-op, same as omitting it.
  final String? q;

  const AdFilters({
    this.city,
    this.district,
    this.category,
    this.type,
    this.rooms,
    this.repairment,
    this.storey,
    this.furniture,
    this.areaMin,
    this.areaMax,
    this.priceMin,
    this.priceMax,
    this.q,
  });

  QueryParams toQuery() => {
    'city': city,
    'district': district,
    'category': category == null || category == AdCategory.unknown
        ? null
        : category!.wire,
    'type': type == null || type == AdType.unknown ? null : type!.wire,
    'rooms': rooms,
    'repairment': repairment == null || repairment == Repairment.unknown
        ? null
        : repairment!.wire,
    'storey': storey,
    'furniture': furniture == null || furniture == Furniture.unknown
        ? null
        : furniture!.wire,
    'areaMin': areaMin,
    'areaMax': areaMax,
    'priceMin': priceMin,
    'priceMax': priceMax,
    'q': q,
  };
}

/// The canonical `GET /ads`/`GET /my/ads` sort vocabulary
/// (`SORT_WHITELIST` in `apps/api/src/services/adService.js`) — a separate
/// type from `AgentAdsResource`'s older `AdSort`, which only ever offered 3
/// values and is left exactly as-is: existing fixture/live code (`my_listings`,
/// `filter`) switches over it exhaustively with no `default` arm, so
/// widening it in place would be a breaking change for every one of those
/// call sites rather than an additive one. Reach for [AdListSort] instead
/// for any new call site — [list]'s optional `sort` param, and both
/// [AdsResource.listPage] and `AgentAdsResource.myListPage`.
///
/// [newest] is a client-only "send nothing" sentinel, same convention as
/// `AdSort.newest`: the server's own fallback for a missing/unrecognized
/// `sort` is already `newest`, so this just makes that explicit rather than
/// sending the literal string.
enum AdListSort {
  newest,
  oldest,
  priceAsc,
  priceDesc,
  areaAsc,
  areaDesc;

  String? get wireOrNull => switch (this) {
    AdListSort.newest => null,
    AdListSort.oldest => 'oldest',
    AdListSort.priceAsc => 'priceAsc',
    AdListSort.priceDesc => 'priceDesc',
    AdListSort.areaAsc => 'areaAsc',
    AdListSort.areaDesc => 'areaDesc',
  };
}

class AdsResource {
  final ApiClient _client;

  const AdsResource(this._client);

  /// The public, anonymous feed (active ads only) — `GET /api/ads`,
  /// optionally scoped to one agent's listings and/or narrowed by
  /// [filters]/[sort]. Returns an empty list rather than throwing when
  /// nothing matches. **Always a bare array** — this method never sends
  /// `limit`/`cursor`/`paged`, so it can never receive the `{ items,
  /// nextCursor }` envelope back; see [listPage] for the opt-in paged form.
  Future<List<Ad>> list({
    AdFilters? filters,
    String? agentId,
    AdListSort sort = AdListSort.newest,
  }) async {
    final query = <String, Object?>{
      ...(filters ?? const AdFilters()).toQuery(),
      'agentId': agentId,
      'sort': sort.wireOrNull,
    };
    final json = await _client.request(
      method: 'GET',
      path: '/ads',
      query: query,
    );
    return (json as List<dynamic>)
        .map((e) => Ad.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `GET /api/ads`'s opt-in paged form — same filters/sort as [list], but
  /// always answers [AdPage] (`{ items, nextCursor }`). Unconditionally
  /// sends `paged=true` itself (even for a first page with no [limit]/
  /// [cursor] given), specifically so its return type is never a lie — see
  /// [AdPage]'s doc comment. [limit] defaults to 20 server-side, capped at
  /// 100; [cursor] is the previous call's [AdPage.nextCursor], omit for the
  /// first page.
  Future<AdPage> listPage({
    AdFilters? filters,
    String? agentId,
    AdListSort sort = AdListSort.newest,
    int? limit,
    String? cursor,
  }) async {
    final query = <String, Object?>{
      ...(filters ?? const AdFilters()).toQuery(),
      'agentId': agentId,
      'sort': sort.wireOrNull,
      'limit': limit,
      'cursor': cursor,
      'paged': 'true',
    };
    final json = await _client.request(
      method: 'GET',
      path: '/ads',
      query: query,
    );
    return AdPage.fromJson(json as Map<String, dynamic>);
  }

  /// `GET /api/ads/:id`. Throws [ApiErrorException] with `code: notFound`
  /// (404) for a missing or malformed id.
  Future<Ad> getById(String id) async {
    final json = await _client.request(method: 'GET', path: '/ads/$id');
    return Ad.fromJson(json as Map<String, dynamic>);
  }
}
