/// Offline stand-in for [FavouriteAdIdsRepository] — no network, no
/// [LaCasaApi] dependency, so any screen wired to fixtures (the default —
/// see `favourite_ad_ids_mode.dart`) gets a heart that renders sensibly
/// with no network available, same guarantee every other fixture
/// repository in this app makes.
///
/// The seed id, `ad-1001`, is the same id `home_feed_fixtures.dart` gives
/// its first listing ("Bright 3-room apartment in Chilonzor") — every
/// feature's own fixture ads are independent transcriptions of the same
/// SCREENS.md §4.1 seed rows, so they share ids by construction. Keeping
/// this constant here (rather than importing it from `features/home/`,
/// which this file must not depend on) means a screen built entirely
/// against its own fixtures still shows `ad-1001` favourited, matching
/// Home's own fixture demo state.
library;

import 'favourite_ad_ids_repository.dart';

class FixtureFavouriteAdIdsRepository implements FavouriteAdIdsRepository {
  const FixtureFavouriteAdIdsRepository();

  static const Set<String> _seedSavedAdIds = {'ad-1001'};

  @override
  Future<Set<String>> fetchInitialSavedAdIds() async => _seedSavedAdIds;

  @override
  Future<void> saveAd(String adId) async {}

  @override
  Future<void> unsaveAd(String adId) async {}
}
