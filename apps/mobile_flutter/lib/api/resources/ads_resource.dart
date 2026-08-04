/// `/api/ads` — the public listing feed (`GET /api/ads`) and listing detail
/// (`GET /api/ads/:id`). Both are unauthenticated. The feed is always
/// scoped to `stage: "ACTIVE"` server-side (sold/draft ads never appear
/// regardless of filters), is NOT paginated (a bare, complete result set
/// every time), and has no `sort`/free-text-search param — see the API
/// contract's §6 gap list. Create/update/delete are out of this client's
/// scope (agent-only CRM screens, not the four buyer-facing screens this
/// resource set was built for).
library;

import '../api_client.dart';
import '../models/ad.dart';
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
  };
}

class AdsResource {
  final ApiClient _client;

  const AdsResource(this._client);

  /// The public, anonymous feed (active ads only) — `GET /api/ads`,
  /// optionally scoped to one agent's listings and/or narrowed by
  /// [filters]. Returns an empty list rather than throwing when nothing
  /// matches.
  Future<List<Ad>> list({AdFilters? filters, String? agentId}) async {
    final query = <String, Object?>{
      ...(filters ?? const AdFilters()).toQuery(),
      'agentId': agentId,
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

  /// `GET /api/ads/:id`. Throws [ApiErrorException] with `code: notFound`
  /// (404) for a missing or malformed id.
  Future<Ad> getById(String id) async {
    final json = await _client.request(method: 'GET', path: '/ads/$id');
    return Ad.fromJson(json as Map<String, dynamic>);
  }
}
