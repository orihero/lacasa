/// The paged envelope `GET /ads` and `GET /my/ads` switch to when the
/// caller opts in — see `resources/ads_resource.dart#AdsResource.listPage`
/// and `resources/agent_ads_resource.dart#AgentAdsResource.myListPage`.
///
/// **Both endpoints answer a bare `List<Ad>` by default** — unchanged from
/// before this run — **and only switch to `{ items, nextCursor }` when the
/// caller sends `limit`, `cursor`, or `paged=true`** (`docs/04-api-spec.md`'s
/// Ads section). That opt-in is deliberate on the server: `GET /api/ads`
/// today returns a bare JSON array and apps/web/apps/console/this client's
/// own `AdsResource.list()`/`AgentAdsResource.myList()` all decode it
/// directly as one; wrapping it in an envelope unconditionally would break
/// every one of them the moment they `.map()`ed over a `Map` instead of a
/// `List`.
///
/// This client mirrors that split at the type level rather than the value
/// level: [AdPage] is only ever produced by `listPage`/`myListPage`, which
/// always send `paged=true` themselves (see their own doc comments) — the
/// bare-array methods ([AdsResource.list]/[AgentAdsResource.myList]) never
/// decode into this class, and these paged methods never decode into a bare
/// `List<Ad>`. There is no single method whose return type could be either
/// shape, so there is nothing for a caller to get wrong by guessing which
/// one came back.
library;

import 'ad.dart';

class AdPage {
  final List<Ad> items;

  /// Opaque — pass verbatim as the next call's `cursor`. `null` means this
  /// was the last page. A forged or garbled cursor is never rejected
  /// server-side (it's treated as "start from the top"), so this is never a
  /// value a caller needs to validate before reusing.
  final String? nextCursor;

  const AdPage({required this.items, required this.nextCursor});

  factory AdPage.fromJson(Map<String, dynamic> json) {
    return AdPage(
      items: (json['items'] as List<dynamic>? ?? const [])
          .map((e) => Ad.fromJson(e as Map<String, dynamic>))
          .toList(),
      nextCursor: json['nextCursor'] as String?,
    );
  }
}
