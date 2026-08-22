/// A controllable [FavouriteAdIdsRepository] fake for widget tests — no
/// network, so a test can hand it exactly the saved-ad-id seed it wants
/// and assert on save/unsave call counts, exactly like every other fake
/// repository under `test/`.
library;

import 'package:lacasa_mobile/shared/shared.dart';

class FakeFavouriteAdIdsRepository implements FavouriteAdIdsRepository {
  FakeFavouriteAdIdsRepository({
    Set<String>? savedAdIds,
    this.saveError,
    this.unsaveError,
  }) : savedAdIds = savedAdIds ?? const {};

  final Set<String> savedAdIds;

  /// When set, [saveAd] throws this instead of succeeding (used to test the
  /// optimistic-toggle revert path). [unsaveAd] is unaffected.
  final Object? saveError;

  /// The mirror image of [saveError] for [unsaveAd] — the failed-unsave
  /// revert is the path `saved-listings` has to reconcile, since that screen
  /// removes a card the moment the optimistic flip happens.
  final Object? unsaveError;

  int saveCallCount = 0;
  int unsaveCallCount = 0;

  @override
  Future<Set<String>> fetchInitialSavedAdIds() async => savedAdIds;

  @override
  Future<void> saveAd(String adId) async {
    saveCallCount++;
    if (saveError != null) throw saveError!;
  }

  @override
  Future<void> unsaveAd(String adId) async {
    unsaveCallCount++;
    if (unsaveError != null) throw unsaveError!;
  }
}
