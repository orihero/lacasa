/// Offline stand-in for [SavedListingsRepository], backed by
/// `saved_listings_fixtures.dart`. No network, no [LaCasaApi] dependency —
/// what this screen renders from by default (see `saved_listings_mode.dart`).
library;

import '../../../api/api.dart';
import 'saved_listings_fixtures.dart';
import 'saved_listings_repository.dart';

class FixtureSavedListingsRepository implements SavedListingsRepository {
  const FixtureSavedListingsRepository();

  @override
  Future<List<Ad>> fetchSavedAds() async => fixtureSavedAds();
}
