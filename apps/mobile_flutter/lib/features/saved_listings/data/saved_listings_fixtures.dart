/// Bundled seed data for [FixtureSavedListingsRepository]. Deliberately
/// **not** an independent seed set: it must return exactly the ad(s)
/// `shared/state/fixture_favourite_ad_ids_repository.dart` seeds as already
/// saved (`ad-1001` only, as of that file). If the two fixtures ever
/// disagreed, `saved_listings_providers.dart`'s pruning listener (see its
/// doc comment) would react to `favouriteAdIdsProvider`'s first-load seed as
/// though the user had just un-saved every id this fixture invented that the
/// favourites fixture doesn't also know about — a fixture-only artifact that
/// would look exactly like a bug. `ad-1001` is duplicated here as a literal
/// (rather than importing the other file's private constant, which isn't
/// exported, and rather than editing a file this task doesn't own) — see
/// this task's notes for the cross-feature coupling this creates.
library;

import '../../../api/api.dart';
import '../../home/data/home_feed_fixtures.dart';

const Set<String> fixtureSavedAdIds = {'ad-1001'};

List<Ad> fixtureSavedAds() {
  return homeFeedFixtureAds
      .where((ad) => fixtureSavedAdIds.contains(ad.id))
      .toList();
}
