/// Data-access seam for the saved/favourited-ad-id set — promoted out of
/// `features/home/data/home_feed_repository.dart` (which used to own these
/// three methods as part of its own interface) once it became clear a
/// second screen (`listing-search`/`listing-detail`) needed the *same*
/// favourited state a listing card's heart on Home already reflects. Two
/// screens each keeping their own copy of this set would let a save on one
/// screen silently fail to show up on the other; this is the single source
/// of truth every heart control reads and writes through instead.
///
/// Every method surfaces the same [ApiException] types [LaCasaApi] itself
/// throws (`lib/api/api_exception.dart`), exactly like the rest of this
/// app's repository seams.
library;

import '../../api/api.dart';

abstract class FavouriteAdIdsRepository {
  /// The set of ad ids already saved by the current session, used to seed
  /// [FavouriteAdIdsNotifier]'s initial state. Never throws — a failure to
  /// load existing favourites degrades to "nothing is favourited yet"
  /// rather than blocking whichever screen asked for it.
  Future<Set<String>> fetchInitialSavedAdIds();

  Future<void> saveAd(String adId);

  Future<void> unsaveAd(String adId);
}
