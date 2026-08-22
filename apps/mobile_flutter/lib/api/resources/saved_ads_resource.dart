/// `/api/saved-ads` — the buyer's favourites. Every write here is gated
/// server-side to `role === "user"` exactly (`refuseNonBuyer()`); an
/// agent/coworker token throws [ApiErrorException] with `code: forbidden`
/// (403) on [save]/[unsave], while [list] just answers `[]` for them (their
/// `SavedAd` rows never exist because writes are blocked — not itself a
/// 403). Both writes are idempotent server-side: [save] on an
/// already-saved ad, or [unsave] on one never saved, both just succeed.
library;

import '../api_client.dart';
import '../models/saved_ad.dart';

class SavedAdsResource {
  final ApiClient _client;

  const SavedAdsResource(this._client);

  /// `GET /api/saved-ads`. Requires auth (any role), but only ever returns
  /// non-empty rows for a buyer.
  Future<List<SavedAd>> list() async {
    final json = await _client.request(method: 'GET', path: '/saved-ads');
    return (json as List<dynamic>)
        .map((e) => SavedAd.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  /// `POST /api/saved-ads/:adId`. Idempotent — saving an already-saved ad
  /// answers identically to the first save (200, not 201). Throws
  /// [ApiErrorException] with `code: notFound` (404) for a malformed or
  /// non-existent [adId], or `code: forbidden` (403) for a non-buyer.
  Future<void> save(String adId) async {
    await _client.request(method: 'POST', path: '/saved-ads/$adId');
  }

  /// `DELETE /api/saved-ads/:adId`. Always succeeds (204) for a buyer once
  /// past the role check, whether or not [adId] was ever saved or is even
  /// well-formed — unsaving something not saved just leaves the caller in
  /// the state they wanted.
  Future<void> unsave(String adId) async {
    await _client.request(method: 'DELETE', path: '/saved-ads/$adId');
  }
}
