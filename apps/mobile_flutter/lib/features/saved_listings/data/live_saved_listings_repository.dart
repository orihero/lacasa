/// The real, network-backed [SavedListingsRepository] — a thin adapter over
/// [LaCasaApi.savedAds], the same "no new wire shapes" rule
/// `live_agents_repository.dart` follows. Unwraps [SavedAd] to [Ad] here
/// (dropping the always-`true` `saved` flag) because that flag exists only
/// to prove the row came from this endpoint — see `saved_ad.dart` — and
/// this screen already knows every row it renders is saved by definition.
library;

import '../../../api/api.dart';
import 'saved_listings_repository.dart';

class LiveSavedListingsRepository implements SavedListingsRepository {
  const LiveSavedListingsRepository(this._api);

  final LaCasaApi _api;

  @override
  Future<List<Ad>> fetchSavedAds() async {
    final rows = await _api.savedAds.list();
    return rows.map((row) => row.ad).toList();
  }
}
