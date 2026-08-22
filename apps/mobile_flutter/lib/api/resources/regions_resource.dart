/// `/api/regions` — the city/district picker vocabulary. Public,
/// unauthenticated, static reference data.
///
/// **No conditional-GET caching in this client.** The server sends
/// `Cache-Control: public, max-age=86400` plus a weak `ETag`
/// (`docs/04-api-spec.md`'s Regions section) so an HTTP cache sitting in
/// front of the app can skip the round trip on a repeat request — but
/// [Transport]/`DioTransport` (`lib/api/transport.dart`) neither stores nor
/// replays an `If-None-Match` header, and there is nothing cached
/// client-side for a `304` to refer back to even if one arrived. Wiring up
/// real conditional-GET support (an `If-None-Match` store keyed by path,
/// reusing the last 200 body on a 304) is real future work, not modeled
/// here — every call is a plain, uncached `GET`. Documented rather than
/// silently omitted, per this codebase's honesty rule: this class does not
/// claim a caching behavior it doesn't have.
library;

import '../api_client.dart';
import '../models/region.dart';

class RegionsResource {
  final ApiClient _client;

  const RegionsResource(this._client);

  /// `GET /regions[?regionId=]`. Omit [regionId] for the full 14-region/
  /// 203-district vocabulary; pass one to narrow both arrays to that single
  /// region — still returns both as arrays either way, so callers use one
  /// parser regardless. An id that matches no region is not an error: it
  /// answers `200` with both arrays empty (a filter that matched nothing),
  /// so this method never throws for a bad [regionId].
  Future<RegionsData> fetch({int? regionId}) async {
    final json = await _client.request(
      method: 'GET',
      path: '/regions',
      query: {'regionId': regionId},
    );
    return RegionsData.fromJson(json as Map<String, dynamic>);
  }
}
