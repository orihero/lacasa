/// Data-access seam for "Recent Searches" (SCREENS.md §3.4: "mobile-only,
/// local storage"). There is no server endpoint for this — confirmed
/// against `apps/api/src/routes/ads.js` and web's own `SearchPage.jsx`,
/// neither of which has any concept of a persisted recent-query list — so
/// unlike every other repository in this app there is no live/fixture
/// split: this is *always* local storage, on every build.
///
/// **Storage choice**: `flutter_secure_storage` (already a project
/// dependency, used today only for the auth token — `lib/api/
/// token_storage.dart`) rather than adding a new dependency such as
/// `shared_preferences`. Recent search text is not secret, so the keychain/
/// keystore's extra protection is unnecessary overhead for this data — but
/// it is the only on-device persistence primitive already in `pubspec.yaml`
/// under this task's "do not add a package" constraint, and a handful of
/// short strings, written at most once per debounced query, is well within
/// what a keystore write can absorb without a noticeable UI stutter. If a
/// lighter-weight package (e.g. `shared_preferences`) is authorized later,
/// swapping [SecureRecentSearchesRepository]'s body is the entire migration
/// — this interface does not change.
///
/// [load] never throws — a storage failure (no platform binding under
/// `flutter test`, a corrupted value, a cold keystore that errors) degrades
/// to "no recent searches yet" rather than blocking the results list this
/// is secondary to, exactly like [FavouriteAdIdsRepository
/// .fetchInitialSavedAdIds]'s documented degrade rule.
library;

abstract class RecentSearchesRepository {
  Future<List<String>> load();

  Future<void> save(List<String> recents);
}
