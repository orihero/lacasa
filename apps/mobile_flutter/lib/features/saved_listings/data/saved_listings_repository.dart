/// Data-access seam for `saved-listings` (SCREENS.md §3.17) — the grid of a
/// buyer's saved ads.
///
/// **Why this is a second repository rather than reusing
/// `shared/state/favourite_ad_ids_repository.dart`**: that seam exists to
/// answer one question cheaply for every heart control in the app —
/// "which ad ids are currently saved" — and deliberately returns only a
/// `Set<String>`, never the full [Ad] payload a card needs to render a
/// photo/title/price. This screen's whole job is rendering those cards, so
/// it needs its own fetch of the full rows `GET /api/saved-ads` actually
/// returns. Both seams end up hitting the same endpoint in [LiveSavedListingsRepository]/
/// [LiveFavouriteAdIdsRepository] — that duplication is accepted rather than
/// threading one screen's provider through the other's, which would make an
/// unrelated feature's state shape a dependency of this one.
library;

import '../../../api/api.dart';

abstract class SavedListingsRepository {
  /// Every ad the current session has saved, most-recently-saved order as
  /// the server returns it. Returns `[]` for a signed-in non-buyer rather
  /// than throwing — `SavedAdsResource.list()`'s own doc comment notes the
  /// live endpoint answers the same way, since a `SavedAd` row can only ever
  /// exist for a buyer in the first place. Callers must not invoke this for
  /// a fully signed-out session — see `saved_listings_screen.dart` for why
  /// that is a screen-level gate, not a repository-level one.
  Future<List<Ad>> fetchSavedAds();
}
