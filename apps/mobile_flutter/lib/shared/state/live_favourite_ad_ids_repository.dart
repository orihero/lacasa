/// The real, network-backed [FavouriteAdIdsRepository] — thin adapter over
/// [LaCasaApi.savedAds], adding no wire shapes of its own. Behaviourally
/// identical to the saved-ad methods `LiveHomeFeedRepository` used to carry
/// before this seam was promoted to `lib/shared/`.
library;

import '../../api/api.dart';
import 'favourite_ad_ids_repository.dart';

class LiveFavouriteAdIdsRepository implements FavouriteAdIdsRepository {
  const LiveFavouriteAdIdsRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<Set<String>> fetchInitialSavedAdIds() async {
    try {
      final saved = await _api.savedAds.list();
      return saved.map((row) => row.ad.id).toSet();
    } on ApiException {
      // A non-buyer session gets `forbidden`/an empty list anyway; any other
      // failure here shouldn't stop the rest of the screen from rendering —
      // favourites just start out looking unsaved.
      return const {};
    }
  }

  @override
  Future<void> saveAd(String adId) => _api.savedAds.save(adId);

  @override
  Future<void> unsaveAd(String adId) => _api.savedAds.unsave(adId);
}
